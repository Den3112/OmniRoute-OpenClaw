---
name: web-development
description: Use this skill for building modern web applications with React 19, Next.js 15+, TypeScript, API development, state management, routing, and frontend architecture. Covers React Compiler, Server Actions, Partial Prerendering, and modern patterns (2026).
origin: Custom
---

# Web Development Skill

Comprehensive guide for building modern web applications with React 19, Next.js 15+, and TypeScript (Updated May 2026).

## When to Activate

- Building React 19/Next.js 15+ applications
- Creating API endpoints and Server Actions
- Implementing state management (React 19 use hook, Zustand)
- Setting up routing and navigation
- Optimizing performance with React Compiler
- Working with forms and validation
- Implementing authentication flows
- Building responsive UIs with modern CSS
- Server-side rendering (SSR), static generation (SSG), and Partial Prerendering (PPR)
- Using React Server Components and streaming

## Project Structure

### Next.js 15+ App Router Structure (2026)
```
app/
├── (auth)/              # Route groups
│   ├── login/
│   └── register/
├── (dashboard)/
│   ├── layout.tsx       # Nested layout
│   └── page.tsx
├── api/                 # API routes
│   ├── users/
│   │   └── route.ts
│   └── auth/
│       └── route.ts
├── layout.tsx           # Root layout
├── page.tsx             # Home page
└── error.tsx            # Error boundary

components/
├── ui/                  # Reusable UI components
│   ├── button.tsx
│   ├── input.tsx
│   └── card.tsx
├── features/            # Feature-specific components
│   ├── auth/
│   └── dashboard/
└── layouts/             # Layout components

lib/
├── api.ts               # API client
├── utils.ts             # Utility functions
├── hooks.ts             # Custom hooks
└── types.ts             # TypeScript types

public/                  # Static assets
├── images/
└── fonts/
```

## React Best Practices

### Component Design

#### Functional Components with TypeScript
```typescript
import { FC, ReactNode } from 'react'

interface ButtonProps {
  children: ReactNode
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  onClick?: () => void
}

export const Button: FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  disabled = false,
  onClick
}) => {
  const baseStyles = 'rounded font-medium transition-colors'
  const variantStyles = {
    primary: 'bg-blue-600 hover:bg-blue-700 text-white',
    secondary: 'bg-gray-200 hover:bg-gray-300 text-gray-900',
    danger: 'bg-red-600 hover:bg-red-700 text-white'
  }
  const sizeStyles = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg'
  }

  return (
    <button
      className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]}`}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  )
}
```

#### Custom Hooks
```typescript
import { useState, useEffect } from 'react'

// Fetch data hook
export function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const fetchData = async () => {
      try {
        setLoading(true)
        const response = await fetch(url)
        if (!response.ok) throw new Error('Failed to fetch')
        const json = await response.json()
        setData(json)
      } catch (err) {
        setError(err as Error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [url])

  return { data, loading, error }
}

// Local storage hook
export function useLocalStorage<T>(key: string, initialValue: T) {
  const [value, setValue] = useState<T>(() => {
    if (typeof window === 'undefined') return initialValue
    
    try {
      const item = window.localStorage.getItem(key)
      return item ? JSON.parse(item) : initialValue
    } catch (error) {
      console.error(error)
      return initialValue
    }
  })

  const setStoredValue = (newValue: T | ((val: T) => T)) => {
    try {
      const valueToStore = newValue instanceof Function ? newValue(value) : newValue
      setValue(valueToStore)
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore))
      }
    } catch (error) {
      console.error(error)
    }
  }

  return [value, setStoredValue] as const
}

// Debounce hook
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value)

  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value)
    }, delay)

    return () => {
      clearTimeout(handler)
    }
  }, [value, delay])

  return debouncedValue
}
```

### State Management

#### Context API Pattern
```typescript
import { createContext, useContext, useState, ReactNode } from 'react'

interface User {
  id: string
  email: string
  name: string
}

interface AuthContextType {
  user: User | null
  login: (email: string, password: string) => Promise<void>
  logout: () => void
  isLoading: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const login = async (email: string, password: string) => {
    setIsLoading(true)
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
      })
      
      if (!response.ok) throw new Error('Login failed')
      
      const userData = await response.json()
      setUser(userData)
    } finally {
      setIsLoading(false)
    }
  }

  const logout = () => {
    setUser(null)
    // Clear cookies/tokens
  }

  return (
    <AuthContext.Provider value={{ user, login, logout, isLoading }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within AuthProvider')
  }
  return context
}
```

#### Zustand Store (Recommended for Complex State)
```typescript
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

interface CartItem {
  id: string
  name: string
  price: number
  quantity: number
}

interface CartStore {
  items: CartItem[]
  addItem: (item: CartItem) => void
  removeItem: (id: string) => void
  updateQuantity: (id: string, quantity: number) => void
  clearCart: () => void
  total: () => number
}

export const useCartStore = create<CartStore>()(
  persist(
    (set, get) => ({
      items: [],
      
      addItem: (item) => set((state) => {
        const existing = state.items.find(i => i.id === item.id)
        if (existing) {
          return {
            items: state.items.map(i =>
              i.id === item.id
                ? { ...i, quantity: i.quantity + item.quantity }
                : i
            )
          }
        }
        return { items: [...state.items, item] }
      }),
      
      removeItem: (id) => set((state) => ({
        items: state.items.filter(i => i.id !== id)
      })),
      
      updateQuantity: (id, quantity) => set((state) => ({
        items: state.items.map(i =>
          i.id === id ? { ...i, quantity } : i
        )
      })),
      
      clearCart: () => set({ items: [] }),
      
      total: () => {
        const { items } = get()
        return items.reduce((sum, item) => sum + item.price * item.quantity, 0)
      }
    }),
    { name: 'cart-storage' }
  )
)
```

## Next.js API Routes

### RESTful API Pattern
```typescript
// app/api/users/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  password: z.string().min(8)
})

// GET /api/users
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get('page') || '1')
    const limit = parseInt(searchParams.get('limit') || '10')
    
    // Fetch users from database
    const users = await db.users.findMany({
      skip: (page - 1) * limit,
      take: limit,
      select: { id: true, email: true, name: true } // Don't return passwords
    })
    
    return NextResponse.json({ users, page, limit })
  } catch (error) {
    console.error('Error fetching users:', error)
    return NextResponse.json(
      { error: 'Failed to fetch users' },
      { status: 500 }
    )
  }
}

// POST /api/users
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = CreateUserSchema.parse(body)
    
    // Hash password
    const hashedPassword = await hash(validated.password)
    
    // Create user
    const user = await db.users.create({
      data: {
        email: validated.email,
        name: validated.name,
        password: hashedPassword
      },
      select: { id: true, email: true, name: true }
    })
    
    return NextResponse.json(user, { status: 201 })
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      )
    }
    
    console.error('Error creating user:', error)
    return NextResponse.json(
      { error: 'Failed to create user' },
      { status: 500 }
    )
  }
}
```

### Dynamic API Routes
```typescript
// app/api/users/[id]/route.ts
import { NextRequest, NextResponse } from 'next/server'

interface RouteParams {
  params: { id: string }
}

// GET /api/users/:id
export async function GET(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    const user = await db.users.findUnique({
      where: { id: params.id },
      select: { id: true, email: true, name: true }
    })
    
    if (!user) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }
    
    return NextResponse.json(user)
  } catch (error) {
    console.error('Error fetching user:', error)
    return NextResponse.json(
      { error: 'Failed to fetch user' },
      { status: 500 }
    )
  }
}

// PATCH /api/users/:id
export async function PATCH(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    const body = await request.json()
    
    const user = await db.users.update({
      where: { id: params.id },
      data: body,
      select: { id: true, email: true, name: true }
    })
    
    return NextResponse.json(user)
  } catch (error) {
    console.error('Error updating user:', error)
    return NextResponse.json(
      { error: 'Failed to update user' },
      { status: 500 }
    )
  }
}

// DELETE /api/users/:id
export async function DELETE(
  request: NextRequest,
  { params }: RouteParams
) {
  try {
    await db.users.delete({
      where: { id: params.id }
    })
    
    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Error deleting user:', error)
    return NextResponse.json(
      { error: 'Failed to delete user' },
      { status: 500 }
    )
  }
}
```

## Forms and Validation

### React Hook Form with Zod
```typescript
'use client'

import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'

const LoginSchema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters')
})

type LoginFormData = z.infer<typeof LoginSchema>

export function LoginForm() {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm<LoginFormData>({
    resolver: zodResolver(LoginSchema)
  })

  const onSubmit = async (data: LoginFormData) => {
    try {
      const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      })
      
      if (!response.ok) throw new Error('Login failed')
      
      // Handle success
    } catch (error) {
      console.error(error)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
      <div>
        <label htmlFor="email" className="block text-sm font-medium">
          Email
        </label>
        <input
          {...register('email')}
          type="email"
          id="email"
          className="mt-1 block w-full rounded border px-3 py-2"
        />
        {errors.email && (
          <p className="mt-1 text-sm text-red-600">{errors.email.message}</p>
        )}
      </div>

      <div>
        <label htmlFor="password" className="block text-sm font-medium">
          Password
        </label>
        <input
          {...register('password')}
          type="password"
          id="password"
          className="mt-1 block w-full rounded border px-3 py-2"
        />
        {errors.password && (
          <p className="mt-1 text-sm text-red-600">{errors.password.message}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={isSubmitting}
        className="w-full rounded bg-blue-600 px-4 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
      >
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  )
}
```

## Server Components & Data Fetching

### Server Component (Next.js 13+)
```typescript
// app/users/page.tsx
import { Suspense } from 'react'

async function getUsers() {
  const response = await fetch('https://api.example.com/users', {
    next: { revalidate: 60 } // Revalidate every 60 seconds
  })
  
  if (!response.ok) throw new Error('Failed to fetch users')
  
  return response.json()
}

export default async function UsersPage() {
  const users = await getUsers()

  return (
    <div>
      <h1>Users</h1>
      <Suspense fallback={<div>Loading...</div>}>
        <UserList users={users} />
      </Suspense>
    </div>
  )
}

function UserList({ users }: { users: User[] }) {
  return (
    <ul>
      {users.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  )
}
```

### Streaming with Suspense
```typescript
// app/dashboard/page.tsx
import { Suspense } from 'react'

async function getStats() {
  // Slow query
  await new Promise(resolve => setTimeout(resolve, 2000))
  return { users: 1000, posts: 5000 }
}

async function getRecentActivity() {
  // Fast query
  return [{ id: 1, action: 'User logged in' }]
}

export default function DashboardPage() {
  return (
    <div>
      <h1>Dashboard</h1>
      
      {/* Fast content loads immediately */}
      <Suspense fallback={<div>Loading activity...</div>}>
        <RecentActivity />
      </Suspense>
      
      {/* Slow content streams in later */}
      <Suspense fallback={<div>Loading stats...</div>}>
        <Stats />
      </Suspense>
    </div>
  )
}

async function Stats() {
  const stats = await getStats()
  return <div>Users: {stats.users}, Posts: {stats.posts}</div>
}

async function RecentActivity() {
  const activity = await getRecentActivity()
  return (
    <ul>
      {activity.map(item => (
        <li key={item.id}>{item.action}</li>
      ))}
    </ul>
  )
}
```

## Performance Optimization

### Image Optimization
```typescript
import Image from 'next/image'

export function ProductCard({ product }) {
  return (
    <div>
      <Image
        src={product.image}
        alt={product.name}
        width={300}
        height={300}
        placeholder="blur"
        blurDataURL={product.blurDataURL}
        priority={false} // Set true for above-the-fold images
      />
      <h3>{product.name}</h3>
    </div>
  )
}
```

### Code Splitting
```typescript
import dynamic from 'next/dynamic'

// Lazy load heavy components
const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <div>Loading chart...</div>,
  ssr: false // Disable SSR for client-only components
})

export function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      <HeavyChart data={data} />
    </div>
  )
}
```

### Memoization
```typescript
import { memo, useMemo, useCallback } from 'react'

// Memoize expensive components
export const ExpensiveComponent = memo(function ExpensiveComponent({ data }) {
  // Component only re-renders if data changes
  return <div>{/* Render data */}</div>
})

// Memoize expensive calculations
function ProductList({ products, filter }) {
  const filteredProducts = useMemo(() => {
    return products.filter(p => p.category === filter)
  }, [products, filter])

  return (
    <ul>
      {filteredProducts.map(p => (
        <li key={p.id}>{p.name}</li>
      ))}
    </ul>
  )
}

// Memoize callbacks
function Parent() {
  const [count, setCount] = useState(0)

  const handleClick = useCallback(() => {
    console.log('Clicked')
  }, []) // Callback doesn't change between renders

  return <Child onClick={handleClick} />
}
```

## Error Handling

### Error Boundaries
```typescript
// app/error.tsx
'use client'

import { useEffect } from 'react'

export default function Error({
  error,
  reset
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  useEffect(() => {
    console.error('Error:', error)
  }, [error])

  return (
    <div className="flex min-h-screen flex-col items-center justify-center">
      <h2 className="text-2xl font-bold">Something went wrong!</h2>
      <button
        onClick={reset}
        className="mt-4 rounded bg-blue-600 px-4 py-2 text-white"
      >
        Try again
      </button>
    </div>
  )
}
```

### Global Error Handler
```typescript
// app/global-error.tsx
'use client'

export default function GlobalError({
  error,
  reset
}: {
  error: Error & { digest?: string }
  reset: () => void
}) {
  return (
    <html>
      <body>
        <h2>Something went wrong!</h2>
        <button onClick={reset}>Try again</button>
      </body>
    </html>
  )
}
```

## Testing

### Component Testing with React Testing Library
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { LoginForm } from './LoginForm'

describe('LoginForm', () => {
  it('renders login form', () => {
    render(<LoginForm />)
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
  })

  it('shows validation errors', async () => {
    render(<LoginForm />)
    
    const submitButton = screen.getByRole('button', { name: /login/i })
    fireEvent.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/invalid email/i)).toBeInTheDocument()
    })
  })

  it('submits form with valid data', async () => {
    const mockSubmit = jest.fn()
    render(<LoginForm onSubmit={mockSubmit} />)
    
    fireEvent.change(screen.getByLabelText(/email/i), {
      target: { value: 'test@example.com' }
    })
    fireEvent.change(screen.getByLabelText(/password/i), {
      target: { value: 'password123' }
    })
    
    fireEvent.click(screen.getByRole('button', { name: /login/i }))
    
    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      })
    })
  })
})
```

## Deployment Checklist

Before deploying to production:

- [ ] **Environment Variables**: All secrets in env vars, not hardcoded
- [ ] **TypeScript**: No type errors (`npm run type-check`)
- [ ] **Linting**: No lint errors (`npm run lint`)
- [ ] **Build**: Production build succeeds (`npm run build`)
- [ ] **Tests**: All tests pass (`npm test`)
- [ ] **Performance**: Lighthouse score > 90
- [ ] **SEO**: Meta tags, sitemap, robots.txt configured
- [ ] **Analytics**: Tracking configured (Google Analytics, Plausible, etc.)
- [ ] **Error Tracking**: Sentry or similar configured
- [ ] **Security**: Security headers, HTTPS, CSP configured
- [ ] **Images**: Optimized and using Next.js Image component
- [ ] **API Routes**: Rate limiting, validation, error handling
- [ ] **Database**: Migrations applied, indexes created
- [ ] **Caching**: Appropriate cache strategies configured

## Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [React Hook Form](https://react-hook-form.com/)
- [Zod Validation](https://zod.dev/)
- [Zustand State Management](https://zustand-demo.pmnd.rs/)
- [TailwindCSS](https://tailwindcss.com/)

---

**Remember**: Write clean, maintainable code. Prioritize user experience and performance. Test thoroughly before deploying.
