---
name: devops-deployment
description: Use this skill for deploying applications, setting up CI/CD pipelines, Docker containerization, cloud platforms (Vercel, Railway, AWS, DigitalOcean), server configuration, monitoring, and production best practices.
origin: Custom
---

# DevOps & Deployment Skill

Comprehensive guide for deploying and managing applications in production.

## When to Activate

- Deploying applications to production
- Setting up CI/CD pipelines
- Containerizing applications with Docker
- Configuring cloud platforms
- Setting up monitoring and logging
- Managing environment variables
- Configuring domains and SSL
- Scaling applications
- Troubleshooting production issues

## Deployment Platforms Comparison

### Vercel (Recommended for Next.js)
**Best for:**
- Next.js applications
- Static sites
- Serverless functions
- Frontend projects

**Pros:**
- Zero configuration for Next.js
- Automatic HTTPS
- Global CDN
- Preview deployments
- Free tier generous

**Cons:**
- Expensive for high traffic
- Limited backend capabilities
- Vendor lock-in

### Railway (Recommended for Full-Stack)
**Best for:**
- Full-stack applications
- Databases included
- Docker containers
- Background workers

**Pros:**
- Easy to use
- Built-in databases
- Reasonable pricing
- Great DX

**Cons:**
- Smaller than AWS
- Less features than cloud giants

### Render
**Best for:**
- Web services
- Static sites
- Cron jobs
- PostgreSQL databases

**Pros:**
- Simple pricing
- Free tier available
- Auto-deploy from Git
- Managed databases

**Cons:**
- Cold starts on free tier
- Limited regions

### DigitalOcean
**Best for:**
- VPS hosting
- Full control needed
- Cost-effective scaling
- Docker deployments

**Pros:**
- Predictable pricing
- Good documentation
- Full server access
- App Platform available

**Cons:**
- More manual setup
- Need DevOps knowledge

### AWS (Advanced)
**Best for:**
- Enterprise applications
- Complex infrastructure
- High scalability needs
- Multiple services integration

**Pros:**
- Most features
- Global infrastructure
- Highly scalable
- Many services

**Cons:**
- Complex
- Expensive
- Steep learning curve

## Docker Containerization

### Dockerfile for Node.js
```dockerfile
# Multi-stage build for smaller image
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build application
RUN npm run build

# Generate Prisma Client
RUN npx prisma generate

# Production stage
FROM node:18-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nodejs

# Copy necessary files from builder
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/prisma ./prisma

# Set user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "dist/index.js"]
```

### Dockerfile for Next.js
```dockerfile
FROM node:18-alpine AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package*.json ./
RUN npm ci

FROM node:18-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    networks:
      - app-network

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - app-network

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Docker Commands
```bash
# Build image
docker build -t myapp:latest .

# Run container
docker run -d -p 3000:3000 --name myapp myapp:latest

# Run with environment variables
docker run -d -p 3000:3000 \
  -e DATABASE_URL=postgresql://... \
  -e NODE_ENV=production \
  --name myapp myapp:latest

# View logs
docker logs myapp
docker logs -f myapp  # Follow logs

# Execute command in container
docker exec -it myapp sh

# Stop and remove
docker stop myapp
docker rm myapp

# Docker Compose
docker-compose up -d
docker-compose down
docker-compose logs -f
docker-compose restart app

# Clean up
docker system prune -a
docker volume prune
```

## CI/CD with GitHub Actions

### Node.js CI/CD Pipeline
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '18'

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run type check
        run: npm run type-check

      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test

      - name: Build
        run: npm run build

  deploy:
    name: Deploy to Production
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Deploy to Railway
        uses: berviantoleo/railway-deploy@main
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: myapp

      # Or deploy to Vercel
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v20
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'
```

### Docker Build and Push
```yaml
# .github/workflows/docker.yml
name: Docker Build and Push

on:
  push:
    branches: [main]
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v4
        with:
          images: username/myapp
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}

      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=registry,ref=username/myapp:buildcache
          cache-to: type=registry,ref=username/myapp:buildcache,mode=max
```

## Vercel Deployment

### vercel.json Configuration
```json
{
  "version": 2,
  "buildCommand": "npm run build",
  "devCommand": "npm run dev",
  "installCommand": "npm install",
  "framework": "nextjs",
  "regions": ["iad1"],
  "env": {
    "DATABASE_URL": "@database-url",
    "REDIS_URL": "@redis-url"
  },
  "build": {
    "env": {
      "NEXT_PUBLIC_API_URL": "https://api.example.com"
    }
  },
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "s-maxage=1, stale-while-revalidate"
        }
      ]
    }
  ],
  "redirects": [
    {
      "source": "/old-path",
      "destination": "/new-path",
      "permanent": true
    }
  ],
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://api.example.com/:path*"
    }
  ]
}
```

### Deploy Commands
```bash
# Install Vercel CLI
npm i -g vercel

# Login
vercel login

# Deploy to preview
vercel

# Deploy to production
vercel --prod

# Set environment variables
vercel env add DATABASE_URL production
vercel env add REDIS_URL production

# Pull environment variables
vercel env pull .env.local
```

## Railway Deployment

### railway.json
```json
{
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "npm run build"
  },
  "deploy": {
    "startCommand": "npm start",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}

```

### nixpacks.toml
```toml
[phases.setup]
nixPkgs = ['nodejs-18_x']

[phases.install]
cmds = ['npm ci']

[phases.build]
cmds = ['npm run build', 'npx prisma generate']

[start]
cmd = 'npm start'
```

### Deploy Commands
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login
railway login

# Link project
railway link

# Deploy
railway up

# Add environment variables
railway variables set DATABASE_URL=postgresql://...

# View logs
railway logs

# Open in browser
railway open
```

## Nginx Configuration

### Basic Reverse Proxy
```nginx
# /etc/nginx/sites-available/myapp
server {
    listen 80;
    server_name example.com www.example.com;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com www.example.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json application/xml+rss;

    # Proxy to Node.js app
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Static files caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        proxy_pass http://localhost:3000;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:3000/health;
        access_log off;
    }
}
```

### Load Balancing
```nginx
upstream backend {
    least_conn;
    server localhost:3000 weight=1;
    server localhost:3001 weight=1;
    server localhost:3002 weight=1;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## SSL/TLS with Let's Encrypt

### Install Certbot
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d example.com -d www.example.com

# Auto-renewal (already set up by certbot)
sudo certbot renew --dry-run

# Check renewal timer
sudo systemctl status certbot.timer
```

## Environment Variables Management

### .env.example Template
```bash
# .env.example
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/dbname

# Redis
REDIS_URL=redis://localhost:6379

# API Keys
OPENAI_API_KEY=sk-...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Authentication
JWT_SECRET=your-secret-key-here
SESSION_SECRET=your-session-secret

# Telegram Bot
BOT_TOKEN=your-bot-token
WEBHOOK_URL=https://yourdomain.com

# Email
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# App Configuration
NODE_ENV=production
PORT=3000
APP_URL=https://example.com

# Admin
ADMIN_IDS=123456789,987654321
```

### Loading Environment Variables
```typescript
// src/config/env.ts
import { z } from 'zod'
import { config } from 'dotenv'

config()

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.string().transform(Number),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  OPENAI_API_KEY: z.string().startsWith('sk-'),
  APP_URL: z.string().url()
})

export const env = envSchema.parse(process.env)
```

## Monitoring and Logging

### PM2 Process Manager
```bash
# Install PM2
npm install -g pm2

# Start application
pm2 start dist/index.js --name myapp

# Start with environment
pm2 start dist/index.js --name myapp --env production

# Monitor
pm2 monit

# View logs
pm2 logs myapp
pm2 logs myapp --lines 100

# Restart
pm2 restart myapp

# Stop
pm2 stop myapp

# Delete
pm2 delete myapp

# Save configuration
pm2 save

# Startup script
pm2 startup
pm2 save

# Update PM2
pm2 update
```

### PM2 Ecosystem File
```javascript
// ecosystem.config.js
module.exports = {
  apps: [
    {
      name: 'myapp',
      script: './dist/index.js',
      instances: 'max',
      exec_mode: 'cluster',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true
    }
  ]
}
```

### Winston Logger
```typescript
import winston from 'winston'

const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: 'myapp' },
  transports: [
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: 'logs/combined.log' })
  ]
})

if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }))
}

export default logger
```

### Health Check Endpoint
```typescript
import express from 'express'
import { PrismaClient } from '@prisma/client'
import redis from './redis'

const prisma = new PrismaClient()

export async function healthCheck(req: express.Request, res: express.Response) {
  const checks = {
    uptime: process.uptime(),
    timestamp: Date.now(),
    status: 'ok',
    services: {
      database: 'unknown',
      redis: 'unknown'
    }
  }

  try {
    // Check database
    await prisma.$queryRaw`SELECT 1`
    checks.services.database = 'ok'
  } catch (error) {
    checks.services.database = 'error'
    checks.status = 'degraded'
  }

  try {
    // Check Redis
    await redis.ping()
    checks.services.redis = 'ok'
  } catch (error) {
    checks.services.redis = 'error'
    checks.status = 'degraded'
  }

  const statusCode = checks.status === 'ok' ? 200 : 503
  res.status(statusCode).json(checks)
}
```

## Database Migrations in Production

### Prisma Migrations
```bash
# Generate migration
npx prisma migrate dev --name add_user_fields

# Apply migrations in production
npx prisma migrate deploy

# Check migration status
npx prisma migrate status

# Reset database (DANGEROUS - dev only)
npx prisma migrate reset
```

### Migration Script
```bash
#!/bin/bash
# migrate.sh

echo "Running database migrations..."

# Backup database first
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql

# Run migrations
npx prisma migrate deploy

if [ $? -eq 0 ]; then
  echo "Migrations completed successfully"
  exit 0
else
  echo "Migration failed!"
  exit 1
fi
```

## Scaling Strategies

### Horizontal Scaling with PM2
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'myapp',
    script: './dist/index.js',
    instances: 4, // Or 'max' for all CPU cores
    exec_mode: 'cluster',
    max_memory_restart: '500M'
  }]
}
```

### Load Balancing with Nginx
```nginx
upstream backend {
    least_conn;
    server 10.0.1.1:3000;
    server 10.0.1.2:3000;
    server 10.0.1.3:3000;
}
```

### Database Connection Pooling
```typescript
// Increase pool size for production
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  }
})

// Or with pg
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum pool size
  min: 5,
  idleTimeoutMillis: 30000
})
```

## Backup Strategy

### Automated Database Backups
```bash
#!/bin/bash
# backup-db.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/database"
S3_BUCKET="s3://my-backups/database"

# Create backup
pg_dump $DATABASE_URL | gzip > $BACKUP_DIR/backup_$DATE.sql.gz

# Upload to S3
aws s3 cp $BACKUP_DIR/backup_$DATE.sql.gz $S3_BUCKET/

# Keep only last 30 days locally
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

### Cron Job for Backups
```cron
# Run daily at 2 AM
0 2 * * * /path/to/backup-db.sh >> /var/log/backup.log 2>&1

# Run every 6 hours
0 */6 * * * /path/to/backup-db.sh >> /var/log/backup.log 2>&1
```

## Security Best Practices

### Firewall Configuration (UFW)
```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow specific IP only
sudo ufw allow from 203.0.113.0/24 to any port 22

# Check status
sudo ufw status
```

### Fail2Ban for SSH Protection
```bash
# Install
sudo apt install fail2ban

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Edit jail.local
sudo nano /etc/fail2ban/jail.local

# Restart
sudo systemctl restart fail2ban

# Check status
sudo fail2ban-client status sshd
```

## Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Environment variables configured
- [ ] Database migrations ready
- [ ] Backup created
- [ ] Dependencies updated
- [ ] Security audit completed
- [ ] Performance tested

### Deployment
- [ ] Deploy to staging first
- [ ] Run smoke tests
- [ ] Check logs for errors
- [ ] Verify database migrations
- [ ] Test critical user flows
- [ ] Monitor error rates
- [ ] Check performance metrics

### Post-Deployment
- [ ] Verify application is running
- [ ] Check all endpoints
- [ ] Monitor logs for 30 minutes
- [ ] Verify database connections
- [ ] Check external integrations
- [ ] Update documentation
- [ ] Notify team of deployment

### Rollback Plan
- [ ] Keep previous version available
- [ ] Document rollback procedure
- [ ] Test rollback in staging
- [ ] Have database backup ready
- [ ] Monitor for issues

## Troubleshooting

### Common Issues

**Application won't start:**
```bash
# Check logs
pm2 logs myapp
docker logs myapp

# Check port availability
sudo lsof -i :3000

# Check environment variables
printenv | grep DATABASE_URL
```

**Database connection issues:**
```bash
# Test connection
psql $DATABASE_URL

# Check if database is running
sudo systemctl status postgresql

# Check connection pool
# In your app, log pool stats
```

**High memory usage:**
```bash
# Check memory
free -h
pm2 monit

# Restart with memory limit
pm2 restart myapp --max-memory-restart 500M
```

**Slow performance:**
```bash
# Check CPU usage
top
htop

# Check database queries
# Enable slow query log in PostgreSQL

# Check network latency
ping your-database-host
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Vercel Documentation](https://vercel.com/docs)
- [Railway Documentation](https://docs.railway.app/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)

---

**Remember**: Test in staging first. Monitor after deployment. Have a rollback plan. Automate everything. Security is critical. Keep backups.
