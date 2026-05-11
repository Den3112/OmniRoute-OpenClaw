---
name: authentication-authorization
description: Use this skill for implementing authentication and authorization including NextAuth.js, JWT, session management, OAuth 2.0, social logins, RBAC, MFA, password security, and auth best practices (2026).
origin: Custom
---

# Authentication & Authorization Skill

Comprehensive guide for implementing authentication and authorization (Updated May 2026).

## When to Activate

- Implementing user authentication
- Setting up OAuth/social logins
- Managing sessions and tokens
- Implementing role-based access control (RBAC)
- Adding multi-factor authentication (MFA)
- Password hashing and security
- Protecting API routes
- Handling auth state
- Implementing permissions

## Authentication vs Authorization

**Authentication** - Who are you?
- Login/signup
- Verifying identity
- Session management

**Authorization** - What can you do?
- Permissions
- Role-based access
- Resource ownership

## NextAuth.js (Auth.js) - Recommended for 2026

### Why NextAuth.js?
- Built for Next.js
- Multiple providers (OAuth, Email, Credentials)
- Session management
- JWT support
- Database adapters
- TypeScript support

### Setup

```bash
npm install next-auth@beta
```

```typescript
// auth.ts
import NextAuth from 'next-auth'
import GitHub from 'next-auth/providers/github'
import Google from 'next-auth/providers/google'
import Credentials from 'next-auth/providers/credentials'
import { PrismaAdapter } from '@auth/prisma-adapter'
import { prisma } from './lib/prisma'
import bcrypt from 'bcryptjs'

export const { handlers, auth, signIn, signOut } = NextAuth({
  adapter: PrismaAdapter(prisma),
  session: { strategy: 'jwt' },
  pages: {
    signIn: '/login',
    error: '/auth/error'
  },
  providers: [
    GitHub({
      clientId: process.env.GITHUB_ID!,
      clientSecret: process.env.GITHUB_SECRET!
    }),
    Google({
      clientId: process.env.GOOGLE_ID!,
      clientSecret: process.env.GOOGLE_SECRET!
    }),
    Credentials({
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          return null
        }

        const user = await prisma.user.findUnique({
          where: { email: credentials.email as string }
        })

        if (!user || !user.password) {
          return null
        }

        const isValid = await bcrypt.compare(
          credentials.password as string,
          user.password
        )

        if (!isValid) {
          return null
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
        token.role = user.role
      }
      return token
    },
    async session({ session, token }) {
      if (session.user) {
        session.user.id = token.id as string
        session.user.role = token.role as string
      }
      return session
    }
  }
})
```

### API Route Handler

```typescript
// app/api/auth/[...nextauth]/route.ts
import { handlers } from '@/auth'

export const { GET, POST } = handlers
```

### Middleware Protection

```typescript
// middleware.ts
import { auth } from '@/auth'
import { NextResponse } from 'next/server'

export default auth((req) => {
  const isLoggedIn = !!req.auth
  const isAuthPage = req.nextUrl.pathname.startsWith('/login')
  const isProtectedPage = req.nextUrl.pathname.startsWith('/dashboard')

  if (isProtectedPage && !isLoggedIn) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  if (isAuthPage && isLoggedIn) {
    return NextResponse.redirect(new URL('/dashboard', req.url))
  }

  return NextResponse.next()
})

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)']
}
```

### Client Components

```typescript
// components/LoginButton.tsx
'use client'

import { signIn, signOut } from 'next-auth/react'

export function LoginButton() {
  return (
    <button onClick={() => signIn()}>
      Sign In
    </button>
  )
}

export function LogoutButton() {
  return (
    <button onClick={() => signOut()}>
      Sign Out
    </button>
  )
}

export function GitHubLoginButton() {
  return (
    <button onClick={() => signIn('github')}>
      Sign in with GitHub
    </button>
  )
}
```

### Server Components

```typescript
// app/dashboard/page.tsx
import { auth } from '@/auth'
import { redirect } from 'next/navigation'

export default async function DashboardPage() {
  const session = await auth()

  if (!session) {
    redirect('/login')
  }

  return (
    <div>
      <h1>Welcome, {session.user?.name}</h1>
      <p>Email: {session.user?.email}</p>
    </div>
  )
}
```

### Protected API Routes

```typescript
// app/api/protected/route.ts
import { auth } from '@/auth'
import { NextResponse } from 'next/server'

export async function GET() {
  const session = await auth()

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  return NextResponse.json({
    message: 'Protected data',
    user: session.user
  })
}
```

## JWT Authentication (Manual Implementation)

### Generate JWT

```typescript
import jwt from 'jsonwebtoken'

const JWT_SECRET = process.env.JWT_SECRET!

interface TokenPayload {
  userId: string
  email: string
  role: string
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, {
    expiresIn: '7d'
  })
}

export function verifyToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as TokenPayload
  } catch (error) {
    return null
  }
}

export function generateRefreshToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, {
    expiresIn: '30d'
  })
}
```

### Login Endpoint

```typescript
// app/api/auth/login/route.ts
import { NextRequest, NextResponse } from 'next/server'
import bcrypt from 'bcryptjs'
import { generateToken, generateRefreshToken } from '@/lib/jwt'

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json()

    // Find user
    const user = await prisma.user.findUnique({
      where: { email }
    })

    if (!user || !user.password) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      )
    }

    // Verify password
    const isValid = await bcrypt.compare(password, user.password)

    if (!isValid) {
      return NextResponse.json(
        { error: 'Invalid credentials' },
        { status: 401 }
      )
    }

    // Generate tokens
    const accessToken = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role
    })

    const refreshToken = generateRefreshToken(user.id)

    // Store refresh token in database
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        userId: user.id,
        expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      }
    })

    // Set httpOnly cookie
    const response = NextResponse.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role
      },
      accessToken
    })

    response.cookies.set('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 30 * 24 * 60 * 60 // 30 days
    })

    return response
  } catch (error) {
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
```

### Auth Middleware

```typescript
// lib/auth-middleware.ts
import { NextRequest, NextResponse } from 'next/server'
import { verifyToken } from './jwt'

export async function authMiddleware(request: NextRequest) {
  const token = request.headers.get('authorization')?.replace('Bearer ', '')

  if (!token) {
    return NextResponse.json(
      { error: 'No token provided' },
      { status: 401 }
    )
  }

  const payload = verifyToken(token)

  if (!payload) {
    return NextResponse.json(
      { error: 'Invalid token' },
      { status: 401 }
    )
  }

  // Add user to request
  return { user: payload }
}
```

## Password Security

### Hashing Passwords

```typescript
import bcrypt from 'bcryptjs'

// Hash password
export async function hashPassword(password: string): Promise<string> {
  const salt = await bcrypt.genSalt(12)
  return bcrypt.hash(password, salt)
}

// Verify password
export async function verifyPassword(
  password: string,
  hashedPassword: string
): Promise<boolean> {
  return bcrypt.compare(password, hashedPassword)
}
```

### Password Validation

```typescript
import { z } from 'zod'

export const passwordSchema = z
  .string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
  .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
  .regex(/[0-9]/, 'Password must contain at least one number')
  .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character')

// Usage
try {
  passwordSchema.parse('MyP@ssw0rd')
} catch (error) {
  console.error(error.errors)
}
```

### Password Reset Flow

```typescript
// Generate reset token
import crypto from 'crypto'

export function generateResetToken(): string {
  return crypto.randomBytes(32).toString('hex')
}

// Request password reset
export async function requestPasswordReset(email: string) {
  const user = await prisma.user.findUnique({ where: { email } })

  if (!user) {
    // Don't reveal if user exists
    return { success: true }
  }

  const resetToken = generateResetToken()
  const expiresAt = new Date(Date.now() + 60 * 60 * 1000) // 1 hour

  await prisma.passwordReset.create({
    data: {
      token: resetToken,
      userId: user.id,
      expiresAt
    }
  })

  // Send email with reset link
  await sendPasswordResetEmail(email, resetToken)

  return { success: true }
}

// Reset password
export async function resetPassword(token: string, newPassword: string) {
  const resetRecord = await prisma.passwordReset.findUnique({
    where: { token },
    include: { user: true }
  })

  if (!resetRecord || resetRecord.expiresAt < new Date()) {
    throw new Error('Invalid or expired token')
  }

  const hashedPassword = await hashPassword(newPassword)

  await prisma.user.update({
    where: { id: resetRecord.userId },
    data: { password: hashedPassword }
  })

  // Delete used token
  await prisma.passwordReset.delete({
    where: { token }
  })

  return { success: true }
}
```

## Role-Based Access Control (RBAC)

### Define Roles and Permissions

```typescript
// lib/rbac.ts
export enum Role {
  USER = 'USER',
  MODERATOR = 'MODERATOR',
  ADMIN = 'ADMIN'
}

export enum Permission {
  READ_POSTS = 'READ_POSTS',
  CREATE_POSTS = 'CREATE_POSTS',
  UPDATE_POSTS = 'UPDATE_POSTS',
  DELETE_POSTS = 'DELETE_POSTS',
  MANAGE_USERS = 'MANAGE_USERS',
  MANAGE_SETTINGS = 'MANAGE_SETTINGS'
}

const rolePermissions: Record<Role, Permission[]> = {
  [Role.USER]: [
    Permission.READ_POSTS,
    Permission.CREATE_POSTS
  ],
  [Role.MODERATOR]: [
    Permission.READ_POSTS,
    Permission.CREATE_POSTS,
    Permission.UPDATE_POSTS,
    Permission.DELETE_POSTS
  ],
  [Role.ADMIN]: [
    Permission.READ_POSTS,
    Permission.CREATE_POSTS,
    Permission.UPDATE_POSTS,
    Permission.DELETE_POSTS,
    Permission.MANAGE_USERS,
    Permission.MANAGE_SETTINGS
  ]
}

export function hasPermission(role: Role, permission: Permission): boolean {
  return rolePermissions[role]?.includes(permission) || false
}

export function requirePermission(role: Role, permission: Permission) {
  if (!hasPermission(role, permission)) {
    throw new Error('Insufficient permissions')
  }
}
```

### Authorization Middleware

```typescript
// lib/authorization.ts
import { auth } from '@/auth'
import { NextResponse } from 'next/server'
import { Role, Permission, hasPermission } from './rbac'

export async function requireAuth() {
  const session = await auth()

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    )
  }

  return session
}

export async function requireRole(allowedRoles: Role[]) {
  const session = await requireAuth()

  if (session instanceof NextResponse) {
    return session
  }

  if (!allowedRoles.includes(session.user.role as Role)) {
    return NextResponse.json(
      { error: 'Forbidden' },
      { status: 403 }
    )
  }

  return session
}

export async function requirePermission(permission: Permission) {
  const session = await requireAuth()

  if (session instanceof NextResponse) {
    return session
  }

  if (!hasPermission(session.user.role as Role, permission)) {
    return NextResponse.json(
      { error: 'Forbidden' },
      { status: 403 }
    )
  }

  return session
}
```

### Protected Routes with RBAC

```typescript
// app/api/admin/users/route.ts
import { requireRole } from '@/lib/authorization'
import { Role } from '@/lib/rbac'

export async function GET() {
  const session = await requireRole([Role.ADMIN])

  if (session instanceof NextResponse) {
    return session
  }

  const users = await prisma.user.findMany()

  return NextResponse.json({ users })
}
```

### Client-Side Authorization

```typescript
'use client'

import { useSession } from 'next-auth/react'
import { Role, hasPermission, Permission } from '@/lib/rbac'

export function AdminPanel() {
  const { data: session } = useSession()

  if (!session) {
    return <div>Please login</div>
  }

  const userRole = session.user.role as Role

  return (
    <div>
      <h1>Admin Panel</h1>

      {hasPermission(userRole, Permission.MANAGE_USERS) && (
        <button>Manage Users</button>
      )}

      {hasPermission(userRole, Permission.MANAGE_SETTINGS) && (
        <button>Manage Settings</button>
      )}
    </div>
  )
}
```

## Multi-Factor Authentication (MFA)

### TOTP (Time-based One-Time Password)

```typescript
import speakeasy from 'speakeasy'
import QRCode from 'qrcode'

// Generate MFA secret
export async function generateMFASecret(userId: string, email: string) {
  const secret = speakeasy.generateSecret({
    name: `MyApp (${email})`,
    length: 32
  })

  // Store secret in database
  await prisma.user.update({
    where: { id: userId },
    data: { mfaSecret: secret.base32 }
  })

  // Generate QR code
  const qrCodeUrl = await QRCode.toDataURL(secret.otpauth_url!)

  return {
    secret: secret.base32,
    qrCode: qrCodeUrl
  }
}

// Verify TOTP token
export function verifyMFAToken(secret: string, token: string): boolean {
  return speakeasy.totp.verify({
    secret,
    encoding: 'base32',
    token,
    window: 2 // Allow 2 time steps before/after
  })
}

// Enable MFA
export async function enableMFA(userId: string, token: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId }
  })

  if (!user?.mfaSecret) {
    throw new Error('MFA not set up')
  }

  const isValid = verifyMFAToken(user.mfaSecret, token)

  if (!isValid) {
    throw new Error('Invalid token')
  }

  await prisma.user.update({
    where: { id: userId },
    data: { mfaEnabled: true }
  })

  return { success: true }
}
```

### MFA Login Flow

```typescript
// app/api/auth/login-mfa/route.ts
export async function POST(request: NextRequest) {
  const { email, password, mfaToken } = await request.json()

  // Verify credentials
  const user = await prisma.user.findUnique({ where: { email } })

  if (!user || !user.password) {
    return NextResponse.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    )
  }

  const isValidPassword = await bcrypt.compare(password, user.password)

  if (!isValidPassword) {
    return NextResponse.json(
      { error: 'Invalid credentials' },
      { status: 401 }
    )
  }

  // Check if MFA is enabled
  if (user.mfaEnabled && user.mfaSecret) {
    if (!mfaToken) {
      return NextResponse.json(
        { requiresMFA: true },
        { status: 200 }
      )
    }

    const isValidMFA = verifyMFAToken(user.mfaSecret, mfaToken)

    if (!isValidMFA) {
      return NextResponse.json(
        { error: 'Invalid MFA token' },
        { status: 401 }
      )
    }
  }

  // Generate tokens and login
  const accessToken = generateToken({
    userId: user.id,
    email: user.email,
    role: user.role
  })

  return NextResponse.json({
    user: {
      id: user.id,
      email: user.email,
      name: user.name
    },
    accessToken
  })
}
```

## Social Login (OAuth)

### GitHub OAuth

```typescript
// Already configured in NextAuth setup above
// Just add the button:

<button onClick={() => signIn('github')}>
  Sign in with GitHub
</button>
```

### Google OAuth

```typescript
<button onClick={() => signIn('google')}>
  Sign in with Google
</button>
```

### Custom OAuth Provider

```typescript
import { OAuthConfig } from 'next-auth/providers'

interface CustomProfile {
  id: string
  email: string
  name: string
}

export default function CustomProvider(): OAuthConfig<CustomProfile> {
  return {
    id: 'custom',
    name: 'Custom Provider',
    type: 'oauth',
    authorization: {
      url: 'https://provider.com/oauth/authorize',
      params: { scope: 'email profile' }
    },
    token: 'https://provider.com/oauth/token',
    userinfo: 'https://provider.com/oauth/userinfo',
    profile(profile) {
      return {
        id: profile.id,
        email: profile.email,
        name: profile.name
      }
    }
  }
}
```

## Session Management

### Server-Side Session Check

```typescript
import { auth } from '@/auth'

export async function getServerSession() {
  return await auth()
}
```

### Client-Side Session

```typescript
'use client'

import { useSession } from 'next-auth/react'

export function UserProfile() {
  const { data: session, status } = useSession()

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  if (status === 'unauthenticated') {
    return <div>Not logged in</div>
  }

  return (
    <div>
      <p>Welcome, {session?.user?.name}</p>
      <p>Email: {session?.user?.email}</p>
    </div>
  )
}
```

## Best Practices Checklist

### Security
- [ ] Never store passwords in plain text
- [ ] Use bcrypt with salt rounds ≥ 12
- [ ] Implement rate limiting on auth endpoints
- [ ] Use httpOnly cookies for refresh tokens
- [ ] Enable HTTPS in production
- [ ] Implement CSRF protection
- [ ] Validate and sanitize all inputs
- [ ] Use secure session storage

### Tokens
- [ ] Short-lived access tokens (15 min)
- [ ] Long-lived refresh tokens (30 days)
- [ ] Store refresh tokens securely
- [ ] Implement token rotation
- [ ] Revoke tokens on logout

### Passwords
- [ ] Minimum 8 characters
- [ ] Require uppercase, lowercase, number, special char
- [ ] Implement password reset flow
- [ ] Prevent password reuse
- [ ] Show password strength indicator

### Authorization
- [ ] Implement RBAC or ABAC
- [ ] Check permissions on server-side
- [ ] Never trust client-side checks
- [ ] Log authorization failures
- [ ] Implement principle of least privilege

### MFA
- [ ] Offer MFA as optional
- [ ] Support TOTP (Google Authenticator)
- [ ] Provide backup codes
- [ ] Allow MFA recovery

## Resources

- [NextAuth.js Documentation](https://next-auth.js.org/)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
- [OAuth 2.0 Specification](https://oauth.net/2/)

---

**Remember**: Security is critical. Hash passwords. Use HTTPS. Implement MFA. Check permissions server-side. Never trust the client.
