---
name: realtime-features
description: Use this skill for implementing real-time features including WebSockets, Socket.io, Server-Sent Events (SSE), WebRTC, live chat, notifications, collaborative editing, and real-time data synchronization (2026).
origin: Custom
---

# Real-time Features Skill

Comprehensive guide for implementing real-time features in web applications (Updated May 2026).

## When to Activate

- Implementing live chat
- Real-time notifications
- Collaborative editing
- Live updates/feeds
- WebSocket connections
- Server-Sent Events (SSE)
- WebRTC video/audio
- Real-time dashboards
- Multiplayer features
- Live presence indicators

## Real-time Technologies Comparison

### WebSockets
**Best for:** Bidirectional communication, chat, gaming
- Full-duplex communication
- Low latency
- Persistent connection
- More complex to implement

### Server-Sent Events (SSE)
**Best for:** Server-to-client updates, notifications, live feeds
- Unidirectional (server → client)
- Simpler than WebSockets
- Auto-reconnection
- HTTP-based

### WebRTC
**Best for:** Video/audio calls, peer-to-peer
- Direct peer-to-peer
- Low latency
- Built-in encryption
- Complex setup

### Long Polling
**Best for:** Legacy browser support
- HTTP-based
- Higher latency
- More server load
- Fallback option

## Socket.io (Recommended for Most Cases)

### Why Socket.io?
- WebSocket + fallbacks
- Auto-reconnection
- Room/namespace support
- Broadcasting
- TypeScript support
- Easy to use

### Server Setup

```typescript
// server.ts
import { createServer } from 'http'
import { Server } from 'socket.io'
import { parse } from 'url'
import next from 'next'

const dev = process.env.NODE_ENV !== 'production'
const app = next({ dev })
const handle = app.getRequestHandler()

app.prepare().then(() => {
  const server = createServer((req, res) => {
    const parsedUrl = parse(req.url!, true)
    handle(req, res, parsedUrl)
  })

  const io = new Server(server, {
    cors: {
      origin: process.env.NEXT_PUBLIC_APP_URL,
      methods: ['GET', 'POST']
    }
  })

  // Connection handler
  io.on('connection', (socket) => {
    console.log('Client connected:', socket.id)

    // Join room
    socket.on('join-room', (roomId: string) => {
      socket.join(roomId)
      console.log(`Socket ${socket.id} joined room ${roomId}`)
    })

    // Leave room
    socket.on('leave-room', (roomId: string) => {
      socket.leave(roomId)
      console.log(`Socket ${socket.id} left room ${roomId}`)
    })

    // Handle messages
    socket.on('message', (data: { roomId: string; message: string; userId: string }) => {
      // Broadcast to room
      io.to(data.roomId).emit('message', {
        id: Date.now().toString(),
        userId: data.userId,
        message: data.message,
        timestamp: new Date()
      })
    })

    // Typing indicator
    socket.on('typing', (data: { roomId: string; userId: string; isTyping: boolean }) => {
      socket.to(data.roomId).emit('user-typing', {
        userId: data.userId,
        isTyping: data.isTyping
      })
    })

    // Disconnect
    socket.on('disconnect', () => {
      console.log('Client disconnected:', socket.id)
    })
  })

  const PORT = process.env.PORT || 3000
  server.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`)
  })
})
```

### Client Setup

```typescript
// lib/socket.ts
import { io, Socket } from 'socket.io-client'

let socket: Socket | null = null

export function getSocket(): Socket {
  if (!socket) {
    socket = io(process.env.NEXT_PUBLIC_SOCKET_URL || 'http://localhost:3000', {
      autoConnect: false,
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionAttempts: 5
    })
  }
  return socket
}

export function connectSocket() {
  const socket = getSocket()
  if (!socket.connected) {
    socket.connect()
  }
  return socket
}

export function disconnectSocket() {
  const socket = getSocket()
  if (socket.connected) {
    socket.disconnect()
  }
}
```

### React Hook for Socket.io

```typescript
// hooks/useSocket.ts
import { useEffect, useState } from 'react'
import { Socket } from 'socket.io-client'
import { getSocket, connectSocket, disconnectSocket } from '@/lib/socket'

export function useSocket() {
  const [socket, setSocket] = useState<Socket | null>(null)
  const [isConnected, setIsConnected] = useState(false)

  useEffect(() => {
    const socketInstance = connectSocket()
    setSocket(socketInstance)

    socketInstance.on('connect', () => {
      console.log('Socket connected')
      setIsConnected(true)
    })

    socketInstance.on('disconnect', () => {
      console.log('Socket disconnected')
      setIsConnected(false)
    })

    return () => {
      disconnectSocket()
    }
  }, [])

  return { socket, isConnected }
}
```

### Live Chat Component

```typescript
'use client'

import { useState, useEffect, useRef } from 'react'
import { useSocket } from '@/hooks/useSocket'

interface Message {
  id: string
  userId: string
  message: string
  timestamp: Date
}

export function LiveChat({ roomId, userId }: { roomId: string; userId: string }) {
  const { socket, isConnected } = useSocket()
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set())
  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!socket) return

    // Join room
    socket.emit('join-room', roomId)

    // Listen for messages
    socket.on('message', (message: Message) => {
      setMessages((prev) => [...prev, message])
    })

    // Listen for typing
    socket.on('user-typing', ({ userId, isTyping }: { userId: string; isTyping: boolean }) => {
      setTypingUsers((prev) => {
        const newSet = new Set(prev)
        if (isTyping) {
          newSet.add(userId)
        } else {
          newSet.delete(userId)
        }
        return newSet
      })
    })

    return () => {
      socket.emit('leave-room', roomId)
      socket.off('message')
      socket.off('user-typing')
    }
  }, [socket, roomId])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const sendMessage = () => {
    if (!socket || !input.trim()) return

    socket.emit('message', {
      roomId,
      message: input,
      userId
    })

    setInput('')
  }

  const handleTyping = (isTyping: boolean) => {
    if (!socket) return
    socket.emit('typing', { roomId, userId, isTyping })
  }

  return (
    <div className="flex flex-col h-screen max-w-2xl mx-auto">
      <div className="bg-gray-100 p-4">
        <h2 className="text-xl font-bold">Chat Room: {roomId}</h2>
        <p className="text-sm">
          {isConnected ? '🟢 Connected' : '🔴 Disconnected'}
        </p>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`p-2 rounded ${
              msg.userId === userId ? 'bg-blue-100 ml-auto' : 'bg-gray-100'
            } max-w-xs`}
          >
            <p className="text-sm font-semibold">{msg.userId}</p>
            <p>{msg.message}</p>
            <p className="text-xs text-gray-500">
              {new Date(msg.timestamp).toLocaleTimeString()}
            </p>
          </div>
        ))}
        <div ref={messagesEndRef} />
      </div>

      {typingUsers.size > 0 && (
        <div className="px-4 py-2 text-sm text-gray-500">
          {Array.from(typingUsers).join(', ')} {typingUsers.size === 1 ? 'is' : 'are'} typing...
        </div>
      )}

      <div className="p-4 border-t">
        <div className="flex gap-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onFocus={() => handleTyping(true)}
            onBlur={() => handleTyping(false)}
            onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
            placeholder="Type a message..."
            className="flex-1 px-4 py-2 border rounded"
          />
          <button
            onClick={sendMessage}
            disabled={!isConnected || !input.trim()}
            className="px-6 py-2 bg-blue-600 text-white rounded disabled:opacity-50"
          >
            Send
          </button>
        </div>
      </div>
    </div>
  )
}
```

## Server-Sent Events (SSE)

### Server Implementation

```typescript
// app/api/events/route.ts
import { NextRequest } from 'next/server'

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    async start(controller) {
      // Send initial connection message
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ type: 'connected' })}\n\n`)
      )

      // Simulate real-time updates
      const interval = setInterval(() => {
        const data = {
          type: 'update',
          timestamp: new Date().toISOString(),
          value: Math.random()
        }

        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(data)}\n\n`)
        )
      }, 1000)

      // Cleanup on close
      request.signal.addEventListener('abort', () => {
        clearInterval(interval)
        controller.close()
      })
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

### Client Implementation

```typescript
'use client'

import { useEffect, useState } from 'react'

interface SSEData {
  type: string
  timestamp?: string
  value?: number
}

export function SSEComponent() {
  const [data, setData] = useState<SSEData[]>([])
  const [isConnected, setIsConnected] = useState(false)

  useEffect(() => {
    const eventSource = new EventSource('/api/events')

    eventSource.onopen = () => {
      console.log('SSE connected')
      setIsConnected(true)
    }

    eventSource.onmessage = (event) => {
      const newData = JSON.parse(event.data)
      setData((prev) => [...prev.slice(-9), newData]) // Keep last 10
    }

    eventSource.onerror = () => {
      console.error('SSE error')
      setIsConnected(false)
      eventSource.close()
    }

    return () => {
      eventSource.close()
    }
  }, [])

  return (
    <div>
      <h2>Real-time Updates {isConnected ? '🟢' : '🔴'}</h2>
      <div className="space-y-2">
        {data.map((item, i) => (
          <div key={i} className="p-2 bg-gray-100 rounded">
            <p>Type: {item.type}</p>
            {item.timestamp && <p>Time: {item.timestamp}</p>}
            {item.value && <p>Value: {item.value.toFixed(2)}</p>}
          </div>
        ))}
      </div>
    </div>
  )
}
```

## Real-time Notifications

```typescript
// app/api/notifications/route.ts
import { NextRequest } from 'next/server'

const clients = new Set<ReadableStreamDefaultController>()

export async function GET(request: NextRequest) {
  const encoder = new TextEncoder()

  const stream = new ReadableStream({
    start(controller) {
      clients.add(controller)

      // Send heartbeat
      const heartbeat = setInterval(() => {
        controller.enqueue(encoder.encode(': heartbeat\n\n'))
      }, 30000)

      request.signal.addEventListener('abort', () => {
        clearInterval(heartbeat)
        clients.delete(controller)
        controller.close()
      })
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

// Function to broadcast notification to all clients
export function broadcastNotification(notification: any) {
  const encoder = new TextEncoder()
  const data = `data: ${JSON.stringify(notification)}\n\n`

  clients.forEach((controller) => {
    try {
      controller.enqueue(encoder.encode(data))
    } catch (error) {
      clients.delete(controller)
    }
  })
}
```

### Notification Component

```typescript
'use client'

import { useEffect, useState } from 'react'

interface Notification {
  id: string
  title: string
  message: string
  type: 'info' | 'success' | 'warning' | 'error'
  timestamp: string
}

export function NotificationCenter() {
  const [notifications, setNotifications] = useState<Notification[]>([])

  useEffect(() => {
    const eventSource = new EventSource('/api/notifications')

    eventSource.onmessage = (event) => {
      const notification = JSON.parse(event.data)
      setNotifications((prev) => [notification, ...prev])

      // Auto-remove after 5 seconds
      setTimeout(() => {
        setNotifications((prev) => prev.filter((n) => n.id !== notification.id))
      }, 5000)
    }

    return () => {
      eventSource.close()
    }
  }, [])

  return (
    <div className="fixed top-4 right-4 space-y-2 z-50">
      {notifications.map((notification) => (
        <div
          key={notification.id}
          className={`p-4 rounded shadow-lg max-w-sm ${
            notification.type === 'error'
              ? 'bg-red-100'
              : notification.type === 'success'
              ? 'bg-green-100'
              : notification.type === 'warning'
              ? 'bg-yellow-100'
              : 'bg-blue-100'
          }`}
        >
          <h3 className="font-bold">{notification.title}</h3>
          <p className="text-sm">{notification.message}</p>
        </div>
      ))}
    </div>
  )
}
```

## WebRTC Video Chat

### Setup

```bash
npm install simple-peer
```

### Video Chat Component

```typescript
'use client'

import { useEffect, useRef, useState } from 'react'
import SimplePeer from 'simple-peer'
import { useSocket } from '@/hooks/useSocket'

export function VideoChat({ roomId, userId }: { roomId: string; userId: string }) {
  const { socket } = useSocket()
  const [peers, setPeers] = useState<Map<string, SimplePeer.Instance>>(new Map())
  const localVideoRef = useRef<HTMLVideoElement>(null)
  const [localStream, setLocalStream] = useState<MediaStream | null>(null)

  useEffect(() => {
    // Get local media stream
    navigator.mediaDevices
      .getUserMedia({ video: true, audio: true })
      .then((stream) => {
        setLocalStream(stream)
        if (localVideoRef.current) {
          localVideoRef.current.srcObject = stream
        }
      })
      .catch((err) => console.error('Error accessing media devices:', err))

    return () => {
      localStream?.getTracks().forEach((track) => track.stop())
    }
  }, [])

  useEffect(() => {
    if (!socket || !localStream) return

    socket.emit('join-room', roomId)

    // Handle new user joining
    socket.on('user-joined', ({ userId: newUserId }: { userId: string }) => {
      if (newUserId === userId) return

      // Create peer as initiator
      const peer = new SimplePeer({
        initiator: true,
        stream: localStream,
        trickle: false
      })

      peer.on('signal', (signal) => {
        socket.emit('signal', {
          to: newUserId,
          from: userId,
          signal
        })
      })

      peer.on('stream', (remoteStream) => {
        // Handle remote stream
        console.log('Received remote stream from', newUserId)
      })

      setPeers((prev) => new Map(prev).set(newUserId, peer))
    })

    // Handle incoming signal
    socket.on('signal', ({ from, signal }: { from: string; signal: any }) => {
      let peer = peers.get(from)

      if (!peer) {
        // Create peer as receiver
        peer = new SimplePeer({
          initiator: false,
          stream: localStream,
          trickle: false
        })

        peer.on('signal', (signal) => {
          socket.emit('signal', {
            to: from,
            from: userId,
            signal
          })
        })

        peer.on('stream', (remoteStream) => {
          console.log('Received remote stream from', from)
        })

        setPeers((prev) => new Map(prev).set(from, peer))
      }

      peer.signal(signal)
    })

    return () => {
      socket.off('user-joined')
      socket.off('signal')
      peers.forEach((peer) => peer.destroy())
    }
  }, [socket, localStream, roomId, userId])

  return (
    <div className="grid grid-cols-2 gap-4">
      <div>
        <h3>You</h3>
        <video
          ref={localVideoRef}
          autoPlay
          muted
          playsInline
          className="w-full rounded"
        />
      </div>

      {Array.from(peers.entries()).map(([peerId, peer]) => (
        <div key={peerId}>
          <h3>Peer {peerId}</h3>
          <video
            ref={(video) => {
              if (video) {
                peer.on('stream', (stream) => {
                  video.srcObject = stream
                })
              }
            }}
            autoPlay
            playsInline
            className="w-full rounded"
          />
        </div>
      ))}
    </div>
  )
}
```

## Presence Indicators

```typescript
'use client'

import { useEffect, useState } from 'react'
import { useSocket } from '@/hooks/useSocket'

interface User {
  id: string
  name: string
  status: 'online' | 'away' | 'offline'
  lastSeen?: Date
}

export function PresenceIndicator({ roomId }: { roomId: string }) {
  const { socket } = useSocket()
  const [users, setUsers] = useState<User[]>([])

  useEffect(() => {
    if (!socket) return

    socket.emit('join-presence', roomId)

    socket.on('presence-update', (updatedUsers: User[]) => {
      setUsers(updatedUsers)
    })

    // Send heartbeat every 30 seconds
    const heartbeat = setInterval(() => {
      socket.emit('heartbeat', roomId)
    }, 30000)

    return () => {
      clearInterval(heartbeat)
      socket.emit('leave-presence', roomId)
      socket.off('presence-update')
    }
  }, [socket, roomId])

  return (
    <div className="space-y-2">
      <h3 className="font-bold">Online Users ({users.length})</h3>
      {users.map((user) => (
        <div key={user.id} className="flex items-center gap-2">
          <div
            className={`w-3 h-3 rounded-full ${
              user.status === 'online'
                ? 'bg-green-500'
                : user.status === 'away'
                ? 'bg-yellow-500'
                : 'bg-gray-500'
            }`}
          />
          <span>{user.name}</span>
          {user.status === 'offline' && user.lastSeen && (
            <span className="text-xs text-gray-500">
              Last seen {new Date(user.lastSeen).toLocaleTimeString()}
            </span>
          )}
        </div>
      ))}
    </div>
  )
}
```

## Collaborative Editing (Basic)

```typescript
'use client'

import { useState, useEffect } from 'react'
import { useSocket } from '@/hooks/useSocket'

export function CollaborativeEditor({ documentId }: { documentId: string }) {
  const { socket } = useSocket()
  const [content, setContent] = useState('')
  const [cursors, setCursors] = useState<Map<string, number>>(new Map())

  useEffect(() => {
    if (!socket) return

    socket.emit('join-document', documentId)

    // Receive initial content
    socket.on('document-content', (initialContent: string) => {
      setContent(initialContent)
    })

    // Receive updates
    socket.on('content-update', ({ content: newContent }: { content: string }) => {
      setContent(newContent)
    })

    // Receive cursor positions
    socket.on('cursor-update', ({ userId, position }: { userId: string; position: number }) => {
      setCursors((prev) => new Map(prev).set(userId, position))
    })

    return () => {
      socket.emit('leave-document', documentId)
      socket.off('document-content')
      socket.off('content-update')
      socket.off('cursor-update')
    }
  }, [socket, documentId])

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const newContent = e.target.value
    setContent(newContent)

    if (socket) {
      socket.emit('content-change', {
        documentId,
        content: newContent
      })
    }
  }

  const handleCursorMove = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const position = e.target.selectionStart

    if (socket) {
      socket.emit('cursor-move', {
        documentId,
        position
      })
    }
  }

  return (
    <div>
      <textarea
        value={content}
        onChange={handleChange}
        onSelect={handleCursorMove}
        className="w-full h-96 p-4 border rounded font-mono"
        placeholder="Start typing..."
      />
      <div className="mt-2 text-sm text-gray-500">
        {cursors.size} other user{cursors.size !== 1 ? 's' : ''} editing
      </div>
    </div>
  )
}
```

## Best Practices Checklist

### Connection Management
- [ ] Implement auto-reconnection
- [ ] Handle connection errors gracefully
- [ ] Show connection status to users
- [ ] Implement heartbeat/ping-pong
- [ ] Clean up connections on unmount

### Performance
- [ ] Throttle/debounce frequent events
- [ ] Use rooms/namespaces for isolation
- [ ] Implement message queuing
- [ ] Compress large payloads
- [ ] Limit broadcast recipients

### Security
- [ ] Authenticate WebSocket connections
- [ ] Validate all incoming messages
- [ ] Implement rate limiting
- [ ] Use HTTPS/WSS in production
- [ ] Sanitize user-generated content

### Scalability
- [ ] Use Redis adapter for multiple servers
- [ ] Implement horizontal scaling
- [ ] Monitor connection counts
- [ ] Set connection limits
- [ ] Use load balancing

## Resources

- [Socket.io Documentation](https://socket.io/docs/)
- [Server-Sent Events Spec](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [WebRTC Documentation](https://webrtc.org/)
- [Simple Peer](https://github.com/feross/simple-peer)

---

**Remember**: Real-time features require careful planning. Handle disconnections. Optimize for performance. Secure connections. Test with multiple clients.
