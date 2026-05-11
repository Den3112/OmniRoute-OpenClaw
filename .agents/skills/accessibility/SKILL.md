---
name: accessibility
description: Use this skill for implementing web accessibility (a11y) including WCAG 2.2 compliance, ARIA attributes, keyboard navigation, screen reader support, semantic HTML, color contrast, focus management, and accessibility testing (2026).
origin: Custom
---

# Accessibility (a11y) Skill

Comprehensive guide for building accessible web applications (Updated May 2026).

## When to Activate

- Implementing accessible components
- WCAG compliance
- Keyboard navigation
- Screen reader support
- ARIA attributes
- Focus management
- Color contrast
- Accessible forms
- Testing accessibility

## WCAG 2.2 Principles (POUR)

### Perceivable
Users must be able to perceive the information being presented.

### Operable
Users must be able to operate the interface.

### Understandable
Users must be able to understand the information and operation.

### Robust
Content must be robust enough to work with assistive technologies.

## Semantic HTML

### Use Proper HTML Elements

```typescript
// ❌ Bad: Non-semantic
<div onClick={handleClick}>Click me</div>
<div className="heading">Title</div>
<div className="list">
  <div>Item 1</div>
  <div>Item 2</div>
</div>

// ✅ Good: Semantic
<button onClick={handleClick}>Click me</button>
<h1>Title</h1>
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>
```

### Document Structure

```typescript
export default function Page() {
  return (
    <>
      <header>
        <nav aria-label="Main navigation">
          <ul>
            <li><a href="/">Home</a></li>
            <li><a href="/about">About</a></li>
          </ul>
        </nav>
      </header>

      <main>
        <article>
          <h1>Page Title</h1>
          <section>
            <h2>Section Title</h2>
            <p>Content...</p>
          </section>
        </article>

        <aside aria-label="Related content">
          <h2>Related Articles</h2>
        </aside>
      </main>

      <footer>
        <p>&copy; 2026 Company Name</p>
      </footer>
    </>
  )
}
```

## ARIA Attributes

### ARIA Roles

```typescript
// Landmark roles (use semantic HTML when possible)
<div role="navigation">...</div>  // Use <nav> instead
<div role="main">...</div>        // Use <main> instead
<div role="banner">...</div>      // Use <header> instead
<div role="contentinfo">...</div> // Use <footer> instead

// Widget roles
<div role="button" tabIndex={0}>Click me</div>
<div role="dialog" aria-modal="true">Modal content</div>
<div role="alert">Important message</div>
<div role="status">Loading...</div>
```

### ARIA States and Properties

```typescript
// aria-label: Provides accessible name
<button aria-label="Close dialog">×</button>

// aria-labelledby: References element for label
<div id="dialog-title">Confirm Action</div>
<div role="dialog" aria-labelledby="dialog-title">...</div>

// aria-describedby: Additional description
<input
  type="email"
  aria-describedby="email-hint"
/>
<span id="email-hint">We'll never share your email</span>

// aria-expanded: Collapsible state
<button aria-expanded={isOpen} aria-controls="menu">
  Menu
</button>
<div id="menu" hidden={!isOpen}>...</div>

// aria-hidden: Hide from screen readers
<span aria-hidden="true">🎉</span>

// aria-live: Announce dynamic content
<div aria-live="polite" aria-atomic="true">
  {statusMessage}
</div>

// aria-current: Current item in navigation
<a href="/about" aria-current="page">About</a>
```

## Keyboard Navigation

### Focus Management

```typescript
'use client'

import { useRef, useEffect } from 'react'

export function Modal({ isOpen, onClose, children }: {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
}) {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      // Save current focus
      previousFocusRef.current = document.activeElement as HTMLElement
      
      // Focus modal
      modalRef.current?.focus()

      // Trap focus inside modal
      const handleKeyDown = (e: KeyboardEvent) => {
        if (e.key === 'Escape') {
          onClose()
        }

        if (e.key === 'Tab') {
          const focusableElements = modalRef.current?.querySelectorAll(
            'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
          )
          
          if (!focusableElements?.length) return

          const firstElement = focusableElements[0] as HTMLElement
          const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement

          if (e.shiftKey && document.activeElement === firstElement) {
            e.preventDefault()
            lastElement.focus()
          } else if (!e.shiftKey && document.activeElement === lastElement) {
            e.preventDefault()
            firstElement.focus()
          }
        }
      }

      document.addEventListener('keydown', handleKeyDown)

      return () => {
        document.removeEventListener('keydown', handleKeyDown)
        // Restore focus
        previousFocusRef.current?.focus()
      }
    }
  }, [isOpen, onClose])

  if (!isOpen) return null

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center"
      onClick={onClose}
    >
      <div
        ref={modalRef}
        role="dialog"
        aria-modal="true"
        tabIndex={-1}
        className="bg-white p-6 rounded-lg"
        onClick={(e) => e.stopPropagation()}
      >
        {children}
        <button onClick={onClose}>Close</button>
      </div>
    </div>
  )
}
```

### Keyboard Shortcuts

```typescript
'use client'

import { useEffect } from 'react'

export function useKeyboardShortcut(
  key: string,
  callback: () => void,
  modifiers?: { ctrl?: boolean; shift?: boolean; alt?: boolean }
) {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      const matchesModifiers =
        (!modifiers?.ctrl || e.ctrlKey) &&
        (!modifiers?.shift || e.shiftKey) &&
        (!modifiers?.alt || e.altKey)

      if (e.key === key && matchesModifiers) {
        e.preventDefault()
        callback()
      }
    }

    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [key, callback, modifiers])
}

// Usage
export function SearchComponent() {
  const [isOpen, setIsOpen] = useState(false)

  useKeyboardShortcut('k', () => setIsOpen(true), { ctrl: true })

  return (
    <div>
      <p>Press Ctrl+K to search</p>
      {isOpen && <SearchModal onClose={() => setIsOpen(false)} />}
    </div>
  )
}
```

### Skip Links

```typescript
// components/SkipLink.tsx
export function SkipLink() {
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 focus:z-50 focus:px-4 focus:py-2 focus:bg-blue-600 focus:text-white"
    >
      Skip to main content
    </a>
  )
}

// Layout
export default function Layout({ children }: { children: React.ReactNode }) {
  return (
    <body>
      <SkipLink />
      <nav>...</nav>
      <main id="main-content" tabIndex={-1}>
        {children}
      </main>
    </body>
  )
}
```

## Accessible Forms

### Form Labels

```typescript
// ✅ Good: Explicit label
<label htmlFor="email">Email</label>
<input id="email" type="email" name="email" required />

// ✅ Good: Implicit label
<label>
  Email
  <input type="email" name="email" required />
</label>

// ✅ Good: aria-label when visual label not needed
<input
  type="search"
  aria-label="Search"
  placeholder="Search..."
/>
```

### Error Messages

```typescript
'use client'

import { useState } from 'react'

export function AccessibleForm() {
  const [email, setEmail] = useState('')
  const [error, setError] = useState('')

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!email.includes('@')) {
      setError('Please enter a valid email address')
      return
    }
    
    setError('')
    // Submit form
  }

  return (
    <form onSubmit={handleSubmit}>
      <label htmlFor="email">Email</label>
      <input
        id="email"
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        aria-invalid={!!error}
        aria-describedby={error ? 'email-error' : undefined}
        required
      />
      {error && (
        <div
          id="email-error"
          role="alert"
          className="text-red-600"
        >
          {error}
        </div>
      )}
      <button type="submit">Submit</button>
    </form>
  )
}
```

### Required Fields

```typescript
<label htmlFor="name">
  Name <span aria-label="required">*</span>
</label>
<input
  id="name"
  type="text"
  required
  aria-required="true"
/>
```

## Color Contrast

### WCAG 2.2 Requirements

- **Normal text**: 4.5:1 contrast ratio (AA)
- **Large text** (18pt+): 3:1 contrast ratio (AA)
- **AAA level**: 7:1 for normal, 4.5:1 for large

### Checking Contrast

```typescript
// Use tools like:
// - Chrome DevTools (Lighthouse)
// - WebAIM Contrast Checker
// - axe DevTools

// Good contrast examples
const colors = {
  // ✅ Good: 7.5:1 ratio
  text: '#1a1a1a',
  background: '#ffffff',
  
  // ✅ Good: 4.6:1 ratio
  primary: '#0066cc',
  primaryText: '#ffffff',
  
  // ❌ Bad: 2.3:1 ratio (fails WCAG)
  lightGray: '#cccccc',
  white: '#ffffff'
}
```

### Don't Rely on Color Alone

```typescript
// ❌ Bad: Color only
<span className="text-red-600">Error</span>
<span className="text-green-600">Success</span>

// ✅ Good: Color + icon + text
<span className="text-red-600">
  <span aria-hidden="true">❌</span>
  <span className="sr-only">Error:</span>
  Invalid input
</span>

<span className="text-green-600">
  <span aria-hidden="true">✓</span>
  <span className="sr-only">Success:</span>
  Saved successfully
</span>
```

## Screen Reader Support

### Visually Hidden Content

```css
/* globals.css */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}

.sr-only-focusable:focus {
  position: static;
  width: auto;
  height: auto;
  padding: inherit;
  margin: inherit;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

### Live Regions

```typescript
'use client'

import { useState } from 'react'

export function LiveRegionExample() {
  const [message, setMessage] = useState('')

  const announce = (text: string) => {
    setMessage(text)
    // Clear after announcement
    setTimeout(() => setMessage(''), 1000)
  }

  return (
    <div>
      <button onClick={() => announce('Item added to cart')}>
        Add to Cart
      </button>

      {/* Polite: Wait for user to finish current task */}
      <div
        role="status"
        aria-live="polite"
        aria-atomic="true"
        className="sr-only"
      >
        {message}
      </div>

      {/* Assertive: Interrupt immediately (use sparingly) */}
      <div
        role="alert"
        aria-live="assertive"
        aria-atomic="true"
        className="sr-only"
      >
        {/* Critical messages only */}
      </div>
    </div>
  )
}
```

## Accessible Components

### Button

```typescript
interface ButtonProps {
  children: React.ReactNode
  onClick?: () => void
  disabled?: boolean
  loading?: boolean
  type?: 'button' | 'submit' | 'reset'
}

export function Button({
  children,
  onClick,
  disabled,
  loading,
  type = 'button'
}: ButtonProps) {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || loading}
      aria-disabled={disabled || loading}
      aria-busy={loading}
      className="px-4 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
    >
      {loading ? (
        <>
          <span className="sr-only">Loading...</span>
          <span aria-hidden="true">⏳</span>
        </>
      ) : (
        children
      )}
    </button>
  )
}
```

### Dropdown Menu

```typescript
'use client'

import { useState, useRef, useEffect } from 'react'

export function DropdownMenu() {
  const [isOpen, setIsOpen] = useState(false)
  const buttonRef = useRef<HTMLButtonElement>(null)
  const menuRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (isOpen) {
      menuRef.current?.querySelector<HTMLElement>('[role="menuitem"]')?.focus()
    }
  }, [isOpen])

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Escape') {
      setIsOpen(false)
      buttonRef.current?.focus()
    } else if (e.key === 'ArrowDown') {
      e.preventDefault()
      const items = menuRef.current?.querySelectorAll('[role="menuitem"]')
      const currentIndex = Array.from(items || []).indexOf(document.activeElement as Element)
      const nextItem = items?.[currentIndex + 1] as HTMLElement
      nextItem?.focus()
    } else if (e.key === 'ArrowUp') {
      e.preventDefault()
      const items = menuRef.current?.querySelectorAll('[role="menuitem"]')
      const currentIndex = Array.from(items || []).indexOf(document.activeElement as Element)
      const prevItem = items?.[currentIndex - 1] as HTMLElement
      prevItem?.focus()
    }
  }

  return (
    <div className="relative">
      <button
        ref={buttonRef}
        onClick={() => setIsOpen(!isOpen)}
        aria-expanded={isOpen}
        aria-haspopup="true"
        aria-controls="menu"
      >
        Menu
      </button>

      {isOpen && (
        <div
          ref={menuRef}
          id="menu"
          role="menu"
          onKeyDown={handleKeyDown}
          className="absolute top-full left-0 mt-2 bg-white border rounded shadow-lg"
        >
          <button
            role="menuitem"
            onClick={() => {
              console.log('Profile')
              setIsOpen(false)
            }}
            className="block w-full text-left px-4 py-2 hover:bg-gray-100"
          >
            Profile
          </button>
          <button
            role="menuitem"
            onClick={() => {
              console.log('Settings')
              setIsOpen(false)
            }}
            className="block w-full text-left px-4 py-2 hover:bg-gray-100"
          >
            Settings
          </button>
          <button
            role="menuitem"
            onClick={() => {
              console.log('Logout')
              setIsOpen(false)
            }}
            className="block w-full text-left px-4 py-2 hover:bg-gray-100"
          >
            Logout
          </button>
        </div>
      )}
    </div>
  )
}
```

### Tabs

```typescript
'use client'

import { useState } from 'react'

interface Tab {
  id: string
  label: string
  content: React.ReactNode
}

export function Tabs({ tabs }: { tabs: Tab[] }) {
  const [activeTab, setActiveTab] = useState(tabs[0].id)

  const handleKeyDown = (e: React.KeyboardEvent, index: number) => {
    if (e.key === 'ArrowRight') {
      e.preventDefault()
      const nextIndex = (index + 1) % tabs.length
      setActiveTab(tabs[nextIndex].id)
    } else if (e.key === 'ArrowLeft') {
      e.preventDefault()
      const prevIndex = (index - 1 + tabs.length) % tabs.length
      setActiveTab(tabs[prevIndex].id)
    } else if (e.key === 'Home') {
      e.preventDefault()
      setActiveTab(tabs[0].id)
    } else if (e.key === 'End') {
      e.preventDefault()
      setActiveTab(tabs[tabs.length - 1].id)
    }
  }

  return (
    <div>
      <div role="tablist" aria-label="Content tabs">
        {tabs.map((tab, index) => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={activeTab === tab.id}
            aria-controls={`panel-${tab.id}`}
            id={`tab-${tab.id}`}
            tabIndex={activeTab === tab.id ? 0 : -1}
            onClick={() => setActiveTab(tab.id)}
            onKeyDown={(e) => handleKeyDown(e, index)}
            className={`px-4 py-2 ${
              activeTab === tab.id ? 'border-b-2 border-blue-600' : ''
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {tabs.map((tab) => (
        <div
          key={tab.id}
          role="tabpanel"
          id={`panel-${tab.id}`}
          aria-labelledby={`tab-${tab.id}`}
          hidden={activeTab !== tab.id}
          tabIndex={0}
          className="p-4"
        >
          {tab.content}
        </div>
      ))}
    </div>
  )
}
```

## Images and Media

### Alt Text

```typescript
// ✅ Good: Descriptive alt text
<img
  src="/product.jpg"
  alt="Blue cotton t-shirt with round neck"
/>

// ✅ Good: Empty alt for decorative images
<img
  src="/decoration.svg"
  alt=""
  aria-hidden="true"
/>

// ✅ Good: Complex images with description
<figure>
  <img
    src="/chart.png"
    alt="Sales chart showing 20% increase"
    aria-describedby="chart-description"
  />
  <figcaption id="chart-description">
    Detailed description of the sales data...
  </figcaption>
</figure>
```

### Video Captions

```typescript
<video controls>
  <source src="/video.mp4" type="video/mp4" />
  <track
    kind="captions"
    src="/captions-en.vtt"
    srclang="en"
    label="English"
    default
  />
  <track
    kind="captions"
    src="/captions-es.vtt"
    srclang="es"
    label="Español"
  />
</video>
```

## Testing Accessibility

### Automated Testing

```bash
# Install tools
npm install -D @axe-core/react eslint-plugin-jsx-a11y
```

```typescript
// vitest.setup.ts
import { configureAxe } from 'jest-axe'

export const axe = configureAxe({
  rules: {
    // Customize rules
  }
})
```

```typescript
// Component.test.tsx
import { render } from '@testing-library/react'
import { axe } from './vitest.setup'
import { Button } from './Button'

test('should not have accessibility violations', async () => {
  const { container } = render(<Button>Click me</Button>)
  const results = await axe(container)
  expect(results).toHaveNoViolations()
})
```

### ESLint Plugin

```javascript
// .eslintrc.js
module.exports = {
  extends: [
    'plugin:jsx-a11y/recommended'
  ],
  plugins: ['jsx-a11y']
}
```

### Manual Testing

```typescript
// Keyboard navigation checklist:
// - Tab through all interactive elements
// - Shift+Tab to go backwards
// - Enter/Space to activate buttons
// - Arrow keys for menus/tabs
// - Escape to close modals/menus

// Screen reader testing:
// - NVDA (Windows, free)
// - JAWS (Windows, paid)
// - VoiceOver (macOS/iOS, built-in)
// - TalkBack (Android, built-in)
```

## Best Practices Checklist

### HTML
- [ ] Use semantic HTML elements
- [ ] Provide proper heading hierarchy (h1-h6)
- [ ] Use landmarks (header, nav, main, aside, footer)
- [ ] Add lang attribute to html element
- [ ] Use lists for list content

### ARIA
- [ ] Use ARIA only when semantic HTML isn't enough
- [ ] Provide accessible names (aria-label, aria-labelledby)
- [ ] Use aria-describedby for additional context
- [ ] Implement proper ARIA states (aria-expanded, aria-selected)
- [ ] Use live regions for dynamic content

### Keyboard
- [ ] All interactive elements are keyboard accessible
- [ ] Visible focus indicators
- [ ] Logical tab order
- [ ] Implement keyboard shortcuts
- [ ] Trap focus in modals

### Visual
- [ ] Sufficient color contrast (4.5:1 minimum)
- [ ] Don't rely on color alone
- [ ] Text is resizable up to 200%
- [ ] No content loss when zoomed
- [ ] Support for reduced motion

### Forms
- [ ] All inputs have labels
- [ ] Error messages are clear and associated
- [ ] Required fields are indicated
- [ ] Form validation is accessible
- [ ] Success messages announced

### Media
- [ ] Images have alt text
- [ ] Decorative images have empty alt
- [ ] Videos have captions
- [ ] Audio has transcripts
- [ ] No auto-playing media

## Resources

- [WCAG 2.2 Guidelines](https://www.w3.org/WAI/WCAG22/quickref/)
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [WebAIM](https://webaim.org/)
- [A11y Project](https://www.a11yproject.com/)
- [ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/)
- [axe DevTools](https://www.deque.com/axe/devtools/)

---

**Remember**: Accessibility is not optional. Test with real users. Use semantic HTML. Provide keyboard access. Check color contrast. Test with screen readers.
