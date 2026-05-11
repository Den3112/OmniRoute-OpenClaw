---
name: performance-optimization
description: Use this skill for optimizing web application performance including Core Web Vitals, bundle size optimization, lazy loading, caching strategies, image optimization, code splitting, and performance monitoring (2026).
origin: Custom
---

# Performance & Optimization Skill

Comprehensive guide for optimizing web application performance (Updated May 2026).

## When to Activate

- Optimizing Core Web Vitals (LCP, FID, CLS)
- Reducing bundle size
- Implementing lazy loading
- Setting up caching strategies
- Optimizing images and assets
- Code splitting and tree shaking
- Database query optimization
- API response optimization
- Performance monitoring and profiling
- Lighthouse score improvement

## Core Web Vitals (2026 Standards)

### Understanding Core Web Vitals

**LCP (Largest Contentful Paint)** - Should be < 2.5s
- Measures loading performance
- Time until largest content element is visible

**INP (Interaction to Next Paint)** - Should be < 200ms
- Replaced FID in 2024
- Measures responsiveness to user interactions

**CLS (Cumulative Layout Shift)** - Should be < 0.1
- Measures visual stability
- Prevents unexpected layout shifts

### Measuring Performance
```typescript
// lib/performance.ts
export function measureWebVitals() {
  if (typeof window === 'undefined') return

  // LCP
  new PerformanceObserver((list) => {
    const entries = list.getEntries()
    const lastEntry = entries[entries.length - 1]
    console.log('LCP:', lastEntry.renderTime || lastEntry.loadTime)
  }).observe({ entryTypes: ['largest-contentful-paint'] })

  // INP
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      const inp = entry as PerformanceEventTiming
      console.log('INP:', inp.processingStart - inp.startTime)
    }
  }).observe({ type: 'event', buffered: true, durationThreshold: 16 })

  // CLS
  let clsScore = 0
  new PerformanceObserver((list) => {
    for (const entry of list.getEntries()) {
      if (!(entry as any).hadRecentInput) {
        clsScore += (entry as any).value
        console.log('CLS:', clsScore)
      }
    }
  }).observe({ entryTypes: ['layout-shift'] })
}

// Next.js integration
export function reportWebVitals(metric: any) {
  console.log(metric)
  
  // Send to analytics
  if (metric.label === 'web-vital') {
    // Send to your analytics service
    fetch('/api/analytics', {
      method: 'POST',
      body: JSON.stringify({
        name: metric.name,
        value: metric.value,
        id: metric.id
      })
    })
  }
}
```

## Bundle Size Optimization

### Analyzing Bundle Size
```bash
# Next.js Bundle Analyzer
npm install @next/bundle-analyzer

# Build with analysis
ANALYZE=true npm run build
```

```javascript
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true'
})

module.exports = withBundleAnalyzer({
  // Your Next.js config
})
```

### Tree Shaking
```typescript
// ❌ Bad: Imports entire library
import _ from 'lodash'
const result = _.debounce(fn, 300)

// ✅ Good: Import only what you need
import debounce from 'lodash/debounce'
const result = debounce(fn, 300)

// ✅ Better: Use modern alternatives
import { debounce } from 'es-toolkit'
```

### Code Splitting

#### Dynamic Imports
```typescript
// ❌ Bad: Import everything upfront
import HeavyComponent from './HeavyComponent'

export default function Page() {
  return <HeavyComponent />
}

// ✅ Good: Dynamic import
import dynamic from 'next/dynamic'

const HeavyComponent = dynamic(() => import('./HeavyComponent'), {
  loading: () => <div>Loading...</div>,
  ssr: false // Disable SSR if not needed
})

export default function Page() {
  return <HeavyComponent />
}
```

#### Route-based Code Splitting
```typescript
// Next.js automatically splits by route
// app/dashboard/page.tsx - separate bundle
// app/settings/page.tsx - separate bundle
```

#### Component-level Splitting
```typescript
'use client'

import { lazy, Suspense } from 'react'

// Lazy load heavy components
const Chart = lazy(() => import('./Chart'))
const DataTable = lazy(() => import('./DataTable'))

export function Dashboard() {
  return (
    <div>
      <h1>Dashboard</h1>
      
      <Suspense fallback={<div>Loading chart...</div>}>
        <Chart data={data} />
      </Suspense>
      
      <Suspense fallback={<div>Loading table...</div>}>
        <DataTable data={data} />
      </Suspense>
    </div>
  )
}
```

## Image Optimization

### Next.js Image Component
```typescript
import Image from 'next/image'

// ✅ Optimized images
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
        quality={85} // Default is 75
        sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
      />
    </div>
  )
}
```

### Modern Image Formats
```typescript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'], // AVIF first, then WebP
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
    minimumCacheTTL: 60 * 60 * 24 * 365 // 1 year
  }
}
```

### Lazy Loading Images
```typescript
export function ImageGallery({ images }) {
  return (
    <div>
      {images.map((img, i) => (
        <Image
          key={img.id}
          src={img.url}
          alt={img.alt}
          width={300}
          height={300}
          loading={i < 3 ? 'eager' : 'lazy'} // Load first 3 eagerly
        />
      ))}
    </div>
  )
}
```

## Caching Strategies

### HTTP Caching Headers
```typescript
// app/api/data/route.ts
import { NextResponse } from 'next/server'

export async function GET() {
  const data = await fetchData()

  return NextResponse.json(data, {
    headers: {
      'Cache-Control': 'public, s-maxage=3600, stale-while-revalidate=86400'
    }
  })
}
```

### Next.js Caching (2026)
```typescript
// Static data - cached indefinitely
export async function getStaticData() {
  const data = await fetch('https://api.example.com/data', {
    cache: 'force-cache'
  })
  return data.json()
}

// Revalidate every hour
export async function getRevalidatedData() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 3600 }
  })
  return data.json()
}

// No caching
export async function getDynamicData() {
  const data = await fetch('https://api.example.com/data', {
    cache: 'no-store'
  })
  return data.json()
}

// Tag-based revalidation
export async function getTaggedData() {
  const data = await fetch('https://api.example.com/data', {
    next: { tags: ['products'] }
  })
  return data.json()
}

// Revalidate by tag
import { revalidateTag } from 'next/cache'
revalidateTag('products')
```

### Client-Side Caching
```typescript
// React Query (TanStack Query)
import { useQuery } from '@tanstack/react-query'

export function useProducts() {
  return useQuery({
    queryKey: ['products'],
    queryFn: fetchProducts,
    staleTime: 5 * 60 * 1000, // 5 minutes
    cacheTime: 10 * 60 * 1000, // 10 minutes
    refetchOnWindowFocus: false
  })
}
```

### Service Worker Caching
```typescript
// public/sw.js
const CACHE_NAME = 'v1'
const urlsToCache = [
  '/',
  '/styles/main.css',
  '/scripts/main.js'
]

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(urlsToCache))
  )
})

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => response || fetch(event.request))
  )
})
```

## React Performance Optimization

### Memoization
```typescript
import { memo, useMemo, useCallback } from 'react'

// Memoize expensive components
export const ExpensiveComponent = memo(function ExpensiveComponent({ data }) {
  return <div>{/* Render data */}</div>
})

// Memoize expensive calculations
export function DataProcessor({ items }) {
  const processedData = useMemo(() => {
    return items
      .filter(item => item.active)
      .map(item => expensiveTransform(item))
      .sort((a, b) => b.score - a.score)
  }, [items])

  return <div>{processedData.map(item => <Item key={item.id} {...item} />)}</div>
}

// Memoize callbacks
export function Parent() {
  const [count, setCount] = useState(0)

  const handleClick = useCallback(() => {
    console.log('Clicked')
  }, []) // Callback doesn't change

  return <Child onClick={handleClick} />
}
```

### Virtual Scrolling
```typescript
import { useVirtualizer } from '@tanstack/react-virtual'

export function VirtualList({ items }) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    overscan: 5
  })

  return (
    <div ref={parentRef} style={{ height: '400px', overflow: 'auto' }}>
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative'
        }}
      >
        {virtualizer.getVirtualItems().map((virtualItem) => (
          <div
            key={virtualItem.key}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${virtualItem.size}px`,
              transform: `translateY(${virtualItem.start}px)`
            }}
          >
            {items[virtualItem.index].name}
          </div>
        ))}
      </div>
    </div>
  )
}
```

### React Compiler (2026)
```typescript
// next.config.js
module.exports = {
  experimental: {
    reactCompiler: true // Auto-memoization
  }
}

// No need for manual memo/useMemo/useCallback
// React Compiler handles it automatically
export function Component({ data }) {
  const processed = data.map(item => transform(item)) // Auto-memoized
  
  return <div>{processed}</div>
}
```

## Database Query Optimization

### Indexing
```sql
-- Add indexes for frequently queried columns
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_posts_author_created ON posts(author_id, created_at DESC);

-- Composite index for multiple columns
CREATE INDEX idx_posts_status_category ON posts(status, category_id);

-- Partial index
CREATE INDEX idx_active_users ON users(email) WHERE is_active = true;

-- Check index usage
SELECT 
  schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;
```

### Query Optimization
```typescript
// ❌ Bad: N+1 query problem
const posts = await prisma.post.findMany()
for (const post of posts) {
  post.author = await prisma.user.findUnique({ where: { id: post.authorId } })
}

// ✅ Good: Use include
const posts = await prisma.post.findMany({
  include: {
    author: true
  }
})

// ✅ Better: Select only needed fields
const posts = await prisma.post.findMany({
  select: {
    id: true,
    title: true,
    author: {
      select: {
        id: true,
        name: true,
        avatar: true
      }
    }
  }
})
```

### Connection Pooling
```typescript
// Increase pool size for high traffic
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
})

// PostgreSQL connection string with pool settings
// postgresql://user:pass@host:5432/db?connection_limit=20&pool_timeout=10
```

## API Response Optimization

### Compression
```typescript
// middleware.ts
import { NextResponse } from 'next/server'

export function middleware(request: Request) {
  const response = NextResponse.next()
  
  // Enable compression
  response.headers.set('Content-Encoding', 'gzip')
  
  return response
}
```

### Pagination
```typescript
// Cursor-based pagination (better for large datasets)
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url)
  const cursor = searchParams.get('cursor')
  const limit = 20

  const posts = await prisma.post.findMany({
    take: limit + 1,
    ...(cursor && {
      cursor: { id: parseInt(cursor) },
      skip: 1
    }),
    orderBy: { id: 'asc' }
  })

  const hasMore = posts.length > limit
  const items = hasMore ? posts.slice(0, -1) : posts
  const nextCursor = hasMore ? items[items.length - 1].id : null

  return NextResponse.json({
    items,
    nextCursor,
    hasMore
  })
}
```

### Response Streaming
```typescript
// app/api/stream/route.ts
export async function GET() {
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i < 10; i++) {
        const data = await fetchData(i)
        controller.enqueue(encoder.encode(JSON.stringify(data) + '\n'))
        await new Promise(resolve => setTimeout(resolve, 100))
      }
      controller.close()
    }
  })

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  })
}
```

## Font Optimization

### Next.js Font Optimization
```typescript
import { Inter, Roboto_Mono } from 'next/font/google'

const inter = Inter({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-inter'
})

const robotoMono = Roboto_Mono({
  subsets: ['latin'],
  display: 'swap',
  variable: '--font-roboto-mono'
})

export default function RootLayout({ children }) {
  return (
    <html lang="en" className={`${inter.variable} ${robotoMono.variable}`}>
      <body>{children}</body>
    </html>
  )
}
```

### Local Fonts
```typescript
import localFont from 'next/font/local'

const customFont = localFont({
  src: './fonts/CustomFont.woff2',
  display: 'swap',
  variable: '--font-custom'
})
```

## JavaScript Optimization

### Debouncing and Throttling
```typescript
// Debounce: Wait until user stops typing
export function debounce<T extends (...args: any[]) => any>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: NodeJS.Timeout

  return function (...args: Parameters<T>) {
    clearTimeout(timeoutId)
    timeoutId = setTimeout(() => fn(...args), delay)
  }
}

// Throttle: Execute at most once per interval
export function throttle<T extends (...args: any[]) => any>(
  fn: T,
  limit: number
): (...args: Parameters<T>) => void {
  let inThrottle: boolean

  return function (...args: Parameters<T>) {
    if (!inThrottle) {
      fn(...args)
      inThrottle = true
      setTimeout(() => (inThrottle = false), limit)
    }
  }
}

// Usage
const handleSearch = debounce((query: string) => {
  searchAPI(query)
}, 300)

const handleScroll = throttle(() => {
  updateScrollPosition()
}, 100)
```

### Web Workers
```typescript
// worker.ts
self.onmessage = (e: MessageEvent) => {
  const result = heavyComputation(e.data)
  self.postMessage(result)
}

// main.ts
const worker = new Worker(new URL('./worker.ts', import.meta.url))

worker.postMessage(data)

worker.onmessage = (e: MessageEvent) => {
  console.log('Result:', e.data)
}
```

## Monitoring and Profiling

### Performance Monitoring
```typescript
// lib/monitoring.ts
export class PerformanceMonitor {
  static measure(name: string, fn: () => void) {
    const start = performance.now()
    fn()
    const end = performance.now()
    console.log(`${name} took ${end - start}ms`)
  }

  static async measureAsync(name: string, fn: () => Promise<void>) {
    const start = performance.now()
    await fn()
    const end = performance.now()
    console.log(`${name} took ${end - start}ms`)
  }

  static mark(name: string) {
    performance.mark(name)
  }

  static measureBetween(name: string, startMark: string, endMark: string) {
    performance.measure(name, startMark, endMark)
    const measure = performance.getEntriesByName(name)[0]
    console.log(`${name}: ${measure.duration}ms`)
  }
}

// Usage
PerformanceMonitor.mark('fetch-start')
await fetchData()
PerformanceMonitor.mark('fetch-end')
PerformanceMonitor.measureBetween('data-fetch', 'fetch-start', 'fetch-end')
```

### React DevTools Profiler
```typescript
import { Profiler } from 'react'

function onRenderCallback(
  id: string,
  phase: 'mount' | 'update',
  actualDuration: number,
  baseDuration: number,
  startTime: number,
  commitTime: number
) {
  console.log(`${id} (${phase}) took ${actualDuration}ms`)
}

export function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <YourComponents />
    </Profiler>
  )
}
```

### Lighthouse CI
```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI

on: [push]

jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm ci
      - run: npm run build
      - name: Run Lighthouse CI
        uses: treosh/lighthouse-ci-action@v9
        with:
          urls: |
            http://localhost:3000
            http://localhost:3000/about
          uploadArtifacts: true
          temporaryPublicStorage: true
```

## Performance Budget

### Setting Budgets
```javascript
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      numberOfRuns: 3
    },
    assert: {
      assertions: {
        'categories:performance': ['error', { minScore: 0.9 }],
        'categories:accessibility': ['error', { minScore: 0.9 }],
        'first-contentful-paint': ['error', { maxNumericValue: 2000 }],
        'largest-contentful-paint': ['error', { maxNumericValue: 2500 }],
        'cumulative-layout-shift': ['error', { maxNumericValue: 0.1 }],
        'total-blocking-time': ['error', { maxNumericValue: 300 }]
      }
    }
  }
}
```

## Best Practices Checklist

### Loading Performance
- [ ] Optimize images (WebP/AVIF, lazy loading)
- [ ] Minimize JavaScript bundle size
- [ ] Use code splitting
- [ ] Enable compression (gzip/brotli)
- [ ] Implement caching strategies
- [ ] Use CDN for static assets
- [ ] Preload critical resources
- [ ] Defer non-critical JavaScript

### Runtime Performance
- [ ] Memoize expensive components
- [ ] Use virtual scrolling for long lists
- [ ] Debounce/throttle event handlers
- [ ] Avoid unnecessary re-renders
- [ ] Optimize database queries
- [ ] Use Web Workers for heavy computations
- [ ] Implement pagination

### Rendering Performance
- [ ] Minimize layout shifts (CLS)
- [ ] Optimize font loading
- [ ] Use CSS containment
- [ ] Avoid forced synchronous layouts
- [ ] Optimize animations (use transform/opacity)

### Monitoring
- [ ] Track Core Web Vitals
- [ ] Set up performance monitoring
- [ ] Monitor bundle size
- [ ] Run Lighthouse audits
- [ ] Set performance budgets
- [ ] Profile in production

## Resources

- [Web.dev Performance](https://web.dev/performance/)
- [Next.js Performance](https://nextjs.org/docs/app/building-your-application/optimizing)
- [React Performance](https://react.dev/learn/render-and-commit)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [WebPageTest](https://www.webpagetest.org/)

---

**Remember**: Measure first. Optimize what matters. Monitor continuously. Set budgets. Test on real devices. Performance is a feature.
