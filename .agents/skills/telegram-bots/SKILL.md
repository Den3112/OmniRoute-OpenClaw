---
name: telegram-bots
description: Use this skill for building Telegram bots with Node.js, TypeScript, Telegraf, Grammy, or node-telegram-bot-api. Covers bot commands, inline keyboards, webhooks, payments, mini apps, and bot deployment.
origin: Custom
---

# Telegram Bots Development Skill

Comprehensive guide for building Telegram bots with modern frameworks and best practices.

## When to Activate

- Creating new Telegram bots
- Implementing bot commands and handlers
- Working with inline keyboards and buttons
- Setting up webhooks
- Implementing payments in bots
- Building Telegram Mini Apps
- Managing bot state and sessions
- Integrating with external APIs
- Deploying bots to production

## Bot Frameworks Comparison

### Telegraf (Recommended for most projects)
- Modern, TypeScript-friendly
- Middleware-based architecture
- Great documentation
- Active community

### Grammy (Modern alternative)
- Built for TypeScript from ground up
- Excellent type safety
- Plugin ecosystem
- Deno and Node.js support

### node-telegram-bot-api (Legacy)
- Older, callback-based
- Less TypeScript support
- Use only for maintaining existing bots

## Project Structure

```
telegram-bot/
├── src/
│   ├── bot.ts              # Bot initialization
│   ├── config.ts           # Configuration
│   ├── commands/           # Command handlers
│   │   ├── start.ts
│   │   ├── help.ts
│   │   └── settings.ts
│   ├── handlers/           # Event handlers
│   │   ├── message.ts
│   │   ├── callback.ts
│   │   └── inline.ts
│   ├── keyboards/          # Keyboard layouts
│   │   ├── main.ts
│   │   └── settings.ts
│   ├── middleware/         # Custom middleware
│   │   ├── auth.ts
│   │   ├── logging.ts
│   │   └── rateLimit.ts
│   ├── services/           # Business logic
│   │   ├── user.ts
│   │   └── payment.ts
│   ├── database/           # Database layer
│   │   ├── models/
│   │   └── migrations/
│   └── utils/              # Utilities
│       ├── logger.ts
│       └── helpers.ts
├── .env                    # Environment variables
├── package.json
└── tsconfig.json
```

## Getting Started with Telegraf

### Installation
```bash
npm install telegraf
npm install -D @types/node typescript ts-node
```

### Basic Bot Setup
```typescript
// src/bot.ts
import { Telegraf, Context } from 'telegraf'
import { message } from 'telegraf/filters'

interface BotContext extends Context {
  session?: {
    userId: number
    username?: string
  }
}

const bot = new Telegraf<BotContext>(process.env.BOT_TOKEN!)

// Start command
bot.command('start', async (ctx) => {
  await ctx.reply(
    `Привет, ${ctx.from.first_name}! 👋\n\nЯ бот-помощник. Используй /help для списка команд.`
  )
})

// Help command
bot.command('help', async (ctx) => {
  const helpText = `
📋 Доступные команды:

/start - Начать работу с ботом
/help - Показать это сообщение
/settings - Настройки
/status - Проверить статус
  `.trim()
  
  await ctx.reply(helpText)
})

// Handle text messages
bot.on(message('text'), async (ctx) => {
  const text = ctx.message.text
  await ctx.reply(`Вы написали: ${text}`)
})

// Error handling
bot.catch((err, ctx) => {
  console.error('Bot error:', err)
  ctx.reply('Произошла ошибка. Попробуйте позже.')
})

// Start bot
bot.launch()

// Enable graceful stop
process.once('SIGINT', () => bot.stop('SIGINT'))
process.once('SIGTERM', () => bot.stop('SIGTERM'))

console.log('Bot started!')
```

### Configuration
```typescript
// src/config.ts
import { config } from 'dotenv'

config()

export const CONFIG = {
  BOT_TOKEN: process.env.BOT_TOKEN!,
  WEBHOOK_URL: process.env.WEBHOOK_URL,
  PORT: parseInt(process.env.PORT || '3000'),
  DATABASE_URL: process.env.DATABASE_URL!,
  ADMIN_IDS: process.env.ADMIN_IDS?.split(',').map(Number) || [],
  NODE_ENV: process.env.NODE_ENV || 'development'
}

// Validate required config
if (!CONFIG.BOT_TOKEN) {
  throw new Error('BOT_TOKEN is required')
}

if (!CONFIG.DATABASE_URL) {
  throw new Error('DATABASE_URL is required')
}
```

## Inline Keyboards

### Simple Keyboard
```typescript
import { Markup } from 'telegraf'

bot.command('menu', async (ctx) => {
  await ctx.reply(
    'Выберите действие:',
    Markup.inlineKeyboard([
      [Markup.button.callback('📊 Статистика', 'stats')],
      [Markup.button.callback('⚙️ Настройки', 'settings')],
      [Markup.button.callback('❓ Помощь', 'help')]
    ])
  )
})

// Handle button clicks
bot.action('stats', async (ctx) => {
  await ctx.answerCbQuery()
  await ctx.editMessageText('📊 Ваша статистика:\n\nПользователей: 1000\nСообщений: 5000')
})

bot.action('settings', async (ctx) => {
  await ctx.answerCbQuery()
  await ctx.editMessageText(
    '⚙️ Настройки:',
    Markup.inlineKeyboard([
      [Markup.button.callback('🔔 Уведомления', 'toggle_notifications')],
      [Markup.button.callback('🌐 Язык', 'change_language')],
      [Markup.button.callback('« Назад', 'back_to_menu')]
    ])
  )
})
```

### Dynamic Keyboards
```typescript
function createPaginationKeyboard(page: number, totalPages: number) {
  const buttons = []
  
  // Previous button
  if (page > 1) {
    buttons.push(Markup.button.callback('« Назад', `page_${page - 1}`))
  }
  
  // Page indicator
  buttons.push(Markup.button.callback(`${page}/${totalPages}`, 'noop'))
  
  // Next button
  if (page < totalPages) {
    buttons.push(Markup.button.callback('Вперед »', `page_${page + 1}`))
  }
  
  return Markup.inlineKeyboard([buttons])
}

bot.command('list', async (ctx) => {
  const page = 1
  const totalPages = 10
  
  await ctx.reply(
    `Страница ${page} из ${totalPages}`,
    createPaginationKeyboard(page, totalPages)
  )
})

// Handle pagination
bot.action(/page_(\d+)/, async (ctx) => {
  const page = parseInt(ctx.match[1])
  const totalPages = 10
  
  await ctx.answerCbQuery()
  await ctx.editMessageText(
    `Страница ${page} из ${totalPages}`,
    createPaginationKeyboard(page, totalPages)
  )
})
```

### URL and Web App Buttons
```typescript
bot.command('links', async (ctx) => {
  await ctx.reply(
    'Полезные ссылки:',
    Markup.inlineKeyboard([
      [Markup.button.url('🌐 Наш сайт', 'https://example.com')],
      [Markup.button.url('📱 Telegram канал', 'https://t.me/channel')],
      [Markup.button.webApp('🚀 Открыть приложение', 'https://app.example.com')]
    ])
  )
})
```

## Reply Keyboards

```typescript
import { Markup } from 'telegraf'

// Main menu keyboard
const mainKeyboard = Markup.keyboard([
  ['📊 Статистика', '⚙️ Настройки'],
  ['💰 Баланс', '📝 История'],
  ['❓ Помощь']
]).resize()

bot.command('start', async (ctx) => {
  await ctx.reply(
    'Главное меню:',
    mainKeyboard
  )
})

// Handle keyboard buttons
bot.hears('📊 Статистика', async (ctx) => {
  await ctx.reply('Ваша статистика...')
})

bot.hears('⚙️ Настройки', async (ctx) => {
  await ctx.reply('Настройки...')
})

// Remove keyboard
bot.command('hide', async (ctx) => {
  await ctx.reply(
    'Клавиатура скрыта',
    Markup.removeKeyboard()
  )
})
```

## Session Management

### Using Telegraf Sessions
```typescript
import { session } from 'telegraf'

interface SessionData {
  step?: string
  userData?: {
    name?: string
    age?: number
    email?: string
  }
}

interface BotContext extends Context {
  session: SessionData
}

const bot = new Telegraf<BotContext>(process.env.BOT_TOKEN!)

// Enable sessions
bot.use(session())

// Multi-step form example
bot.command('register', async (ctx) => {
  ctx.session.step = 'name'
  await ctx.reply('Как вас зовут?')
})

bot.on(message('text'), async (ctx) => {
  const step = ctx.session.step
  
  if (step === 'name') {
    ctx.session.userData = { name: ctx.message.text }
    ctx.session.step = 'age'
    await ctx.reply('Сколько вам лет?')
  } else if (step === 'age') {
    const age = parseInt(ctx.message.text)
    
    if (isNaN(age) || age < 0 || age > 150) {
      await ctx.reply('Пожалуйста, введите корректный возраст')
      return
    }
    
    ctx.session.userData!.age = age
    ctx.session.step = 'email'
    await ctx.reply('Введите ваш email:')
  } else if (step === 'email') {
    ctx.session.userData!.email = ctx.message.text
    
    const { name, age, email } = ctx.session.userData!
    
    await ctx.reply(
      `Регистрация завершена!\n\nИмя: ${name}\nВозраст: ${age}\nEmail: ${email}`
    )
    
    // Clear session
    ctx.session = {}
  }
})
```

### Redis Session Storage
```typescript
import { Redis } from '@telegraf/session/redis'
import { session } from 'telegraf'

const store = Redis({
  url: process.env.REDIS_URL
})

bot.use(session({ store }))
```

## Middleware

### Authentication Middleware
```typescript
// src/middleware/auth.ts
import { Context, MiddlewareFn } from 'telegraf'
import { CONFIG } from '../config'

export const adminOnly: MiddlewareFn<Context> = async (ctx, next) => {
  const userId = ctx.from?.id
  
  if (!userId || !CONFIG.ADMIN_IDS.includes(userId)) {
    await ctx.reply('⛔ У вас нет доступа к этой команде')
    return
  }
  
  return next()
}

// Usage
bot.command('admin', adminOnly, async (ctx) => {
  await ctx.reply('Админ панель...')
})
```

### Rate Limiting Middleware
```typescript
// src/middleware/rateLimit.ts
import { Context, MiddlewareFn } from 'telegraf'

const userRequests = new Map<number, number[]>()

export function rateLimit(maxRequests: number, windowMs: number): MiddlewareFn<Context> {
  return async (ctx, next) => {
    const userId = ctx.from?.id
    if (!userId) return next()
    
    const now = Date.now()
    const userReqs = userRequests.get(userId) || []
    
    // Remove old requests outside the window
    const recentReqs = userReqs.filter(time => now - time < windowMs)
    
    if (recentReqs.length >= maxRequests) {
      await ctx.reply('⏱ Слишком много запросов. Попробуйте позже.')
      return
    }
    
    recentReqs.push(now)
    userRequests.set(userId, recentReqs)
    
    return next()
  }
}

// Usage: 5 requests per minute
bot.use(rateLimit(5, 60000))
```

### Logging Middleware
```typescript
// src/middleware/logging.ts
import { Context, MiddlewareFn } from 'telegraf'

export const logging: MiddlewareFn<Context> = async (ctx, next) => {
  const start = Date.now()
  const userId = ctx.from?.id
  const username = ctx.from?.username
  const updateType = ctx.updateType
  
  console.log(`[${new Date().toISOString()}] User ${userId} (@${username}) - ${updateType}`)
  
  await next()
  
  const duration = Date.now() - start
  console.log(`[${new Date().toISOString()}] Processed in ${duration}ms`)
}

bot.use(logging)
```

## File Handling

### Receiving Files
```typescript
import { message } from 'telegraf/filters'
import axios from 'axios'
import fs from 'fs'

// Handle photos
bot.on(message('photo'), async (ctx) => {
  const photo = ctx.message.photo[ctx.message.photo.length - 1]
  const fileLink = await ctx.telegram.getFileLink(photo.file_id)
  
  await ctx.reply(`Получено фото: ${fileLink.href}`)
  
  // Download file
  const response = await axios.get(fileLink.href, { responseType: 'arraybuffer' })
  fs.writeFileSync(`./downloads/${photo.file_id}.jpg`, response.data)
})

// Handle documents
bot.on(message('document'), async (ctx) => {
  const doc = ctx.message.document
  const fileLink = await ctx.telegram.getFileLink(doc.file_id)
  
  await ctx.reply(`Получен файл: ${doc.file_name} (${doc.file_size} bytes)`)
})

// Handle voice messages
bot.on(message('voice'), async (ctx) => {
  const voice = ctx.message.voice
  const fileLink = await ctx.telegram.getFileLink(voice.file_id)
  
  await ctx.reply('Получено голосовое сообщение')
})
```

### Sending Files
```typescript
import { InputFile } from 'telegraf'

bot.command('sendphoto', async (ctx) => {
  // Send from URL
  await ctx.replyWithPhoto('https://example.com/image.jpg')
  
  // Send from file
  await ctx.replyWithPhoto(new InputFile('./image.jpg'))
  
  // Send with caption
  await ctx.replyWithPhoto(
    new InputFile('./image.jpg'),
    { caption: 'Описание фото' }
  )
})

bot.command('senddoc', async (ctx) => {
  await ctx.replyWithDocument(new InputFile('./document.pdf'))
})

bot.command('sendvideo', async (ctx) => {
  await ctx.replyWithVideo(new InputFile('./video.mp4'))
})
```

## Inline Mode

```typescript
import { InlineQueryResult } from 'telegraf/types'

bot.on('inline_query', async (ctx) => {
  const query = ctx.inlineQuery.query
  
  const results: InlineQueryResult[] = [
    {
      type: 'article',
      id: '1',
      title: 'Результат 1',
      description: 'Описание результата',
      input_message_content: {
        message_text: `Вы выбрали: ${query}`
      }
    },
    {
      type: 'photo',
      id: '2',
      photo_url: 'https://example.com/photo.jpg',
      thumbnail_url: 'https://example.com/thumb.jpg',
      caption: 'Фото из инлайн режима'
    }
  ]
  
  await ctx.answerInlineQuery(results, {
    cache_time: 300
  })
})
```

## Webhooks

### Setting Up Webhooks
```typescript
import express from 'express'
import { Telegraf } from 'telegraf'

const bot = new Telegraf(process.env.BOT_TOKEN!)
const app = express()

app.use(express.json())

// Webhook endpoint
app.post('/webhook', (req, res) => {
  bot.handleUpdate(req.body)
  res.sendStatus(200)
})

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' })
})

const PORT = process.env.PORT || 3000

app.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`)
  
  // Set webhook
  const webhookUrl = `${process.env.WEBHOOK_URL}/webhook`
  await bot.telegram.setWebhook(webhookUrl)
  console.log(`Webhook set to ${webhookUrl}`)
})

// Graceful shutdown
process.once('SIGINT', () => bot.stop('SIGINT'))
process.once('SIGTERM', () => bot.stop('SIGTERM'))
```

### Webhook with Secret Token
```typescript
import crypto from 'crypto'

const SECRET_TOKEN = process.env.WEBHOOK_SECRET!

app.post('/webhook', (req, res) => {
  const token = req.headers['x-telegram-bot-api-secret-token']
  
  if (token !== SECRET_TOKEN) {
    return res.sendStatus(403)
  }
  
  bot.handleUpdate(req.body)
  res.sendStatus(200)
})

// Set webhook with secret
await bot.telegram.setWebhook(webhookUrl, {
  secret_token: SECRET_TOKEN
})
```

## Payments

### Creating Invoice
```typescript
bot.command('buy', async (ctx) => {
  await ctx.replyWithInvoice({
    title: 'Премиум подписка',
    description: 'Доступ ко всем функциям на 1 месяц',
    payload: 'premium_1month',
    provider_token: process.env.PAYMENT_TOKEN!,
    currency: 'RUB',
    prices: [
      { label: 'Подписка', amount: 50000 }, // 500.00 RUB (amount in kopecks)
      { label: 'Скидка', amount: -5000 }    // -50.00 RUB
    ]
  })
})

// Handle successful payment
bot.on('pre_checkout_query', async (ctx) => {
  await ctx.answerPreCheckoutQuery(true)
})

bot.on('successful_payment', async (ctx) => {
  const payment = ctx.message.successful_payment
  
  await ctx.reply(
    `✅ Оплата получена!\n\nСумма: ${payment.total_amount / 100} ${payment.currency}\nID: ${payment.telegram_payment_charge_id}`
  )
  
  // Grant premium access to user
  await grantPremiumAccess(ctx.from.id)
})
```

## Telegram Mini Apps

### Web App Button
```typescript
import { Markup } from 'telegraf'

bot.command('app', async (ctx) => {
  await ctx.reply(
    'Открыть приложение:',
    Markup.keyboard([
      [Markup.button.webApp('🚀 Запустить', 'https://app.example.com')]
    ]).resize()
  )
})

// Handle data from Web App
bot.on('web_app_data', async (ctx) => {
  const data = JSON.parse(ctx.webAppData.data)
  
  await ctx.reply(`Получены данные: ${JSON.stringify(data)}`)
})
```

### Mini App HTML
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://telegram.org/js/telegram-web-app.js"></script>
  <title>Mini App</title>
</head>
<body>
  <h1>Telegram Mini App</h1>
  <button id="sendData">Отправить данные</button>

  <script>
    const tg = window.Telegram.WebApp
    
    // Expand app
    tg.expand()
    
    // Send data to bot
    document.getElementById('sendData').addEventListener('click', () => {
      const data = { action: 'test', value: 123 }
      tg.sendData(JSON.stringify(data))
    })
    
    // Show main button
    tg.MainButton.setText('Готово')
    tg.MainButton.show()
    tg.MainButton.onClick(() => {
      tg.close()
    })
  </script>
</body>
</html>
```

## Database Integration

### Prisma Setup
```typescript
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

model User {
  id           Int       @id @default(autoincrement())
  telegramId   BigInt    @unique
  username     String?
  firstName    String
  lastName     String?
  isPremium    Boolean   @default(false)
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt
  messages     Message[]
}

model Message {
  id        Int      @id @default(autoincrement())
  userId    Int
  user      User     @relation(fields: [userId], references: [id])
  text      String
  createdAt DateTime @default(now())
}
```

### Using Prisma in Bot
```typescript
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

bot.command('start', async (ctx) => {
  const telegramId = ctx.from.id
  
  // Find or create user
  let user = await prisma.user.findUnique({
    where: { telegramId }
  })
  
  if (!user) {
    user = await prisma.user.create({
      data: {
        telegramId,
        username: ctx.from.username,
        firstName: ctx.from.first_name,
        lastName: ctx.from.last_name
      }
    })
  }
  
  await ctx.reply(`Привет, ${user.firstName}!`)
})

bot.on(message('text'), async (ctx) => {
  const user = await prisma.user.findUnique({
    where: { telegramId: ctx.from.id }
  })
  
  if (user) {
    await prisma.message.create({
      data: {
        userId: user.id,
        text: ctx.message.text
      }
    })
  }
})
```

## Error Handling

### Global Error Handler
```typescript
bot.catch((err, ctx) => {
  console.error('Bot error:', err)
  
  // Log to error tracking service
  // Sentry.captureException(err)
  
  // Notify user
  ctx.reply('Произошла ошибка. Попробуйте позже.')
  
  // Notify admin
  if (CONFIG.ADMIN_IDS.length > 0) {
    ctx.telegram.sendMessage(
      CONFIG.ADMIN_IDS[0],
      `⚠️ Error: ${err.message}\n\nUser: ${ctx.from?.id}`
    )
  }
})
```

### Try-Catch Pattern
```typescript
bot.command('risky', async (ctx) => {
  try {
    const result = await riskyOperation()
    await ctx.reply(`Результат: ${result}`)
  } catch (error) {
    console.error('Error in risky command:', error)
    await ctx.reply('Не удалось выполнить операцию')
  }
})
```

## Testing

### Unit Tests
```typescript
import { Telegraf } from 'telegraf'
import { describe, it, expect, beforeEach } from 'vitest'

describe('Bot Commands', () => {
  let bot: Telegraf
  
  beforeEach(() => {
    bot = new Telegraf('test-token')
  })
  
  it('should respond to /start command', async () => {
    const ctx = {
      reply: vi.fn(),
      from: { first_name: 'Test' }
    }
    
    await bot.handleUpdate({
      message: {
        text: '/start',
        from: ctx.from
      }
    })
    
    expect(ctx.reply).toHaveBeenCalledWith(
      expect.stringContaining('Привет, Test')
    )
  })
})
```

## Deployment

### Environment Variables
```bash
# .env
BOT_TOKEN=your_bot_token_here
WEBHOOK_URL=https://yourdomain.com
DATABASE_URL=postgresql://user:pass@host:5432/db
REDIS_URL=redis://localhost:6379
ADMIN_IDS=123456789,987654321
NODE_ENV=production
```

### Docker Deployment
```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

CMD ["node", "dist/bot.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  bot:
    build: .
    env_file: .env
    restart: unless-stopped
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: botdb
      POSTGRES_USER: botuser
      POSTGRES_PASSWORD: botpass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### PM2 Deployment
```json
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'telegram-bot',
    script: 'dist/bot.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production'
    }
  }]
}
```

```bash
# Deploy with PM2
pm2 start ecosystem.config.js
pm2 save
pm2 startup
```

## Best Practices

### Security
- [ ] Never commit bot token to git
- [ ] Use environment variables for secrets
- [ ] Validate all user input
- [ ] Implement rate limiting
- [ ] Use webhook secret tokens
- [ ] Sanitize user data before database queries

### Performance
- [ ] Use webhooks instead of polling in production
- [ ] Implement caching for frequent queries
- [ ] Use Redis for session storage
- [ ] Optimize database queries with indexes
- [ ] Implement pagination for large lists

### User Experience
- [ ] Provide clear command descriptions
- [ ] Use inline keyboards for better UX
- [ ] Show loading indicators for long operations
- [ ] Handle errors gracefully
- [ ] Provide help and documentation

### Code Quality
- [ ] Use TypeScript for type safety
- [ ] Write unit tests for critical logic
- [ ] Use middleware for common functionality
- [ ] Keep handlers small and focused
- [ ] Document complex logic

## Resources

- [Telegram Bot API](https://core.telegram.org/bots/api)
- [Telegraf Documentation](https://telegraf.js.org/)
- [Grammy Framework](https://grammy.dev/)
- [Telegram Mini Apps](https://core.telegram.org/bots/webapps)
- [BotFather](https://t.me/botfather) - Create and manage bots

---

**Remember**: Test thoroughly before deploying. Monitor bot performance and errors. Keep dependencies updated. Respect user privacy and Telegram's terms of service.
