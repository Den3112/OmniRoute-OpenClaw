---
name: internationalization
description: Use this skill for implementing internationalization (i18n) and localization (l10n) including next-intl, multi-language support, RTL languages, date/time/currency formatting, translation management, and locale detection (2026).
origin: Custom
---

# Internationalization (i18n) & Localization Skill

Comprehensive guide for implementing i18n in web applications (Updated May 2026).

## When to Activate

- Adding multi-language support
- Implementing locale switching
- Formatting dates, numbers, currencies
- Supporting RTL languages
- Managing translations
- Detecting user locale
- Localizing content
- SEO for multiple languages

## i18n vs l10n

**Internationalization (i18n)** - Making app ready for multiple languages
- Code structure
- Text extraction
- Locale detection
- Format handling

**Localization (l10n)** - Adapting app for specific locale
- Translations
- Cultural adaptations
- Local formats
- Regional content

## next-intl (Recommended for Next.js 2026)

### Why next-intl?
- Built for Next.js App Router
- Server Components support
- Type-safe translations
- Automatic locale detection
- SEO-friendly
- Small bundle size

### Setup

```bash
npm install next-intl
```

### Configuration

```typescript
// i18n.ts
import { getRequestConfig } from 'next-intl/server'
import { notFound } from 'next/navigation'

export const locales = ['en', 'es', 'fr', 'de', 'ja', 'ar'] as const
export type Locale = (typeof locales)[number]

export default getRequestConfig(async ({ locale }) => {
  // Validate locale
  if (!locales.includes(locale as Locale)) {
    notFound()
  }

  return {
    messages: (await import(`./messages/${locale}.json`)).default
  }
})
```

### Middleware

```typescript
// middleware.ts
import createMiddleware from 'next-intl/middleware'
import { locales } from './i18n'

export default createMiddleware({
  locales,
  defaultLocale: 'en',
  localePrefix: 'as-needed' // Don't prefix default locale
})

export const config = {
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)']
}
```

### Layout Setup

```typescript
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from 'next-intl'
import { getMessages } from 'next-intl/server'
import { notFound } from 'next/navigation'
import { locales } from '@/i18n'

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }))
}

export default async function LocaleLayout({
  children,
  params: { locale }
}: {
  children: React.ReactNode
  params: { locale: string }
}) {
  // Validate locale
  if (!locales.includes(locale as any)) {
    notFound()
  }

  const messages = await getMessages()

  return (
    <html lang={locale} dir={locale === 'ar' ? 'rtl' : 'ltr'}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  )
}
```

### Translation Files

```json
// messages/en.json
{
  "common": {
    "welcome": "Welcome",
    "hello": "Hello {name}",
    "itemCount": "{count, plural, =0 {No items} =1 {One item} other {# items}}"
  },
  "navigation": {
    "home": "Home",
    "about": "About",
    "contact": "Contact"
  },
  "auth": {
    "login": "Login",
    "logout": "Logout",
    "register": "Register"
  }
}
```

```json
// messages/es.json
{
  "common": {
    "welcome": "Bienvenido",
    "hello": "Hola {name}",
    "itemCount": "{count, plural, =0 {Sin artículos} =1 {Un artículo} other {# artículos}}"
  },
  "navigation": {
    "home": "Inicio",
    "about": "Acerca de",
    "contact": "Contacto"
  },
  "auth": {
    "login": "Iniciar sesión",
    "logout": "Cerrar sesión",
    "register": "Registrarse"
  }
}
```

### Server Components

```typescript
// app/[locale]/page.tsx
import { useTranslations } from 'next-intl'

export default function HomePage() {
  const t = useTranslations('common')

  return (
    <div>
      <h1>{t('welcome')}</h1>
      <p>{t('hello', { name: 'John' })}</p>
      <p>{t('itemCount', { count: 5 })}</p>
    </div>
  )
}
```

### Client Components

```typescript
'use client'

import { useTranslations } from 'next-intl'

export function WelcomeMessage() {
  const t = useTranslations('common')

  return <h1>{t('welcome')}</h1>
}
```

### Locale Switcher

```typescript
'use client'

import { useLocale } from 'next-intl'
import { useRouter, usePathname } from 'next/navigation'
import { locales, type Locale } from '@/i18n'

export function LocaleSwitcher() {
  const locale = useLocale()
  const router = useRouter()
  const pathname = usePathname()

  const switchLocale = (newLocale: Locale) => {
    // Remove current locale from pathname
    const segments = pathname.split('/')
    segments[1] = newLocale
    const newPathname = segments.join('/')

    router.push(newPathname)
  }

  return (
    <select
      value={locale}
      onChange={(e) => switchLocale(e.target.value as Locale)}
      className="px-3 py-2 border rounded"
    >
      {locales.map((loc) => (
        <option key={loc} value={loc}>
          {getLocaleName(loc)}
        </option>
      ))}
    </select>
  )
}

function getLocaleName(locale: string): string {
  const names: Record<string, string> = {
    en: 'English',
    es: 'Español',
    fr: 'Français',
    de: 'Deutsch',
    ja: '日本語',
    ar: 'العربية'
  }
  return names[locale] || locale
}
```

## Date & Time Formatting

```typescript
import { useFormatter } from 'next-intl'

export function DateTimeExample() {
  const format = useFormatter()
  const now = new Date()

  return (
    <div>
      {/* Date */}
      <p>{format.dateTime(now, { dateStyle: 'full' })}</p>
      {/* Output (en): Saturday, May 10, 2026 */}
      {/* Output (es): sábado, 10 de mayo de 2026 */}

      {/* Time */}
      <p>{format.dateTime(now, { timeStyle: 'short' })}</p>
      {/* Output: 8:15 PM */}

      {/* Custom format */}
      <p>
        {format.dateTime(now, {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
          hour: 'numeric',
          minute: 'numeric'
        })}
      </p>

      {/* Relative time */}
      <p>{format.relativeTime(now, new Date(Date.now() - 3600000))}</p>
      {/* Output: 1 hour ago */}
    </div>
  )
}
```

## Number & Currency Formatting

```typescript
import { useFormatter } from 'next-intl'

export function NumberExample() {
  const format = useFormatter()

  return (
    <div>
      {/* Number */}
      <p>{format.number(1234567.89)}</p>
      {/* Output (en): 1,234,567.89 */}
      {/* Output (de): 1.234.567,89 */}

      {/* Currency */}
      <p>{format.number(1234.56, { style: 'currency', currency: 'USD' })}</p>
      {/* Output (en): $1,234.56 */}
      {/* Output (es): US$1,234.56 */}

      {/* Percentage */}
      <p>{format.number(0.75, { style: 'percent' })}</p>
      {/* Output: 75% */}

      {/* Compact notation */}
      <p>{format.number(1234567, { notation: 'compact' })}</p>
      {/* Output (en): 1.2M */}
    </div>
  )
}
```

## Pluralization

```typescript
// messages/en.json
{
  "items": "{count, plural, =0 {No items} =1 {One item} other {# items}}",
  "notifications": "{count, plural, =0 {No new notifications} =1 {One new notification} other {# new notifications}}"
}

// Component
import { useTranslations } from 'next-intl'

export function ItemCount({ count }: { count: number }) {
  const t = useTranslations()

  return <p>{t('items', { count })}</p>
}
```

## Rich Text Formatting

```typescript
// messages/en.json
{
  "richText": "Welcome <b>back</b>, {name}! Check your <link>dashboard</link>."
}

// Component
import { useTranslations } from 'next-intl'

export function RichTextExample() {
  const t = useTranslations()

  return (
    <p>
      {t.rich('richText', {
        name: 'John',
        b: (chunks) => <strong>{chunks}</strong>,
        link: (chunks) => <a href="/dashboard">{chunks}</a>
      })}
    </p>
  )
}
```

## RTL (Right-to-Left) Support

### CSS for RTL

```css
/* globals.css */
[dir='rtl'] {
  direction: rtl;
}

[dir='rtl'] .text-left {
  text-align: right;
}

[dir='rtl'] .text-right {
  text-align: left;
}

/* Use logical properties */
.element {
  margin-inline-start: 1rem; /* margin-left in LTR, margin-right in RTL */
  margin-inline-end: 1rem;   /* margin-right in LTR, margin-left in RTL */
  padding-inline: 1rem;
}
```

### Tailwind CSS RTL

```typescript
// tailwind.config.js
module.exports = {
  plugins: [
    require('tailwindcss-rtl')
  ]
}

// Usage
<div className="ms-4 me-2"> {/* margin-start and margin-end */}
  <p className="text-start">Text</p> {/* text-align: start */}
</div>
```

### Dynamic RTL Detection

```typescript
'use client'

import { useLocale } from 'next-intl'
import { useEffect } from 'react'

const RTL_LOCALES = ['ar', 'he', 'fa', 'ur']

export function RTLProvider({ children }: { children: React.ReactNode }) {
  const locale = useLocale()
  const isRTL = RTL_LOCALES.includes(locale)

  useEffect(() => {
    document.documentElement.dir = isRTL ? 'rtl' : 'ltr'
  }, [isRTL])

  return <>{children}</>
}
```

## SEO for Multiple Languages

### Metadata

```typescript
// app/[locale]/layout.tsx
import { Metadata } from 'next'
import { getTranslations } from 'next-intl/server'

export async function generateMetadata({
  params: { locale }
}: {
  params: { locale: string }
}): Promise<Metadata> {
  const t = await getTranslations({ locale, namespace: 'metadata' })

  return {
    title: t('title'),
    description: t('description'),
    alternates: {
      canonical: `https://example.com/${locale}`,
      languages: {
        'en': 'https://example.com/en',
        'es': 'https://example.com/es',
        'fr': 'https://example.com/fr'
      }
    }
  }
}
```

### Sitemap

```typescript
// app/sitemap.ts
import { MetadataRoute } from 'next'
import { locales } from '@/i18n'

export default function sitemap(): MetadataRoute.Sitemap {
  const routes = ['', '/about', '/contact']
  
  return routes.flatMap((route) =>
    locales.map((locale) => ({
      url: `https://example.com/${locale}${route}`,
      lastModified: new Date(),
      alternates: {
        languages: Object.fromEntries(
          locales.map((loc) => [loc, `https://example.com/${loc}${route}`])
        )
      }
    }))
  )
}
```

## Translation Management

### Namespace Organization

```
messages/
├── en/
│   ├── common.json       # Shared translations
│   ├── navigation.json   # Navigation items
│   ├── auth.json         # Authentication
│   ├── errors.json       # Error messages
│   └── pages/
│       ├── home.json
│       ├── about.json
│       └── contact.json
└── es/
    ├── common.json
    ├── navigation.json
    └── ...
```

### Loading Namespaces

```typescript
// i18n.ts
export default getRequestConfig(async ({ locale }) => {
  return {
    messages: {
      ...(await import(`./messages/${locale}/common.json`)).default,
      ...(await import(`./messages/${locale}/navigation.json`)).default,
      ...(await import(`./messages/${locale}/auth.json`)).default
    }
  }
})
```

### Type-Safe Translations

```typescript
// types/translations.ts
import en from '@/messages/en.json'

type Messages = typeof en

declare global {
  interface IntlMessages extends Messages {}
}

// Now you get autocomplete and type checking
const t = useTranslations('common')
t('welcome') // ✅ Type-safe
t('invalid') // ❌ TypeScript error
```

## Locale Detection

### Browser Detection

```typescript
// middleware.ts
import { NextRequest } from 'next/server'
import createMiddleware from 'next-intl/middleware'
import { locales } from './i18n'

export default createMiddleware({
  locales,
  defaultLocale: 'en',
  localeDetection: true, // Auto-detect from Accept-Language header
  localePrefix: 'as-needed'
})
```

### Cookie-Based Persistence

```typescript
// middleware.ts
import { NextRequest, NextResponse } from 'next/server'
import createIntlMiddleware from 'next-intl/middleware'
import { locales } from './i18n'

const intlMiddleware = createIntlMiddleware({
  locales,
  defaultLocale: 'en'
})

export default function middleware(request: NextRequest) {
  const response = intlMiddleware(request)
  
  // Save locale to cookie
  const locale = request.nextUrl.pathname.split('/')[1]
  if (locales.includes(locale as any)) {
    response.cookies.set('NEXT_LOCALE', locale, {
      maxAge: 365 * 24 * 60 * 60 // 1 year
    })
  }
  
  return response
}
```

## Dynamic Content Translation

### Database Content

```typescript
// Prisma schema
model Post {
  id          Int      @id @default(autoincrement())
  translations PostTranslation[]
}

model PostTranslation {
  id       Int    @id @default(autoincrement())
  postId   Int
  post     Post   @relation(fields: [postId], references: [id])
  locale   String
  title    String
  content  String
  
  @@unique([postId, locale])
}

// Fetch translated content
async function getPost(id: number, locale: string) {
  const post = await prisma.post.findUnique({
    where: { id },
    include: {
      translations: {
        where: { locale }
      }
    }
  })

  return {
    id: post.id,
    title: post.translations[0]?.title || 'Untranslated',
    content: post.translations[0]?.content || ''
  }
}
```

### CMS Integration

```typescript
// Fetch from headless CMS
async function getCMSContent(locale: string) {
  const response = await fetch(`https://cms.example.com/api/content?locale=${locale}`)
  return response.json()
}
```

## Testing i18n

```typescript
import { render, screen } from '@testing-library/react'
import { NextIntlClientProvider } from 'next-intl'
import HomePage from './page'

const messages = {
  common: {
    welcome: 'Welcome'
  }
}

test('renders translated content', () => {
  render(
    <NextIntlClientProvider locale="en" messages={messages}>
      <HomePage />
    </NextIntlClientProvider>
  )

  expect(screen.getByText('Welcome')).toBeInTheDocument()
})
```

## Best Practices Checklist

### Setup
- [ ] Use next-intl for Next.js projects
- [ ] Organize translations by namespace
- [ ] Enable type-safe translations
- [ ] Set up locale detection
- [ ] Configure RTL support

### Translations
- [ ] Extract all user-facing text
- [ ] Use ICU message format for plurals
- [ ] Provide context for translators
- [ ] Keep keys descriptive
- [ ] Avoid concatenating strings

### Formatting
- [ ] Use locale-aware date formatting
- [ ] Format numbers and currencies correctly
- [ ] Handle pluralization properly
- [ ] Support RTL languages
- [ ] Use logical CSS properties

### SEO
- [ ] Add hreflang tags
- [ ] Create locale-specific sitemaps
- [ ] Translate meta tags
- [ ] Use proper URL structure
- [ ] Implement canonical URLs

### Performance
- [ ] Load only needed translations
- [ ] Use code splitting for locales
- [ ] Cache translations
- [ ] Lazy load translation files
- [ ] Minimize bundle size

## Common Pitfalls

### ❌ Don't concatenate strings
```typescript
// Bad
const message = t('hello') + ' ' + name + '!'

// Good
const message = t('hello', { name })
```

### ❌ Don't hardcode formats
```typescript
// Bad
const date = `${day}/${month}/${year}`

// Good
const date = format.dateTime(new Date(), { dateStyle: 'short' })
```

### ❌ Don't assume text direction
```typescript
// Bad
<div className="text-left ml-4">

// Good
<div className="text-start ms-4">
```

## Resources

- [next-intl Documentation](https://next-intl-docs.vercel.app/)
- [ICU Message Format](https://unicode-org.github.io/icu/userguide/format_parse/messages/)
- [CLDR - Unicode Locale Data](https://cldr.unicode.org/)
- [RTL Styling Guide](https://rtlstyling.com/)
- [i18n Best Practices](https://www.w3.org/International/questions/qa-i18n)

---

**Remember**: Plan i18n from the start. Use proper formatting. Support RTL. Test with real translations. Consider cultural differences.
