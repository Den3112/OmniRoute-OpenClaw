---
name: api-integration
description: Use this skill for integrating external APIs, building API clients, handling REST/GraphQL/gRPC, OAuth authentication, webhooks, rate limiting, error handling, and API best practices.
origin: Custom
---

# API Integration Skill

Comprehensive guide for integrating and working with external APIs (Updated May 2026).

## When to Activate

- Integrating third-party APIs
- Building API clients
- Implementing OAuth 2.0 authentication
- Setting up webhook handlers
- Working with REST, GraphQL, or gRPC
- Handling rate limiting and retries
- Managing API keys and secrets
- Error handling and logging
- API testing and mocking

## REST API Integration

### Fetch API (Modern Approach)
```typescript
// lib/api-client.ts
interface FetchOptions extends RequestInit {
  timeout?: number
  retries?: number
}

class APIClient {
  private baseURL: string
  private defaultHeaders: HeadersInit

  constructor(baseURL: string, apiKey?: string) {
    this.baseURL = baseURL
    this.defaultHeaders = {
      'Content-Type': 'application/json',
      ...(apiKey && { 'Authorization': `Bearer ${apiKey}` })
    }
  }

  private async fetchWithTimeout(
    url: string,
    options: FetchOptions = {}
  ): Promise<Response> {
    const { timeout = 10000, ...fetchOptions } = options

    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), timeout)

    try {
      const response = await fetch(url, {
        ...fetchOptions,
        signal: controller.signal
      })
      return response
    } finally {
      clearTimeout(timeoutId)
    }
  }

  private async fetchWithRetry(
    url: string,
    options: FetchOptions = {}
  ): Promise<Response> {
    const { retries = 3, ...fetchOptions } = options
    let lastError: Error

    for (let i = 0; i < retries; i++) {
      try {
        const response = await this.fetchWithTimeout(url, fetchOptions)
        
        // Don't retry on client errors (4xx)
        if (response.status >= 400 && response.status < 500) {
          return response
        }
        
        // Retry on server errors (5xx)
        if (response.status >= 500 && i < retries - 1) {
          await this.delay(Math.pow(2, i) * 1000) // Exponential backoff
          continue
        }
        
        return response
      } catch (error) {
        lastError = error as Error
        if (i < retries - 1) {
          await this.delay(Math.pow(2, i) * 1000)
        }
      }
    }

    throw lastError!
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  async get<T>(endpoint: string, options?: FetchOptions): Promise<T> {
    const response = await this.fetchWithRetry(`${this.baseURL}${endpoint}`, {
      method: 'GET',
      headers: this.defaultHeaders,
      ...options
    })

    if (!response.ok) {
      throw new APIError(response.status, await response.text())
    }

    return response.json()
  }

  async post<T>(endpoint: string, data: any, options?: FetchOptions): Promise<T> {
    const response = await this.fetchWithRetry(`${this.baseURL}${endpoint}`, {
      method: 'POST',
      headers: this.defaultHeaders,
      body: JSON.stringify(data),
      ...options
    })

    if (!response.ok) {
      throw new APIError(response.status, await response.text())
    }

    return response.json()
  }

  async put<T>(endpoint: string, data: any, options?: FetchOptions): Promise<T> {
    const response = await this.fetchWithRetry(`${this.baseURL}${endpoint}`, {
      method: 'PUT',
      headers: this.defaultHeaders,
      body: JSON.stringify(data),
      ...options
    })

    if (!response.ok) {
      throw new APIError(response.status, await response.text())
    }

    return response.json()
  }

  async delete<T>(endpoint: string, options?: FetchOptions): Promise<T> {
    const response = await this.fetchWithRetry(`${this.baseURL}${endpoint}`, {
      method: 'DELETE',
      headers: this.defaultHeaders,
      ...options
    })

    if (!response.ok) {
      throw new APIError(response.status, await response.text())
    }

    return response.json()
  }
}

class APIError extends Error {
  constructor(public status: number, message: string) {
    super(`API Error ${status}: ${message}`)
    this.name = 'APIError'
  }
}

// Usage
const api = new APIClient('https://api.example.com', process.env.API_KEY)

const users = await api.get<User[]>('/users')
const newUser = await api.post<User>('/users', { name: 'John' })
```

### Axios Alternative
```typescript
import axios, { AxiosInstance, AxiosError } from 'axios'

class APIService {
  private client: AxiosInstance

  constructor(baseURL: string, apiKey?: string) {
    this.client = axios.create({
      baseURL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        ...(apiKey && { 'Authorization': `Bearer ${apiKey}` })
      }
    })

    // Request interceptor
    this.client.interceptors.request.use(
      (config) => {
        console.log(`[API] ${config.method?.toUpperCase()} ${config.url}`)
        return config
      },
      (error) => Promise.reject(error)
    )

    // Response interceptor
    this.client.interceptors.response.use(
      (response) => response,
      async (error: AxiosError) => {
        const originalRequest = error.config

        // Retry on 5xx errors
        if (error.response?.status >= 500 && originalRequest) {
          await this.delay(1000)
          return this.client(originalRequest)
        }

        return Promise.reject(error)
      }
    )
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }

  async get<T>(url: string, params?: any): Promise<T> {
    const response = await this.client.get<T>(url, { params })
    return response.data
  }

  async post<T>(url: string, data: any): Promise<T> {
    const response = await this.client.post<T>(url, data)
    return response.data
  }

  async put<T>(url: string, data: any): Promise<T> {
    const response = await this.client.put<T>(url, data)
    return response.data
  }

  async delete<T>(url: string): Promise<T> {
    const response = await this.client.delete<T>(url)
    return response.data
  }
}
```

## GraphQL Integration

### Apollo Client Setup
```typescript
import { ApolloClient, InMemoryCache, HttpLink, from } from '@apollo/client'
import { onError } from '@apollo/client/link/error'
import { RetryLink } from '@apollo/client/link/retry'

const httpLink = new HttpLink({
  uri: process.env.GRAPHQL_ENDPOINT,
  headers: {
    authorization: `Bearer ${process.env.API_KEY}`
  }
})

const errorLink = onError(({ graphQLErrors, networkError }) => {
  if (graphQLErrors) {
    graphQLErrors.forEach(({ message, locations, path }) => {
      console.error(
        `[GraphQL error]: Message: ${message}, Location: ${locations}, Path: ${path}`
      )
    })
  }

  if (networkError) {
    console.error(`[Network error]: ${networkError}`)
  }
})

const retryLink = new RetryLink({
  delay: {
    initial: 300,
    max: 3000,
    jitter: true
  },
  attempts: {
    max: 3,
    retryIf: (error) => !!error
  }
})

export const apolloClient = new ApolloClient({
  link: from([errorLink, retryLink, httpLink]),
  cache: new InMemoryCache(),
  defaultOptions: {
    watchQuery: {
      fetchPolicy: 'cache-and-network'
    }
  }
})
```

### GraphQL Queries
```typescript
import { gql } from '@apollo/client'

// Define query
const GET_USERS = gql`
  query GetUsers($limit: Int!, $offset: Int!) {
    users(limit: $limit, offset: $offset) {
      id
      name
      email
      posts {
        id
        title
      }
    }
  }
`

// Execute query
const { data, loading, error } = await apolloClient.query({
  query: GET_USERS,
  variables: { limit: 10, offset: 0 }
})

// Mutation
const CREATE_USER = gql`
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
      id
      name
      email
    }
  }
`

const { data } = await apolloClient.mutate({
  mutation: CREATE_USER,
  variables: {
    input: {
      name: 'John Doe',
      email: 'john@example.com'
    }
  }
})
```

### GraphQL with urql (Lightweight Alternative)
```typescript
import { createClient, fetchExchange, cacheExchange } from 'urql'

const client = createClient({
  url: process.env.GRAPHQL_ENDPOINT!,
  exchanges: [cacheExchange, fetchExchange],
  fetchOptions: {
    headers: {
      authorization: `Bearer ${process.env.API_KEY}`
    }
  }
})

// Query
const result = await client.query(`
  query {
    users {
      id
      name
    }
  }
`, {}).toPromise()
```

## OAuth 2.0 Authentication

### OAuth Flow Implementation
```typescript
// lib/oauth.ts
import crypto from 'crypto'

interface OAuthConfig {
  clientId: string
  clientSecret: string
  redirectUri: string
  authorizationUrl: string
  tokenUrl: string
  scopes: string[]
}

class OAuthClient {
  constructor(private config: OAuthConfig) {}

  // Step 1: Generate authorization URL
  getAuthorizationUrl(state?: string): string {
    const params = new URLSearchParams({
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      response_type: 'code',
      scope: this.config.scopes.join(' '),
      state: state || crypto.randomBytes(16).toString('hex')
    })

    return `${this.config.authorizationUrl}?${params.toString()}`
  }

  // Step 2: Exchange code for access token
  async getAccessToken(code: string): Promise<{
    access_token: string
    refresh_token?: string
    expires_in: number
    token_type: string
  }> {
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(
          `${this.config.clientId}:${this.config.clientSecret}`
        ).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: this.config.redirectUri
      })
    })

    if (!response.ok) {
      throw new Error(`OAuth token exchange failed: ${await response.text()}`)
    }

    return response.json()
  }

  // Step 3: Refresh access token
  async refreshAccessToken(refreshToken: string): Promise<{
    access_token: string
    refresh_token?: string
    expires_in: number
  }> {
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(
          `${this.config.clientId}:${this.config.clientSecret}`
        ).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: refreshToken
      })
    })

    if (!response.ok) {
      throw new Error(`Token refresh failed: ${await response.text()}`)
    }

    return response.json()
  }
}

// Usage example: GitHub OAuth
const githubOAuth = new OAuthClient({
  clientId: process.env.GITHUB_CLIENT_ID!,
  clientSecret: process.env.GITHUB_CLIENT_SECRET!,
  redirectUri: 'https://yourapp.com/auth/callback',
  authorizationUrl: 'https://github.com/login/oauth/authorize',
  tokenUrl: 'https://github.com/login/oauth/access_token',
  scopes: ['user', 'repo']
})

// Redirect user to authorization URL
const authUrl = githubOAuth.getAuthorizationUrl()

// Handle callback
const tokens = await githubOAuth.getAccessToken(code)
```

### Next.js OAuth Route Handler
```typescript
// app/api/auth/github/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams
  const code = searchParams.get('code')
  const state = searchParams.get('state')

  if (!code) {
    return NextResponse.json({ error: 'No code provided' }, { status: 400 })
  }

  try {
    // Exchange code for token
    const tokens = await githubOAuth.getAccessToken(code)

    // Get user info
    const userResponse = await fetch('https://api.github.com/user', {
      headers: {
        'Authorization': `Bearer ${tokens.access_token}`
      }
    })

    const user = await userResponse.json()

    // Store tokens securely (in database)
    await storeUserTokens(user.id, tokens)

    // Redirect to app
    return NextResponse.redirect(new URL('/dashboard', request.url))
  } catch (error) {
    console.error('OAuth error:', error)
    return NextResponse.json({ error: 'Authentication failed' }, { status: 500 })
  }
}
```

## Webhook Handling

### Webhook Receiver
```typescript
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server'
import crypto from 'crypto'

const WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET!

function verifySignature(payload: string, signature: string, secret: string): boolean {
  const hmac = crypto.createHmac('sha256', secret)
  const digest = hmac.update(payload).digest('hex')
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest))
}

export async function POST(request: NextRequest) {
  const payload = await request.text()
  const signature = request.headers.get('stripe-signature')

  if (!signature) {
    return NextResponse.json({ error: 'No signature' }, { status: 400 })
  }

  // Verify webhook signature
  if (!verifySignature(payload, signature, WEBHOOK_SECRET)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 })
  }

  try {
    const event = JSON.parse(payload)

    // Handle different event types
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object)
        break

      case 'payment_intent.failed':
        await handlePaymentFailure(event.data.object)
        break

      case 'customer.subscription.created':
        await handleSubscriptionCreated(event.data.object)
        break

      case 'customer.subscription.deleted':
        await handleSubscriptionCancelled(event.data.object)
        break

      default:
        console.log(`Unhandled event type: ${event.type}`)
    }

    return NextResponse.json({ received: true })
  } catch (error) {
    console.error('Webhook error:', error)
    return NextResponse.json({ error: 'Webhook processing failed' }, { status: 500 })
  }
}

async function handlePaymentSuccess(paymentIntent: any) {
  console.log('Payment succeeded:', paymentIntent.id)
  // Update database, send confirmation email, etc.
}
```

### Webhook with Queue (Reliable Processing)
```typescript
import { Queue } from 'bullmq'

const webhookQueue = new Queue('webhooks', {
  connection: {
    host: process.env.REDIS_HOST,
    port: parseInt(process.env.REDIS_PORT || '6379')
  }
})

export async function POST(request: NextRequest) {
  const payload = await request.text()
  const signature = request.headers.get('stripe-signature')

  // Verify signature
  if (!verifySignature(payload, signature!, WEBHOOK_SECRET)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 })
  }

  // Add to queue for processing
  await webhookQueue.add('process-webhook', {
    payload: JSON.parse(payload),
    receivedAt: new Date().toISOString()
  })

  // Return immediately
  return NextResponse.json({ received: true })
}
```

## Rate Limiting

### Client-Side Rate Limiter
```typescript
class RateLimiter {
  private requests: number[] = []
  private maxRequests: number
  private windowMs: number

  constructor(maxRequests: number, windowMs: number) {
    this.maxRequests = maxRequests
    this.windowMs = windowMs
  }

  async checkLimit(): Promise<boolean> {
    const now = Date.now()
    
    // Remove old requests outside the window
    this.requests = this.requests.filter(time => now - time < this.windowMs)

    if (this.requests.length >= this.maxRequests) {
      const oldestRequest = this.requests[0]
      const waitTime = this.windowMs - (now - oldestRequest)
      
      if (waitTime > 0) {
        await new Promise(resolve => setTimeout(resolve, waitTime))
        return this.checkLimit()
      }
    }

    this.requests.push(now)
    return true
  }
}

// Usage
const limiter = new RateLimiter(10, 60000) // 10 requests per minute

async function makeAPICall() {
  await limiter.checkLimit()
  return fetch('https://api.example.com/data')
}
```

### Server-Side Rate Limiting with Redis
```typescript
import { Redis } from 'ioredis'

const redis = new Redis(process.env.REDIS_URL!)

async function checkRateLimit(
  key: string,
  maxRequests: number,
  windowSeconds: number
): Promise<{ allowed: boolean; remaining: number; resetAt: number }> {
  const now = Date.now()
  const windowStart = now - (windowSeconds * 1000)

  // Remove old entries
  await redis.zremrangebyscore(key, 0, windowStart)

  // Count requests in current window
  const count = await redis.zcard(key)

  if (count >= maxRequests) {
    const oldestRequest = await redis.zrange(key, 0, 0, 'WITHSCORES')
    const resetAt = parseInt(oldestRequest[1]) + (windowSeconds * 1000)

    return {
      allowed: false,
      remaining: 0,
      resetAt
    }
  }

  // Add current request
  await redis.zadd(key, now, `${now}-${Math.random()}`)
  await redis.expire(key, windowSeconds)

  return {
    allowed: true,
    remaining: maxRequests - count - 1,
    resetAt: now + (windowSeconds * 1000)
  }
}

// Usage in API route
export async function GET(request: NextRequest) {
  const userId = request.headers.get('x-user-id')
  
  const rateLimit = await checkRateLimit(
    `rate_limit:${userId}`,
    100, // 100 requests
    3600 // per hour
  )

  if (!rateLimit.allowed) {
    return NextResponse.json(
      { error: 'Rate limit exceeded' },
      {
        status: 429,
        headers: {
          'X-RateLimit-Remaining': '0',
          'X-RateLimit-Reset': rateLimit.resetAt.toString()
        }
      }
    )
  }

  // Process request
  return NextResponse.json({ data: 'success' })
}
```

## API Response Caching

### In-Memory Cache
```typescript
class APICache<T> {
  private cache = new Map<string, { data: T; expiresAt: number }>()

  set(key: string, data: T, ttlSeconds: number): void {
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + (ttlSeconds * 1000)
    })
  }

  get(key: string): T | null {
    const cached = this.cache.get(key)
    
    if (!cached) return null
    
    if (Date.now() > cached.expiresAt) {
      this.cache.delete(key)
      return null
    }
    
    return cached.data
  }

  delete(key: string): void {
    this.cache.delete(key)
  }

  clear(): void {
    this.cache.clear()
  }
}

// Usage
const cache = new APICache<User[]>()

async function getUsers(): Promise<User[]> {
  const cacheKey = 'users:all'
  
  // Check cache
  const cached = cache.get(cacheKey)
  if (cached) return cached
  
  // Fetch from API
  const users = await api.get<User[]>('/users')
  
  // Store in cache for 5 minutes
  cache.set(cacheKey, users, 300)
  
  return users
}
```

### Redis Cache
```typescript
import { Redis } from 'ioredis'

const redis = new Redis(process.env.REDIS_URL!)

async function getCachedData<T>(
  key: string,
  fetcher: () => Promise<T>,
  ttlSeconds: number = 300
): Promise<T> {
  // Try to get from cache
  const cached = await redis.get(key)
  
  if (cached) {
    return JSON.parse(cached)
  }
  
  // Fetch fresh data
  const data = await fetcher()
  
  // Store in cache
  await redis.setex(key, ttlSeconds, JSON.stringify(data))
  
  return data
}

// Usage
const users = await getCachedData(
  'users:all',
  () => api.get<User[]>('/users'),
  300 // 5 minutes
)
```

## Error Handling Best Practices

### Custom Error Classes
```typescript
export class APIError extends Error {
  constructor(
    public statusCode: number,
    message: string,
    public details?: any
  ) {
    super(message)
    this.name = 'APIError'
  }
}

export class NetworkError extends Error {
  constructor(message: string, public originalError?: Error) {
    super(message)
    this.name = 'NetworkError'
  }
}

export class ValidationError extends Error {
  constructor(message: string, public errors: any[]) {
    super(message)
    this.name = 'ValidationError'
  }
}

// Usage
try {
  const response = await fetch('https://api.example.com/data')
  
  if (!response.ok) {
    throw new APIError(
      response.status,
      'API request failed',
      await response.json()
    )
  }
  
  return response.json()
} catch (error) {
  if (error instanceof APIError) {
    console.error(`API Error ${error.statusCode}:`, error.message)
  } else if (error instanceof TypeError) {
    throw new NetworkError('Network request failed', error)
  } else {
    throw error
  }
}
```

## Common API Integrations

### OpenAI API
```typescript
const openai = new APIClient('https://api.openai.com/v1', process.env.OPENAI_API_KEY)

async function generateText(prompt: string): Promise<string> {
  const response = await openai.post<any>('/chat/completions', {
    model: 'gpt-4',
    messages: [{ role: 'user', content: prompt }],
    temperature: 0.7
  })

  return response.choices[0].message.content
}
```

### Stripe API
```typescript
import Stripe from 'stripe'

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2023-10-16'
})

async function createPaymentIntent(amount: number, currency: string = 'usd') {
  return await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true }
  })
}
```

### SendGrid Email API
```typescript
const sendgrid = new APIClient('https://api.sendgrid.com/v3', process.env.SENDGRID_API_KEY)

async function sendEmail(to: string, subject: string, html: string) {
  return await sendgrid.post('/mail/send', {
    personalizations: [{ to: [{ email: to }] }],
    from: { email: 'noreply@example.com' },
    subject,
    content: [{ type: 'text/html', value: html }]
  })
}
```

## Testing API Integrations

### Mock API Responses
```typescript
import { vi } from 'vitest'

// Mock fetch
global.fetch = vi.fn()

describe('API Client', () => {
  it('should fetch users', async () => {
    const mockUsers = [{ id: 1, name: 'John' }]
    
    ;(fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => mockUsers
    })

    const users = await api.get<User[]>('/users')
    
    expect(users).toEqual(mockUsers)
    expect(fetch).toHaveBeenCalledWith(
      'https://api.example.com/users',
      expect.objectContaining({ method: 'GET' })
    )
  })
})
```

## Best Practices Checklist

- [ ] Use environment variables for API keys
- [ ] Implement retry logic with exponential backoff
- [ ] Add request timeouts
- [ ] Validate API responses with schemas (Zod)
- [ ] Implement rate limiting
- [ ] Cache responses when appropriate
- [ ] Log all API requests and errors
- [ ] Handle errors gracefully
- [ ] Verify webhook signatures
- [ ] Use HTTPS for all API calls
- [ ] Implement request/response interceptors
- [ ] Monitor API usage and costs
- [ ] Document API integrations

## Resources

- [REST API Best Practices](https://restfulapi.net/)
- [GraphQL Documentation](https://graphql.org/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Stripe API Documentation](https://stripe.com/docs/api)
- [OpenAI API Documentation](https://platform.openai.com/docs)

---

**Remember**: Secure API keys. Handle errors gracefully. Implement retries. Cache when possible. Monitor usage. Test thoroughly.
