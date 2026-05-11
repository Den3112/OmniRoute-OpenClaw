---
name: database-management
description: Use this skill for working with databases including PostgreSQL, MySQL, MongoDB, Redis, Prisma ORM, TypeORM, migrations, queries, indexing, optimization, and database design patterns.
origin: Custom
---

# Database Management Skill

Comprehensive guide for working with databases in modern applications.

## When to Activate

- Setting up database connections
- Designing database schemas
- Writing queries and migrations
- Optimizing database performance
- Implementing ORMs (Prisma, TypeORM, Mongoose)
- Working with Redis for caching
- Database backup and recovery
- Scaling databases
- Troubleshooting database issues

## Database Selection Guide

### PostgreSQL (Recommended for most projects)
**Use when:**
- Need ACID compliance
- Complex queries and joins
- JSON/JSONB support needed
- Full-text search
- Geospatial data

**Pros:**
- Robust and reliable
- Advanced features
- Great performance
- Strong community

**Cons:**
- More complex than MySQL
- Higher resource usage

### MySQL/MariaDB
**Use when:**
- Simple relational data
- Read-heavy workloads
- Shared hosting environments

**Pros:**
- Easy to use
- Wide hosting support
- Good performance

**Cons:**
- Fewer advanced features
- Less strict than PostgreSQL

### MongoDB
**Use when:**
- Flexible schema needed
- Document-oriented data
- Rapid prototyping
- Horizontal scaling required

**Pros:**
- Schema flexibility
- Easy to scale
- Fast development

**Cons:**
- No ACID transactions (older versions)
- Can lead to data inconsistency
- Larger storage footprint

### Redis
**Use when:**
- Caching needed
- Session storage
- Real-time analytics
- Pub/Sub messaging
- Rate limiting

**Pros:**
- Extremely fast
- Simple data structures
- Built-in pub/sub

**Cons:**
- In-memory only (expensive for large data)
- Limited query capabilities

### SQLite
**Use when:**
- Embedded applications
- Development/testing
- Small applications
- Single-user apps

**Pros:**
- Zero configuration
- Serverless
- Fast for small data

**Cons:**
- Not suitable for concurrent writes
- Limited scalability

## Prisma ORM (Recommended)

### Installation
```bash
npm install prisma @prisma/client
npx prisma init
```

### Schema Definition
```prisma
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id            Int       @id @default(autoincrement())
  email         String    @unique
  username      String    @unique
  password      String
  firstName     String
  lastName      String?
  avatar        String?
  isActive      Boolean   @default(true)
  role          Role      @default(USER)
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  posts         Post[]
  comments      Comment[]
  profile       Profile?
  
  @@index([email])
  @@index([username])
}

model Profile {
  id        Int      @id @default(autoincrement())
  bio       String?
  website   String?
  location  String?
  userId    Int      @unique
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}

model Post {
  id          Int       @id @default(autoincrement())
  title       String
  slug        String    @unique
  content     String
  published   Boolean   @default(false)
  views       Int       @default(0)
  authorId    Int
  author      User      @relation(fields: [authorId], references: [id], onDelete: Cascade)
  categoryId  Int?
  category    Category? @relation(fields: [categoryId], references: [id])
  tags        Tag[]
  comments    Comment[]
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt
  publishedAt DateTime?
  
  @@index([slug])
  @@index([authorId])
  @@index([published])
  @@index([createdAt])
}

model Category {
  id          Int      @id @default(autoincrement())
  name        String   @unique
  slug        String   @unique
  description String?
  posts       Post[]
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  
  @@index([slug])
}

model Tag {
  id        Int      @id @default(autoincrement())
  name      String   @unique
  slug      String   @unique
  posts     Post[]
  createdAt DateTime @default(now())
  
  @@index([slug])
}

model Comment {
  id        Int      @id @default(autoincrement())
  content   String
  postId    Int
  post      Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  authorId  Int
  author    User     @relation(fields: [authorId], references: [id], onDelete: Cascade)
  parentId  Int?
  parent    Comment? @relation("CommentReplies", fields: [parentId], references: [id])
  replies   Comment[] @relation("CommentReplies")
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  
  @@index([postId])
  @@index([authorId])
}

enum Role {
  USER
  ADMIN
  MODERATOR
}
```

### Migrations
```bash
# Create migration
npx prisma migrate dev --name init

# Apply migrations in production
npx prisma migrate deploy

# Reset database (development only)
npx prisma migrate reset

# Generate Prisma Client
npx prisma generate

# Open Prisma Studio (GUI)
npx prisma studio
```

### CRUD Operations
```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

// CREATE
async function createUser(data: {
  email: string
  username: string
  password: string
  firstName: string
}) {
  const user = await prisma.user.create({
    data: {
      ...data,
      profile: {
        create: {
          bio: 'New user'
        }
      }
    },
    include: {
      profile: true
    }
  })
  
  return user
}

// READ
async function getUser(id: number) {
  const user = await prisma.user.findUnique({
    where: { id },
    include: {
      profile: true,
      posts: {
        where: { published: true },
        orderBy: { createdAt: 'desc' },
        take: 10
      }
    }
  })
  
  return user
}

// READ MANY with pagination
async function getUsers(page: number = 1, limit: number = 10) {
  const skip = (page - 1) * limit
  
  const [users, total] = await Promise.all([
    prisma.user.findMany({
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        email: true,
        username: true,
        firstName: true,
        lastName: true,
        createdAt: true,
        _count: {
          select: { posts: true }
        }
      }
    }),
    prisma.user.count()
  ])
  
  return {
    users,
    total,
    page,
    totalPages: Math.ceil(total / limit)
  }
}

// UPDATE
async function updateUser(id: number, data: {
  firstName?: string
  lastName?: string
  avatar?: string
}) {
  const user = await prisma.user.update({
    where: { id },
    data
  })
  
  return user
}

// DELETE
async function deleteUser(id: number) {
  await prisma.user.delete({
    where: { id }
  })
}

// UPSERT (create or update)
async function upsertUser(email: string, data: any) {
  const user = await prisma.user.upsert({
    where: { email },
    update: data,
    create: { email, ...data }
  })
  
  return user
}
```

### Complex Queries
```typescript
// Search with filters
async function searchPosts(query: {
  search?: string
  categoryId?: number
  tags?: string[]
  published?: boolean
  page?: number
  limit?: number
}) {
  const { search, categoryId, tags, published, page = 1, limit = 10 } = query
  const skip = (page - 1) * limit
  
  const where: any = {}
  
  if (search) {
    where.OR = [
      { title: { contains: search, mode: 'insensitive' } },
      { content: { contains: search, mode: 'insensitive' } }
    ]
  }
  
  if (categoryId) {
    where.categoryId = categoryId
  }
  
  if (tags && tags.length > 0) {
    where.tags = {
      some: {
        slug: { in: tags }
      }
    }
  }
  
  if (published !== undefined) {
    where.published = published
  }
  
  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      where,
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        author: {
          select: {
            id: true,
            username: true,
            avatar: true
          }
        },
        category: true,
        tags: true,
        _count: {
          select: { comments: true }
        }
      }
    }),
    prisma.post.count({ where })
  ])
  
  return { posts, total, page, totalPages: Math.ceil(total / limit) }
}

// Aggregations
async function getPostStats() {
  const stats = await prisma.post.aggregate({
    _count: true,
    _avg: { views: true },
    _sum: { views: true },
    _max: { views: true }
  })
  
  return stats
}

// Group by
async function getPostsByCategory() {
  const result = await prisma.post.groupBy({
    by: ['categoryId'],
    _count: true,
    orderBy: {
      _count: {
        categoryId: 'desc'
      }
    }
  })
  
  return result
}

// Raw SQL (when needed)
async function complexQuery() {
  const result = await prisma.$queryRaw`
    SELECT u.username, COUNT(p.id) as post_count
    FROM "User" u
    LEFT JOIN "Post" p ON u.id = p."authorId"
    GROUP BY u.id, u.username
    ORDER BY post_count DESC
    LIMIT 10
  `
  
  return result
}
```

### Transactions
```typescript
// Sequential operations in transaction
async function createPostWithTags(data: {
  title: string
  content: string
  authorId: number
  tagNames: string[]
}) {
  const post = await prisma.$transaction(async (tx) => {
    // Create post
    const newPost = await tx.post.create({
      data: {
        title: data.title,
        content: data.content,
        slug: slugify(data.title),
        authorId: data.authorId
      }
    })
    
    // Create or connect tags
    for (const tagName of data.tagNames) {
      const tag = await tx.tag.upsert({
        where: { name: tagName },
        update: {},
        create: {
          name: tagName,
          slug: slugify(tagName)
        }
      })
      
      await tx.post.update({
        where: { id: newPost.id },
        data: {
          tags: {
            connect: { id: tag.id }
          }
        }
      })
    }
    
    return newPost
  })
  
  return post
}

// Transfer with rollback on error
async function transferPoints(fromUserId: number, toUserId: number, amount: number) {
  try {
    await prisma.$transaction(async (tx) => {
      // Deduct from sender
      const sender = await tx.user.update({
        where: { id: fromUserId },
        data: {
          points: { decrement: amount }
        }
      })
      
      // Check if sender has enough points
      if (sender.points < 0) {
        throw new Error('Insufficient points')
      }
      
      // Add to receiver
      await tx.user.update({
        where: { id: toUserId },
        data: {
          points: { increment: amount }
        }
      })
    })
  } catch (error) {
    console.error('Transfer failed:', error)
    throw error
  }
}
```

## PostgreSQL Direct Queries

### Connection Setup
```typescript
import { Pool } from 'pg'

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
})

// Query helper
async function query(text: string, params?: any[]) {
  const start = Date.now()
  const result = await pool.query(text, params)
  const duration = Date.now() - start
  
  console.log('Executed query', { text, duration, rows: result.rowCount })
  return result
}
```

### Common Queries
```typescript
// SELECT with parameters
async function getUserByEmail(email: string) {
  const result = await query(
    'SELECT * FROM users WHERE email = $1',
    [email]
  )
  return result.rows[0]
}

// INSERT
async function createUser(data: {
  email: string
  username: string
  password: string
}) {
  const result = await query(
    `INSERT INTO users (email, username, password, created_at)
     VALUES ($1, $2, $3, NOW())
     RETURNING *`,
    [data.email, data.username, data.password]
  )
  return result.rows[0]
}

// UPDATE
async function updateUser(id: number, data: { firstName?: string; lastName?: string }) {
  const fields = []
  const values = []
  let paramIndex = 1
  
  if (data.firstName) {
    fields.push(`first_name = $${paramIndex++}`)
    values.push(data.firstName)
  }
  
  if (data.lastName) {
    fields.push(`last_name = $${paramIndex++}`)
    values.push(data.lastName)
  }
  
  values.push(id)
  
  const result = await query(
    `UPDATE users SET ${fields.join(', ')}, updated_at = NOW()
     WHERE id = $${paramIndex}
     RETURNING *`,
    values
  )
  
  return result.rows[0]
}

// DELETE
async function deleteUser(id: number) {
  await query('DELETE FROM users WHERE id = $1', [id])
}

// JOIN
async function getPostsWithAuthors() {
  const result = await query(`
    SELECT 
      p.id, p.title, p.content, p.created_at,
      u.id as author_id, u.username, u.avatar
    FROM posts p
    INNER JOIN users u ON p.author_id = u.id
    WHERE p.published = true
    ORDER BY p.created_at DESC
    LIMIT 10
  `)
  
  return result.rows
}

// Aggregation
async function getUserStats(userId: number) {
  const result = await query(`
    SELECT 
      COUNT(DISTINCT p.id) as post_count,
      COUNT(DISTINCT c.id) as comment_count,
      SUM(p.views) as total_views
    FROM users u
    LEFT JOIN posts p ON u.id = p.author_id
    LEFT JOIN comments c ON u.id = c.author_id
    WHERE u.id = $1
    GROUP BY u.id
  `, [userId])
  
  return result.rows[0]
}
```

### Full-Text Search
```typescript
// Create full-text search index
await query(`
  CREATE INDEX posts_search_idx ON posts 
  USING GIN (to_tsvector('english', title || ' ' || content))
`)

// Search
async function searchPosts(searchQuery: string) {
  const result = await query(`
    SELECT 
      id, title, content,
      ts_rank(to_tsvector('english', title || ' ' || content), query) as rank
    FROM posts, to_tsquery('english', $1) query
    WHERE to_tsvector('english', title || ' ' || content) @@ query
    ORDER BY rank DESC
    LIMIT 20
  `, [searchQuery.split(' ').join(' & ')])
  
  return result.rows
}
```

## MongoDB with Mongoose

### Schema Definition
```typescript
import mongoose, { Schema, Document } from 'mongoose'

interface IUser extends Document {
  email: string
  username: string
  password: string
  firstName: string
  lastName?: string
  avatar?: string
  isActive: boolean
  role: 'user' | 'admin' | 'moderator'
  createdAt: Date
  updatedAt: Date
}

const UserSchema = new Schema<IUser>({
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true
  },
  password: {
    type: String,
    required: true
  },
  firstName: {
    type: String,
    required: true
  },
  lastName: String,
  avatar: String,
  isActive: {
    type: Boolean,
    default: true
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'moderator'],
    default: 'user'
  }
}, {
  timestamps: true
})

// Indexes
UserSchema.index({ email: 1 })
UserSchema.index({ username: 1 })

// Virtual fields
UserSchema.virtual('fullName').get(function() {
  return `${this.firstName} ${this.lastName || ''}`
})

// Methods
UserSchema.methods.toJSON = function() {
  const obj = this.toObject()
  delete obj.password
  return obj
}

export const User = mongoose.model<IUser>('User', UserSchema)
```

### CRUD Operations
```typescript
// CREATE
const user = await User.create({
  email: 'user@example.com',
  username: 'johndoe',
  password: hashedPassword,
  firstName: 'John',
  lastName: 'Doe'
})

// READ
const user = await User.findById(userId)
const user = await User.findOne({ email: 'user@example.com' })

// READ MANY
const users = await User.find({ isActive: true })
  .select('username email firstName')
  .limit(10)
  .skip(0)
  .sort({ createdAt: -1 })

// UPDATE
await User.findByIdAndUpdate(
  userId,
  { firstName: 'Jane' },
  { new: true } // Return updated document
)

// DELETE
await User.findByIdAndDelete(userId)

// COUNT
const count = await User.countDocuments({ isActive: true })
```

## Redis for Caching

### Setup
```typescript
import { createClient } from 'redis'

const redis = createClient({
  url: process.env.REDIS_URL
})

redis.on('error', (err) => console.error('Redis error:', err))
await redis.connect()
```

### Caching Pattern
```typescript
async function getCachedUser(userId: number) {
  const cacheKey = `user:${userId}`
  
  // Try to get from cache
  const cached = await redis.get(cacheKey)
  if (cached) {
    return JSON.parse(cached)
  }
  
  // Get from database
  const user = await prisma.user.findUnique({
    where: { id: userId }
  })
  
  if (user) {
    // Store in cache for 1 hour
    await redis.setEx(cacheKey, 3600, JSON.stringify(user))
  }
  
  return user
}

// Invalidate cache on update
async function updateUser(userId: number, data: any) {
  const user = await prisma.user.update({
    where: { id: userId },
    data
  })
  
  // Invalidate cache
  await redis.del(`user:${userId}`)
  
  return user
}
```

### Common Redis Operations
```typescript
// String operations
await redis.set('key', 'value')
await redis.get('key')
await redis.setEx('key', 3600, 'value') // Expire in 1 hour
await redis.del('key')

// Hash operations
await redis.hSet('user:1', 'name', 'John')
await redis.hGet('user:1', 'name')
await redis.hGetAll('user:1')

// List operations
await redis.lPush('queue', 'item1')
await redis.rPop('queue')
await redis.lRange('queue', 0, -1)

// Set operations
await redis.sAdd('tags', 'javascript')
await redis.sMembers('tags')
await redis.sIsMember('tags', 'javascript')

// Sorted set (leaderboard)
await redis.zAdd('leaderboard', { score: 100, value: 'user1' })
await redis.zRange('leaderboard', 0, 9, { REV: true }) // Top 10

// Pub/Sub
await redis.subscribe('channel', (message) => {
  console.log('Received:', message)
})
await redis.publish('channel', 'Hello!')
```

### Rate Limiting with Redis
```typescript
async function checkRateLimit(userId: number, limit: number = 10, window: number = 60) {
  const key = `rate_limit:${userId}`
  
  const current = await redis.incr(key)
  
  if (current === 1) {
    await redis.expire(key, window)
  }
  
  if (current > limit) {
    throw new Error('Rate limit exceeded')
  }
  
  return { remaining: limit - current }
}
```

## Database Optimization

### Indexing Best Practices
```sql
-- Single column index
CREATE INDEX idx_users_email ON users(email);

-- Composite index (order matters!)
CREATE INDEX idx_posts_author_created ON posts(author_id, created_at DESC);

-- Partial index
CREATE INDEX idx_active_users ON users(email) WHERE is_active = true;

-- Unique index
CREATE UNIQUE INDEX idx_users_username ON users(username);

-- Full-text search index
CREATE INDEX idx_posts_search ON posts USING GIN(to_tsvector('english', title || ' ' || content));

-- Check index usage
SELECT 
  schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan ASC;

-- Find missing indexes
SELECT 
  schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname = 'public'
  AND n_distinct > 100
  AND correlation < 0.1;
```

### Query Optimization
```typescript
// BAD: N+1 query problem
const posts = await prisma.post.findMany()
for (const post of posts) {
  post.author = await prisma.user.findUnique({ where: { id: post.authorId } })
}

// GOOD: Use include/join
const posts = await prisma.post.findMany({
  include: {
    author: true
  }
})

// BAD: Loading unnecessary data
const users = await prisma.user.findMany()

// GOOD: Select only needed fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    username: true,
    email: true
  }
})

// Use pagination
const posts = await prisma.post.findMany({
  take: 20,
  skip: (page - 1) * 20,
  orderBy: { createdAt: 'desc' }
})

// Use cursor-based pagination for large datasets
const posts = await prisma.post.findMany({
  take: 20,
  cursor: lastPostId ? { id: lastPostId } : undefined,
  skip: lastPostId ? 1 : 0,
  orderBy: { id: 'asc' }
})
```

### Connection Pooling
```typescript
// Prisma (automatic)
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
})

// PostgreSQL pool
const pool = new Pool({
  max: 20, // Maximum connections
  min: 5,  // Minimum connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
})
```

## Backup and Recovery

### PostgreSQL Backup
```bash
# Backup database
pg_dump -U username -d database_name -F c -f backup.dump

# Backup with compression
pg_dump -U username -d database_name | gzip > backup.sql.gz

# Restore database
pg_restore -U username -d database_name backup.dump

# Restore from SQL
psql -U username -d database_name < backup.sql
```

### Automated Backups
```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
DB_NAME="mydb"

# Create backup
pg_dump -U postgres $DB_NAME | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

```cron
# Run daily at 2 AM
0 2 * * * /path/to/backup.sh
```

## Monitoring and Debugging

### Prisma Query Logging
```typescript
const prisma = new PrismaClient({
  log: [
    { level: 'query', emit: 'event' },
    { level: 'error', emit: 'stdout' },
    { level: 'warn', emit: 'stdout' }
  ]
})

prisma.$on('query', (e) => {
  console.log('Query:', e.query)
  console.log('Duration:', e.duration + 'ms')
})
```

### PostgreSQL Slow Query Log
```sql
-- Enable slow query logging
ALTER DATABASE mydb SET log_min_duration_statement = 1000; -- Log queries > 1s

-- View slow queries
SELECT 
  query,
  calls,
  total_time,
  mean_time,
  max_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

## Best Practices Checklist

### Schema Design
- [ ] Use appropriate data types
- [ ] Add NOT NULL constraints where applicable
- [ ] Use foreign keys for referential integrity
- [ ] Add indexes on frequently queried columns
- [ ] Use composite indexes for multi-column queries
- [ ] Normalize data to avoid redundancy
- [ ] Use enums for fixed value sets

### Performance
- [ ] Use connection pooling
- [ ] Implement caching (Redis)
- [ ] Add database indexes
- [ ] Use pagination for large datasets
- [ ] Avoid N+1 queries
- [ ] Select only needed columns
- [ ] Use transactions for related operations

### Security
- [ ] Use parameterized queries (prevent SQL injection)
- [ ] Never store plain text passwords
- [ ] Use environment variables for credentials
- [ ] Implement Row Level Security (RLS)
- [ ] Limit database user permissions
- [ ] Enable SSL for database connections
- [ ] Regular security audits

### Maintenance
- [ ] Regular backups
- [ ] Monitor query performance
- [ ] Update dependencies
- [ ] Clean up old data
- [ ] Vacuum database (PostgreSQL)
- [ ] Analyze query plans
- [ ] Monitor disk space

## Resources

- [Prisma Documentation](https://www.prisma.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/docs/)
- [Database Design Best Practices](https://www.postgresql.org/docs/current/ddl.html)

---

**Remember**: Design your schema carefully. Optimize queries. Use indexes wisely. Monitor performance. Backup regularly. Security first.
