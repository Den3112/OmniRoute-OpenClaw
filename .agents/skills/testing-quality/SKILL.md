---
name: testing-quality
description: Use this skill for testing applications including unit tests, integration tests, E2E tests with Vitest, Jest, Playwright, Cypress, test coverage, TDD/BDD, mocking, and quality assurance best practices (2026).
origin: Custom
---

# Testing & Quality Assurance Skill

Comprehensive guide for testing modern applications (Updated May 2026).

## When to Activate

- Writing unit tests
- Creating integration tests
- Setting up E2E tests
- Implementing test coverage
- Practicing TDD/BDD
- Mocking dependencies
- Testing APIs
- Testing React components
- Setting up CI/CD testing
- Performance testing
- Load testing

## Testing Frameworks

### Vitest (Recommended for 2026)
**Why Vitest:**
- Blazing fast (Vite-powered)
- Jest-compatible API
- Native ESM support
- Built-in TypeScript support
- Watch mode out of the box
- Great DX

### Jest (Still widely used)
**When to use:**
- Legacy projects
- Need specific Jest plugins
- Team familiarity

### Playwright (E2E - Recommended)
**Why Playwright:**
- Multi-browser support
- Auto-wait mechanisms
- Network interception
- Mobile emulation
- Parallel execution

## Unit Testing with Vitest

### Setup
```bash
npm install -D vitest @vitest/ui
npm install -D @testing-library/react @testing-library/jest-dom
npm install -D jsdom
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './src/test/setup.ts',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/mockData'
      ]
    }
  }
})
```

```typescript
// src/test/setup.ts
import { expect, afterEach } from 'vitest'
import { cleanup } from '@testing-library/react'
import * as matchers from '@testing-library/jest-dom/matchers'

expect.extend(matchers)

afterEach(() => {
  cleanup()
})
```

### Basic Unit Tests
```typescript
// src/utils/math.ts
export function add(a: number, b: number): number {
  return a + b
}

export function divide(a: number, b: number): number {
  if (b === 0) throw new Error('Division by zero')
  return a / b
}

// src/utils/math.test.ts
import { describe, it, expect } from 'vitest'
import { add, divide } from './math'

describe('Math utilities', () => {
  describe('add', () => {
    it('should add two positive numbers', () => {
      expect(add(2, 3)).toBe(5)
    })

    it('should add negative numbers', () => {
      expect(add(-2, -3)).toBe(-5)
    })

    it('should handle zero', () => {
      expect(add(0, 5)).toBe(5)
    })
  })

  describe('divide', () => {
    it('should divide two numbers', () => {
      expect(divide(10, 2)).toBe(5)
    })

    it('should throw error on division by zero', () => {
      expect(() => divide(10, 0)).toThrow('Division by zero')
    })
  })
})
```

### Testing Async Functions
```typescript
// src/api/users.ts
export async function fetchUser(id: number): Promise<User> {
  const response = await fetch(`/api/users/${id}`)
  if (!response.ok) throw new Error('User not found')
  return response.json()
}

// src/api/users.test.ts
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { fetchUser } from './users'

describe('fetchUser', () => {
  beforeEach(() => {
    vi.resetAllMocks()
  })

  it('should fetch user successfully', async () => {
    const mockUser = { id: 1, name: 'John' }
    
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => mockUser
    })

    const user = await fetchUser(1)
    
    expect(user).toEqual(mockUser)
    expect(fetch).toHaveBeenCalledWith('/api/users/1')
  })

  it('should throw error when user not found', async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false
    })

    await expect(fetchUser(999)).rejects.toThrow('User not found')
  })
})
```

## React Component Testing

### Testing Components
```typescript
// src/components/Button.tsx
interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
  disabled?: boolean
  variant?: 'primary' | 'secondary'
}

export function Button({ children, onClick, disabled, variant = 'primary' }: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`btn btn-${variant}`}
    >
      {children}
    </button>
  )
}

// src/components/Button.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Button } from './Button'

describe('Button', () => {
  it('should render children', () => {
    render(<Button>Click me</Button>)
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('should call onClick when clicked', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick}>Click me</Button>)
    
    fireEvent.click(screen.getByText('Click me'))
    
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('should not call onClick when disabled', () => {
    const handleClick = vi.fn()
    render(<Button onClick={handleClick} disabled>Click me</Button>)
    
    fireEvent.click(screen.getByText('Click me'))
    
    expect(handleClick).not.toHaveBeenCalled()
  })

  it('should apply correct variant class', () => {
    const { rerender } = render(<Button variant="primary">Button</Button>)
    expect(screen.getByRole('button')).toHaveClass('btn-primary')
    
    rerender(<Button variant="secondary">Button</Button>)
    expect(screen.getByRole('button')).toHaveClass('btn-secondary')
  })
})
```

### Testing Hooks
```typescript
// src/hooks/useCounter.ts
import { useState } from 'react'

export function useCounter(initialValue: number = 0) {
  const [count, setCount] = useState(initialValue)

  const increment = () => setCount(c => c + 1)
  const decrement = () => setCount(c => c - 1)
  const reset = () => setCount(initialValue)

  return { count, increment, decrement, reset }
}

// src/hooks/useCounter.test.ts
import { describe, it, expect } from 'vitest'
import { renderHook, act } from '@testing-library/react'
import { useCounter } from './useCounter'

describe('useCounter', () => {
  it('should initialize with default value', () => {
    const { result } = renderHook(() => useCounter())
    expect(result.current.count).toBe(0)
  })

  it('should initialize with custom value', () => {
    const { result } = renderHook(() => useCounter(10))
    expect(result.current.count).toBe(10)
  })

  it('should increment count', () => {
    const { result } = renderHook(() => useCounter())
    
    act(() => {
      result.current.increment()
    })
    
    expect(result.current.count).toBe(1)
  })

  it('should decrement count', () => {
    const { result } = renderHook(() => useCounter(5))
    
    act(() => {
      result.current.decrement()
    })
    
    expect(result.current.count).toBe(4)
  })

  it('should reset to initial value', () => {
    const { result } = renderHook(() => useCounter(10))
    
    act(() => {
      result.current.increment()
      result.current.increment()
      result.current.reset()
    })
    
    expect(result.current.count).toBe(10)
  })
})
```

### Testing Forms
```typescript
// src/components/LoginForm.test.tsx
import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { LoginForm } from './LoginForm'

describe('LoginForm', () => {
  it('should render form fields', () => {
    render(<LoginForm onSubmit={vi.fn()} />)
    
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /login/i })).toBeInTheDocument()
  })

  it('should show validation errors', async () => {
    render(<LoginForm onSubmit={vi.fn()} />)
    
    const submitButton = screen.getByRole('button', { name: /login/i })
    fireEvent.click(submitButton)
    
    await waitFor(() => {
      expect(screen.getByText(/email is required/i)).toBeInTheDocument()
      expect(screen.getByText(/password is required/i)).toBeInTheDocument()
    })
  })

  it('should submit form with valid data', async () => {
    const handleSubmit = vi.fn()
    const user = userEvent.setup()
    
    render(<LoginForm onSubmit={handleSubmit} />)
    
    await user.type(screen.getByLabelText(/email/i), 'test@example.com')
    await user.type(screen.getByLabelText(/password/i), 'password123')
    await user.click(screen.getByRole('button', { name: /login/i }))
    
    await waitFor(() => {
      expect(handleSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        password: 'password123'
      })
    })
  })

  it('should disable submit button while loading', async () => {
    render(<LoginForm onSubmit={vi.fn()} />)
    
    const submitButton = screen.getByRole('button', { name: /login/i })
    
    // Simulate loading state
    fireEvent.click(submitButton)
    
    expect(submitButton).toBeDisabled()
  })
})
```

## Integration Testing

### API Integration Tests
```typescript
// src/api/users.integration.test.ts
import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { setupServer } from 'msw/node'
import { http, HttpResponse } from 'msw'
import { fetchUsers, createUser } from './users'

const server = setupServer(
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'John' },
      { id: 2, name: 'Jane' }
    ])
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json()
    return HttpResponse.json(
      { id: 3, ...body },
      { status: 201 }
    )
  })
)

beforeAll(() => server.listen())
afterAll(() => server.close())

describe('Users API Integration', () => {
  it('should fetch all users', async () => {
    const users = await fetchUsers()
    
    expect(users).toHaveLength(2)
    expect(users[0]).toEqual({ id: 1, name: 'John' })
  })

  it('should create new user', async () => {
    const newUser = { name: 'Bob', email: 'bob@example.com' }
    const created = await createUser(newUser)
    
    expect(created).toMatchObject(newUser)
    expect(created.id).toBe(3)
  })
})
```

### Database Integration Tests
```typescript
// src/database/users.integration.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

describe('User Database Operations', () => {
  beforeEach(async () => {
    // Clean database before each test
    await prisma.user.deleteMany()
  })

  afterEach(async () => {
    await prisma.$disconnect()
  })

  it('should create user', async () => {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User'
      }
    })

    expect(user.id).toBeDefined()
    expect(user.email).toBe('test@example.com')
  })

  it('should find user by email', async () => {
    await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User'
      }
    })

    const user = await prisma.user.findUnique({
      where: { email: 'test@example.com' }
    })

    expect(user).not.toBeNull()
    expect(user?.name).toBe('Test User')
  })

  it('should update user', async () => {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User'
      }
    })

    const updated = await prisma.user.update({
      where: { id: user.id },
      data: { name: 'Updated Name' }
    })

    expect(updated.name).toBe('Updated Name')
  })

  it('should delete user', async () => {
    const user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'Test User'
      }
    })

    await prisma.user.delete({
      where: { id: user.id }
    })

    const found = await prisma.user.findUnique({
      where: { id: user.id }
    })

    expect(found).toBeNull()
  })
})
```

## E2E Testing with Playwright

### Setup
```bash
npm install -D @playwright/test
npx playwright install
```

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure'
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] }
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] }
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] }
    },
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] }
    }
  ],

  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI
  }
})
```

### E2E Tests
```typescript
// e2e/login.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Login Flow', () => {
  test('should login successfully', async ({ page }) => {
    await page.goto('/login')

    // Fill form
    await page.fill('input[name="email"]', 'test@example.com')
    await page.fill('input[name="password"]', 'password123')

    // Submit
    await page.click('button[type="submit"]')

    // Wait for navigation
    await page.waitForURL('/dashboard')

    // Verify logged in
    await expect(page.locator('text=Welcome')).toBeVisible()
  })

  test('should show error with invalid credentials', async ({ page }) => {
    await page.goto('/login')

    await page.fill('input[name="email"]', 'wrong@example.com')
    await page.fill('input[name="password"]', 'wrongpass')
    await page.click('button[type="submit"]')

    // Verify error message
    await expect(page.locator('text=Invalid credentials')).toBeVisible()
  })

  test('should validate required fields', async ({ page }) => {
    await page.goto('/login')

    await page.click('button[type="submit"]')

    // Check validation errors
    await expect(page.locator('text=Email is required')).toBeVisible()
    await expect(page.locator('text=Password is required')).toBeVisible()
  })
})
```

### Testing API Calls
```typescript
// e2e/api.spec.ts
import { test, expect } from '@playwright/test'

test.describe('API Tests', () => {
  test('should fetch users', async ({ request }) => {
    const response = await request.get('/api/users')
    
    expect(response.ok()).toBeTruthy()
    
    const users = await response.json()
    expect(users).toBeInstanceOf(Array)
  })

  test('should create user', async ({ request }) => {
    const response = await request.post('/api/users', {
      data: {
        name: 'John Doe',
        email: 'john@example.com'
      }
    })

    expect(response.status()).toBe(201)
    
    const user = await response.json()
    expect(user.name).toBe('John Doe')
  })

  test('should handle authentication', async ({ request }) => {
    // Login
    const loginResponse = await request.post('/api/auth/login', {
      data: {
        email: 'test@example.com',
        password: 'password123'
      }
    })

    const { token } = await loginResponse.json()

    // Use token for authenticated request
    const response = await request.get('/api/profile', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })

    expect(response.ok()).toBeTruthy()
  })
})
```

### Visual Regression Testing
```typescript
// e2e/visual.spec.ts
import { test, expect } from '@playwright/test'

test.describe('Visual Regression', () => {
  test('homepage should match snapshot', async ({ page }) => {
    await page.goto('/')
    await expect(page).toHaveScreenshot('homepage.png')
  })

  test('button states should match snapshots', async ({ page }) => {
    await page.goto('/components')

    // Normal state
    const button = page.locator('button.primary')
    await expect(button).toHaveScreenshot('button-normal.png')

    // Hover state
    await button.hover()
    await expect(button).toHaveScreenshot('button-hover.png')

    // Disabled state
    await page.click('button#toggle-disabled')
    await expect(button).toHaveScreenshot('button-disabled.png')
  })
})
```

## Mocking

### Mocking Functions
```typescript
import { vi } from 'vitest'

// Mock function
const mockFn = vi.fn()

// Mock implementation
const mockFn = vi.fn((x: number) => x * 2)

// Mock return value
mockFn.mockReturnValue(42)
mockFn.mockReturnValueOnce(1).mockReturnValueOnce(2)

// Mock resolved value (async)
mockFn.mockResolvedValue({ id: 1, name: 'John' })

// Mock rejected value
mockFn.mockRejectedValue(new Error('Failed'))

// Assertions
expect(mockFn).toHaveBeenCalled()
expect(mockFn).toHaveBeenCalledTimes(2)
expect(mockFn).toHaveBeenCalledWith('arg1', 'arg2')
expect(mockFn).toHaveBeenLastCalledWith('lastArg')
```

### Mocking Modules
```typescript
// Mock entire module
vi.mock('./api/users', () => ({
  fetchUsers: vi.fn().mockResolvedValue([
    { id: 1, name: 'John' }
  ]),
  createUser: vi.fn()
}))

// Partial mock
vi.mock('./api/users', async () => {
  const actual = await vi.importActual('./api/users')
  return {
    ...actual,
    fetchUsers: vi.fn().mockResolvedValue([])
  }
})

// Mock with factory
vi.mock('axios', () => ({
  default: {
    get: vi.fn(),
    post: vi.fn()
  }
}))
```

### Mocking Timers
```typescript
import { vi, beforeEach, afterEach } from 'vitest'

beforeEach(() => {
  vi.useFakeTimers()
})

afterEach(() => {
  vi.restoreAllMocks()
})

test('should debounce function', () => {
  const fn = vi.fn()
  const debounced = debounce(fn, 1000)

  debounced()
  debounced()
  debounced()

  expect(fn).not.toHaveBeenCalled()

  vi.advanceTimersByTime(1000)

  expect(fn).toHaveBeenCalledTimes(1)
})
```

## Test Coverage

### Running Coverage
```bash
# Vitest
npm run test -- --coverage

# View coverage report
open coverage/index.html
```

### Coverage Configuration
```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'src/test/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/mockData',
        '**/*.test.{ts,tsx}',
        '**/*.spec.{ts,tsx}'
      ],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80
      }
    }
  }
})
```

## TDD (Test-Driven Development)

### TDD Workflow
```typescript
// 1. Write failing test
test('should calculate total price', () => {
  const items = [
    { price: 10, quantity: 2 },
    { price: 5, quantity: 3 }
  ]
  
  expect(calculateTotal(items)).toBe(35)
})

// 2. Write minimal code to pass
function calculateTotal(items: Array<{ price: number; quantity: number }>): number {
  return items.reduce((sum, item) => sum + (item.price * item.quantity), 0)
}

// 3. Refactor if needed
function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, { price, quantity }) => sum + price * quantity, 0)
}
```

## Performance Testing

### Load Testing with k6
```javascript
// load-test.js
import http from 'k6/http'
import { check, sleep } from 'k6'

export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp up to 20 users
    { duration: '1m', target: 20 },   // Stay at 20 users
    { duration: '30s', target: 0 }    // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.01']    // Error rate must be below 1%
  }
}

export default function () {
  const response = http.get('https://api.example.com/users')
  
  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500
  })
  
  sleep(1)
}
```

## CI/CD Integration

### GitHub Actions
```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run type check
        run: npm run type-check

      - name: Run unit tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

      - name: Run E2E tests
        run: npx playwright test

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: playwright-report
          path: playwright-report/
```

## Best Practices Checklist

- [ ] Write tests before or alongside code (TDD)
- [ ] Aim for 80%+ code coverage
- [ ] Test edge cases and error conditions
- [ ] Use descriptive test names
- [ ] Keep tests isolated and independent
- [ ] Mock external dependencies
- [ ] Test user behavior, not implementation
- [ ] Run tests in CI/CD pipeline
- [ ] Use snapshot testing sparingly
- [ ] Test accessibility
- [ ] Perform visual regression testing
- [ ] Load test critical endpoints
- [ ] Monitor test execution time
- [ ] Keep tests maintainable

## Resources

- [Vitest Documentation](https://vitest.dev/)
- [Playwright Documentation](https://playwright.dev/)
- [Testing Library](https://testing-library.com/)
- [MSW (Mock Service Worker)](https://mswjs.io/)
- [k6 Load Testing](https://k6.io/)

---

**Remember**: Test behavior, not implementation. Keep tests simple. Mock external dependencies. Aim for high coverage. Run tests in CI/CD.
