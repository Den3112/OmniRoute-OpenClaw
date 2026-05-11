---
name: state-management
description: Use this skill for state management in React applications including Zustand, Redux Toolkit, TanStack Query, server state vs client state, optimistic updates, real-time data synchronization, and data flow patterns (2026).
origin: Custom
---

# State Management & Data Flow Skill

Comprehensive guide for state management in modern React applications (Updated May 2026).

## When to Activate

- Managing application state
- Implementing global state
- Handling server state
- Optimistic updates
- Real-time data synchronization
- Form state management
- Caching strategies
- State persistence
- Complex data flows

## State Types

### Client State vs Server State

```typescript
// Client State - UI state, form inputs, modals
// - Synchronous
// - Always up-to-date
// - Owned by client

// Server State - Data from API
// - Asynchronous
// - Can be stale
// - Owned by server
// - Needs caching, refetching, synchronization
```

## Zustand (Recommended for 2026)

### Why Zustand?
- Minimal boilerplate
- No providers needed
- TypeScript-first
- DevTools support
- Middleware ecosystem
- Small bundle size (~1KB)

### Basic Store

```typescript
import { create } from 'zustand'

interface CounterStore {
  count: number
  increment: () => void
  decrement: () => void
  reset: () => void
}

export const useCounterStore = create<CounterStore>((set) => ({
  count: 0,
  increment: () => set((state) => ({ count: state.count + 1 })),
  decrement: () => set((state) => ({ count: state.count - 1 })),
  reset: () => set({ count: 0 })
}))

// Usage in component
function Counter() {
  const { count, increment, decrement } = useCounterStore()
  
  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={increment}>+</button>
      <button onClick={decrement}>-</button>
    </div>
  )
}
```

### Complex Store with Slices

```typescript
import { create } from 'zustand'
import { devtools, persist } from 'zustand/middleware'

// User slice
interface UserSlice {
  user: User | null
  setUser: (user: User) => void
  logout: () => void
}

const createUserSlice = (set: any): UserSlice => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null })
})

// Cart slice
interface CartSlice {
  items: CartItem[]
  addItem: (item: CartItem) => void
  removeItem: (id: string) => void
  clearCart: () => void
  total: () => number
}

const createCartSlice = (set: any, get: any): CartSlice => ({
  items: [],
  addItem: (item) => set((state: any) => ({
    items: [...state.items, item]
  })),
  removeItem: (id) => set((state: any) => ({
    items: state.items.filter((item: CartItem) => item.id !== id)
  })),
  clearCart: () => set({ items: [] }),
  total: () => {
    const state = get()
    return state.items.reduce((sum: number, item: CartItem) => 
      sum + item.price * item.quantity, 0
    )
  }
})

// Combined store
type Store = UserSlice & CartSlice

export const useStore = create<Store>()(
  devtools(
    persist(
      (set, get) => ({
        ...createUserSlice(set),
        ...createCartSlice(set, get)
      }),
      {
        name: 'app-storage',
        partialize: (state) => ({
          user: state.user,
          items: state.items
        })
      }
    )
  )
)
```

### Async Actions

```typescript
interface TodoStore {
  todos: Todo[]
  loading: boolean
  error: string | null
  fetchTodos: () => Promise<void>
  addTodo: (text: string) => Promise<void>
}

export const useTodoStore = create<TodoStore>((set) => ({
  todos: [],
  loading: false,
  error: null,
  
  fetchTodos: async () => {
    set({ loading: true, error: null })
    try {
      const response = await fetch('/api/todos')
      const todos = await response.json()
      set({ todos, loading: false })
    } catch (error) {
      set({ error: 'Failed to fetch todos', loading: false })
    }
  },
  
  addTodo: async (text) => {
    set({ loading: true, error: null })
    try {
      const response = await fetch('/api/todos', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text })
      })
      const newTodo = await response.json()
      set((state) => ({
        todos: [...state.todos, newTodo],
        loading: false
      }))
    } catch (error) {
      set({ error: 'Failed to add todo', loading: false })
    }
  }
}))
```

### Selectors for Performance

```typescript
// ❌ Bad: Component re-renders on any store change
function TodoList() {
  const store = useTodoStore()
  return <div>{store.todos.length}</div>
}

// ✅ Good: Only re-renders when todos change
function TodoList() {
  const todos = useTodoStore((state) => state.todos)
  return <div>{todos.length}</div>
}

// ✅ Better: Memoized selector
import { shallow } from 'zustand/shallow'

function TodoList() {
  const { todos, addTodo } = useTodoStore(
    (state) => ({ todos: state.todos, addTodo: state.addTodo }),
    shallow
  )
  return <div>{todos.length}</div>
}
```

## TanStack Query (React Query)

### Why TanStack Query?
- Server state management
- Automatic caching
- Background refetching
- Optimistic updates
- Pagination & infinite scroll
- Request deduplication

### Setup

```typescript
// app/providers.tsx
'use client'

import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { useState } from 'react'

export function Providers({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 60 * 1000, // 1 minute
        gcTime: 5 * 60 * 1000, // 5 minutes (formerly cacheTime)
        refetchOnWindowFocus: false,
        retry: 1
      }
    }
  }))

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      <ReactQueryDevtools initialIsOpen={false} />
    </QueryClientProvider>
  )
}
```

### Basic Query

```typescript
import { useQuery } from '@tanstack/react-query'

async function fetchUsers() {
  const response = await fetch('/api/users')
  if (!response.ok) throw new Error('Failed to fetch users')
  return response.json()
}

function UserList() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['users'],
    queryFn: fetchUsers
  })

  if (isLoading) return <div>Loading...</div>
  if (error) return <div>Error: {error.message}</div>

  return (
    <div>
      <button onClick={() => refetch()}>Refresh</button>
      {data.map((user: User) => (
        <div key={user.id}>{user.name}</div>
      ))}
    </div>
  )
}
```

### Mutations

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query'

async function createUser(data: CreateUserData) {
  const response = await fetch('/api/users', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!response.ok) throw new Error('Failed to create user')
  return response.json()
}

function CreateUserForm() {
  const queryClient = useQueryClient()
  
  const mutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      // Invalidate and refetch
      queryClient.invalidateQueries({ queryKey: ['users'] })
    }
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    mutation.mutate({
      name: formData.get('name') as string,
      email: formData.get('email') as string
    })
  }

  return (
    <form onSubmit={handleSubmit}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button type="submit" disabled={mutation.isPending}>
        {mutation.isPending ? 'Creating...' : 'Create User'}
      </button>
      {mutation.isError && <div>Error: {mutation.error.message}</div>}
    </form>
  )
}
```

### Optimistic Updates

```typescript
function TodoList() {
  const queryClient = useQueryClient()

  const mutation = useMutation({
    mutationFn: updateTodo,
    onMutate: async (newTodo) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['todos'] })

      // Snapshot previous value
      const previousTodos = queryClient.getQueryData(['todos'])

      // Optimistically update
      queryClient.setQueryData(['todos'], (old: Todo[]) => 
        old.map(todo => 
          todo.id === newTodo.id ? { ...todo, ...newTodo } : todo
        )
      )

      // Return context with snapshot
      return { previousTodos }
    },
    onError: (err, newTodo, context) => {
      // Rollback on error
      queryClient.setQueryData(['todos'], context?.previousTodos)
    },
    onSettled: () => {
      // Refetch after error or success
      queryClient.invalidateQueries({ queryKey: ['todos'] })
    }
  })

  return (
    <div>
      {/* UI */}
    </div>
  )
}
```

### Pagination

```typescript
function PaginatedUsers() {
  const [page, setPage] = useState(1)

  const { data, isLoading, isPlaceholderData } = useQuery({
    queryKey: ['users', page],
    queryFn: () => fetchUsers(page),
    placeholderData: (previousData) => previousData // Keep previous data while fetching
  })

  return (
    <div>
      {data?.users.map((user: User) => (
        <div key={user.id}>{user.name}</div>
      ))}
      
      <button
        onClick={() => setPage(p => Math.max(1, p - 1))}
        disabled={page === 1}
      >
        Previous
      </button>
      
      <button
        onClick={() => setPage(p => p + 1)}
        disabled={isPlaceholderData || !data?.hasMore}
      >
        Next
      </button>
    </div>
  )
}
```

### Infinite Scroll

```typescript
import { useInfiniteQuery } from '@tanstack/react-query'

async function fetchPosts({ pageParam = 0 }) {
  const response = await fetch(`/api/posts?cursor=${pageParam}`)
  return response.json()
}

function InfinitePostList() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage
  } = useInfiniteQuery({
    queryKey: ['posts'],
    queryFn: fetchPosts,
    initialPageParam: 0,
    getNextPageParam: (lastPage) => lastPage.nextCursor
  })

  return (
    <div>
      {data?.pages.map((page, i) => (
        <div key={i}>
          {page.posts.map((post: Post) => (
            <div key={post.id}>{post.title}</div>
          ))}
        </div>
      ))}
      
      <button
        onClick={() => fetchNextPage()}
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage
          ? 'Loading more...'
          : hasNextPage
          ? 'Load More'
          : 'Nothing more to load'}
      </button>
    </div>
  )
}
```

## Redux Toolkit (When Needed)

### When to Use Redux
- Very complex state logic
- Need time-travel debugging
- Team familiar with Redux
- Large-scale applications

### Setup

```typescript
// store/store.ts
import { configureStore } from '@reduxjs/toolkit'
import counterReducer from './counterSlice'
import userReducer from './userSlice'

export const store = configureStore({
  reducer: {
    counter: counterReducer,
    user: userReducer
  }
})

export type RootState = ReturnType<typeof store.getState>
export type AppDispatch = typeof store.dispatch
```

### Slice

```typescript
// store/counterSlice.ts
import { createSlice, PayloadAction } from '@reduxjs/toolkit'

interface CounterState {
  value: number
}

const initialState: CounterState = {
  value: 0
}

export const counterSlice = createSlice({
  name: 'counter',
  initialState,
  reducers: {
    increment: (state) => {
      state.value += 1
    },
    decrement: (state) => {
      state.value -= 1
    },
    incrementByAmount: (state, action: PayloadAction<number>) => {
      state.value += action.payload
    }
  }
})

export const { increment, decrement, incrementByAmount } = counterSlice.actions
export default counterSlice.reducer
```

### Async Thunks

```typescript
import { createAsyncThunk, createSlice } from '@reduxjs/toolkit'

export const fetchUsers = createAsyncThunk(
  'users/fetchUsers',
  async () => {
    const response = await fetch('/api/users')
    return response.json()
  }
)

interface UsersState {
  users: User[]
  loading: boolean
  error: string | null
}

const initialState: UsersState = {
  users: [],
  loading: false,
  error: null
}

const usersSlice = createSlice({
  name: 'users',
  initialState,
  reducers: {},
  extraReducers: (builder) => {
    builder
      .addCase(fetchUsers.pending, (state) => {
        state.loading = true
        state.error = null
      })
      .addCase(fetchUsers.fulfilled, (state, action) => {
        state.loading = false
        state.users = action.payload
      })
      .addCase(fetchUsers.rejected, (state, action) => {
        state.loading = false
        state.error = action.error.message || 'Failed to fetch users'
      })
  }
})

export default usersSlice.reducer
```

## Form State Management

### React Hook Form

```typescript
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const schema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email'),
  age: z.number().min(18, 'Must be 18 or older')
})

type FormData = z.infer<typeof schema>

function UserForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    reset
  } = useForm<FormData>({
    resolver: zodResolver(schema)
  })

  const onSubmit = async (data: FormData) => {
    await createUser(data)
    reset()
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('name')} />
      {errors.name && <span>{errors.name.message}</span>}

      <input {...register('email')} type="email" />
      {errors.email && <span>{errors.email.message}</span>}

      <input {...register('age', { valueAsNumber: true })} type="number" />
      {errors.age && <span>{errors.age.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Submitting...' : 'Submit'}
      </button>
    </form>
  )
}
```

## State Persistence

### LocalStorage with Zustand

```typescript
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

interface SettingsStore {
  theme: 'light' | 'dark'
  language: string
  setTheme: (theme: 'light' | 'dark') => void
  setLanguage: (language: string) => void
}

export const useSettingsStore = create<SettingsStore>()(
  persist(
    (set) => ({
      theme: 'light',
      language: 'en',
      setTheme: (theme) => set({ theme }),
      setLanguage: (language) => set({ language })
    }),
    {
      name: 'settings-storage',
      storage: createJSONStorage(() => localStorage)
    }
  )
)
```

### SessionStorage

```typescript
export const useSessionStore = create<Store>()(
  persist(
    (set) => ({
      // state
    }),
    {
      name: 'session-storage',
      storage: createJSONStorage(() => sessionStorage)
    }
  )
)
```

## State Synchronization

### Cross-Tab Synchronization

```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useStore = create<Store>()(
  persist(
    (set) => ({
      // state
    }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => localStorage),
      // Sync across tabs
      onRehydrateStorage: () => (state) => {
        console.log('Hydration finished', state)
      }
    }
  )
)

// Listen to storage events
if (typeof window !== 'undefined') {
  window.addEventListener('storage', (e) => {
    if (e.key === 'app-storage') {
      // State changed in another tab
      useStore.persist.rehydrate()
    }
  })
}
```

## Best Practices

### State Colocation

```typescript
// ❌ Bad: Global state for local UI
const useGlobalStore = create((set) => ({
  modalOpen: false,
  setModalOpen: (open: boolean) => set({ modalOpen: open })
}))

// ✅ Good: Local state for local UI
function Modal() {
  const [isOpen, setIsOpen] = useState(false)
  
  return (
    <>
      <button onClick={() => setIsOpen(true)}>Open</button>
      {isOpen && <ModalContent onClose={() => setIsOpen(false)} />}
    </>
  )
}
```

### Derived State

```typescript
// ❌ Bad: Storing derived state
const useStore = create((set) => ({
  items: [],
  total: 0,
  addItem: (item) => set((state) => ({
    items: [...state.items, item],
    total: state.total + item.price // Duplicated logic
  }))
}))

// ✅ Good: Compute derived state
const useStore = create((set, get) => ({
  items: [],
  addItem: (item) => set((state) => ({
    items: [...state.items, item]
  })),
  getTotal: () => {
    const { items } = get()
    return items.reduce((sum, item) => sum + item.price, 0)
  }
}))
```

### Immutable Updates

```typescript
// ✅ Always use immutable updates
set((state) => ({
  items: [...state.items, newItem] // Create new array
}))

set((state) => ({
  user: { ...state.user, name: 'New Name' } // Create new object
}))

// With Immer (built into Zustand)
import { immer } from 'zustand/middleware/immer'

const useStore = create<Store>()(
  immer((set) => ({
    items: [],
    addItem: (item) => set((state) => {
      state.items.push(item) // Mutate draft state
    })
  }))
)
```

## State Management Decision Tree

```
Is it server data?
├─ Yes → Use TanStack Query
└─ No → Is it global state?
    ├─ Yes → Use Zustand
    └─ No → Is it form state?
        ├─ Yes → Use React Hook Form
        └─ No → Use useState/useReducer
```

## Best Practices Checklist

- [ ] Use TanStack Query for server state
- [ ] Use Zustand for global client state
- [ ] Keep state as local as possible
- [ ] Use selectors to prevent unnecessary re-renders
- [ ] Implement optimistic updates for better UX
- [ ] Persist important state to localStorage
- [ ] Use TypeScript for type safety
- [ ] Avoid storing derived state
- [ ] Use immutable updates
- [ ] Enable DevTools in development

## Resources

- [Zustand Documentation](https://zustand-demo.pmnd.rs/)
- [TanStack Query Documentation](https://tanstack.com/query/latest)
- [Redux Toolkit Documentation](https://redux-toolkit.js.org/)
- [React Hook Form](https://react-hook-form.com/)

---

**Remember**: Choose the right tool for the job. Server state ≠ Client state. Keep state local when possible. Optimize with selectors.
