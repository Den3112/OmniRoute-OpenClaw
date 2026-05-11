---
name: ai-ml-integration
description: Use this skill for integrating AI/ML services including OpenAI, Anthropic Claude, LangChain, vector databases, RAG systems, prompt engineering, embeddings, AI-powered features, and LLM best practices (2026).
origin: Custom
---

# AI/ML Integration Skill

Comprehensive guide for integrating AI and Machine Learning into applications (Updated May 2026).

## When to Activate

- Integrating OpenAI, Anthropic, or other LLM APIs
- Building RAG (Retrieval-Augmented Generation) systems
- Implementing vector search and embeddings
- Working with LangChain or similar frameworks
- Creating AI-powered chatbots
- Implementing semantic search
- Building AI agents and workflows
- Prompt engineering and optimization
- Fine-tuning models
- Managing AI costs and rate limits

## LLM API Integration

### OpenAI API (GPT-4, GPT-4 Turbo)
```typescript
import OpenAI from 'openai'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
})

// Chat completion
async function chat(messages: Array<{ role: string; content: string }>) {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4-turbo',
    messages,
    temperature: 0.7,
    max_tokens: 2000,
    stream: false
  })

  return completion.choices[0].message.content
}

// Streaming response
async function chatStream(messages: Array<{ role: string; content: string }>) {
  const stream = await openai.chat.completions.create({
    model: 'gpt-4-turbo',
    messages,
    stream: true
  })

  for await (const chunk of stream) {
    const content = chunk.choices[0]?.delta?.content || ''
    process.stdout.write(content)
  }
}

// Function calling
async function chatWithFunctions(prompt: string) {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4-turbo',
    messages: [{ role: 'user', content: prompt }],
    tools: [
      {
        type: 'function',
        function: {
          name: 'get_weather',
          description: 'Get the current weather in a location',
          parameters: {
            type: 'object',
            properties: {
              location: {
                type: 'string',
                description: 'The city and state, e.g. San Francisco, CA'
              },
              unit: {
                type: 'string',
                enum: ['celsius', 'fahrenheit']
              }
            },
            required: ['location']
          }
        }
      }
    ],
    tool_choice: 'auto'
  })

  const message = completion.choices[0].message

  if (message.tool_calls) {
    for (const toolCall of message.tool_calls) {
      if (toolCall.function.name === 'get_weather') {
        const args = JSON.parse(toolCall.function.arguments)
        const weather = await getWeather(args.location, args.unit)
        
        // Send function result back to model
        const finalCompletion = await openai.chat.completions.create({
          model: 'gpt-4-turbo',
          messages: [
            { role: 'user', content: prompt },
            message,
            {
              role: 'tool',
              tool_call_id: toolCall.id,
              content: JSON.stringify(weather)
            }
          ]
        })

        return finalCompletion.choices[0].message.content
      }
    }
  }

  return message.content
}

// Vision (image understanding)
async function analyzeImage(imageUrl: string, prompt: string) {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4-vision-preview',
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: prompt },
          { type: 'image_url', image_url: { url: imageUrl } }
        ]
      }
    ],
    max_tokens: 1000
  })

  return completion.choices[0].message.content
}
```

### Anthropic Claude API
```typescript
import Anthropic from '@anthropic-ai/sdk'

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY
})

// Chat with Claude
async function chatWithClaude(prompt: string) {
  const message = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 4096,
    messages: [
      { role: 'user', content: prompt }
    ]
  })

  return message.content[0].text
}

// Streaming
async function chatWithClaudeStream(prompt: string) {
  const stream = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 4096,
    messages: [{ role: 'user', content: prompt }],
    stream: true
  })

  for await (const event of stream) {
    if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
      process.stdout.write(event.delta.text)
    }
  }
}

// With system prompt
async function chatWithSystem(systemPrompt: string, userPrompt: string) {
  const message = await anthropic.messages.create({
    model: 'claude-3-opus-20240229',
    max_tokens: 4096,
    system: systemPrompt,
    messages: [
      { role: 'user', content: userPrompt }
    ]
  })

  return message.content[0].text
}
```

### Universal LLM Client (Multi-Provider)
```typescript
interface LLMProvider {
  chat(messages: Message[], options?: ChatOptions): Promise<string>
  stream(messages: Message[], options?: ChatOptions): AsyncGenerator<string>
}

interface Message {
  role: 'system' | 'user' | 'assistant'
  content: string
}

interface ChatOptions {
  temperature?: number
  maxTokens?: number
  model?: string
}

class OpenAIProvider implements LLMProvider {
  constructor(private apiKey: string) {}

  async chat(messages: Message[], options?: ChatOptions): Promise<string> {
    const openai = new OpenAI({ apiKey: this.apiKey })
    const completion = await openai.chat.completions.create({
      model: options?.model || 'gpt-4-turbo',
      messages,
      temperature: options?.temperature || 0.7,
      max_tokens: options?.maxTokens || 2000
    })
    return completion.choices[0].message.content || ''
  }

  async *stream(messages: Message[], options?: ChatOptions): AsyncGenerator<string> {
    const openai = new OpenAI({ apiKey: this.apiKey })
    const stream = await openai.chat.completions.create({
      model: options?.model || 'gpt-4-turbo',
      messages,
      stream: true
    })

    for await (const chunk of stream) {
      yield chunk.choices[0]?.delta?.content || ''
    }
  }
}

class AnthropicProvider implements LLMProvider {
  constructor(private apiKey: string) {}

  async chat(messages: Message[], options?: ChatOptions): Promise<string> {
    const anthropic = new Anthropic({ apiKey: this.apiKey })
    const systemMessage = messages.find(m => m.role === 'system')
    const userMessages = messages.filter(m => m.role !== 'system')

    const response = await anthropic.messages.create({
      model: options?.model || 'claude-3-opus-20240229',
      max_tokens: options?.maxTokens || 4096,
      system: systemMessage?.content,
      messages: userMessages
    })

    return response.content[0].text
  }

  async *stream(messages: Message[], options?: ChatOptions): AsyncGenerator<string> {
    const anthropic = new Anthropic({ apiKey: this.apiKey })
    const systemMessage = messages.find(m => m.role === 'system')
    const userMessages = messages.filter(m => m.role !== 'system')

    const stream = await anthropic.messages.create({
      model: options?.model || 'claude-3-opus-20240229',
      max_tokens: options?.maxTokens || 4096,
      system: systemMessage?.content,
      messages: userMessages,
      stream: true
    })

    for await (const event of stream) {
      if (event.type === 'content_block_delta' && event.delta.type === 'text_delta') {
        yield event.delta.text
      }
    }
  }
}

// Usage
const llm = new OpenAIProvider(process.env.OPENAI_API_KEY!)
// or
const llm = new AnthropicProvider(process.env.ANTHROPIC_API_KEY!)

const response = await llm.chat([
  { role: 'system', content: 'You are a helpful assistant.' },
  { role: 'user', content: 'What is the capital of France?' }
])
```

## Embeddings and Vector Search

### Generate Embeddings
```typescript
// OpenAI Embeddings
async function generateEmbedding(text: string): Promise<number[]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-large',
    input: text
  })

  return response.data[0].embedding
}

// Batch embeddings
async function generateEmbeddings(texts: string[]): Promise<number[][]> {
  const response = await openai.embeddings.create({
    model: 'text-embedding-3-large',
    input: texts
  })

  return response.data.map(item => item.embedding)
}
```

### Vector Database Integration (Pinecone)
```typescript
import { Pinecone } from '@pinecone-database/pinecone'

const pinecone = new Pinecone({
  apiKey: process.env.PINECONE_API_KEY!
})

const index = pinecone.index('my-index')

// Upsert vectors
async function upsertDocuments(documents: Array<{ id: string; text: string; metadata?: any }>) {
  const embeddings = await generateEmbeddings(documents.map(d => d.text))

  await index.upsert(
    documents.map((doc, i) => ({
      id: doc.id,
      values: embeddings[i],
      metadata: {
        text: doc.text,
        ...doc.metadata
      }
    }))
  )
}

// Search similar documents
async function searchSimilar(query: string, topK: number = 5) {
  const queryEmbedding = await generateEmbedding(query)

  const results = await index.query({
    vector: queryEmbedding,
    topK,
    includeMetadata: true
  })

  return results.matches.map(match => ({
    id: match.id,
    score: match.score,
    text: match.metadata?.text,
    metadata: match.metadata
  }))
}
```

### Vector Database Integration (Supabase pgvector)
```typescript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_KEY!
)

// Create table with vector column
/*
CREATE TABLE documents (
  id SERIAL PRIMARY KEY,
  content TEXT,
  embedding VECTOR(1536),
  metadata JSONB
);

CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops);
*/

// Insert document with embedding
async function insertDocument(content: string, metadata?: any) {
  const embedding = await generateEmbedding(content)

  const { data, error } = await supabase
    .from('documents')
    .insert({
      content,
      embedding,
      metadata
    })

  return data
}

// Search similar documents
async function searchDocuments(query: string, limit: number = 5) {
  const queryEmbedding = await generateEmbedding(query)

  const { data, error } = await supabase.rpc('match_documents', {
    query_embedding: queryEmbedding,
    match_threshold: 0.7,
    match_count: limit
  })

  return data
}

// SQL function for similarity search
/*
CREATE OR REPLACE FUNCTION match_documents(
  query_embedding VECTOR(1536),
  match_threshold FLOAT,
  match_count INT
)
RETURNS TABLE (
  id INT,
  content TEXT,
  metadata JSONB,
  similarity FLOAT
)
LANGUAGE SQL STABLE
AS $$
  SELECT
    id,
    content,
    metadata,
    1 - (embedding <=> query_embedding) AS similarity
  FROM documents
  WHERE 1 - (embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
$$;
*/
```

## RAG (Retrieval-Augmented Generation)

### Simple RAG Implementation
```typescript
class RAGSystem {
  constructor(
    private llm: LLMProvider,
    private vectorDB: VectorDatabase
  ) {}

  async query(question: string, context?: string): Promise<string> {
    // 1. Retrieve relevant documents
    const relevantDocs = await this.vectorDB.search(question, 5)

    // 2. Build context from retrieved documents
    const retrievedContext = relevantDocs
      .map((doc, i) => `[${i + 1}] ${doc.text}`)
      .join('\n\n')

    // 3. Generate answer using LLM with context
    const prompt = `
Context information:
${retrievedContext}

${context ? `Additional context: ${context}\n` : ''}
Question: ${question}

Please answer the question based on the context provided above. If the answer cannot be found in the context, say so.
    `.trim()

    const answer = await this.llm.chat([
      { role: 'system', content: 'You are a helpful assistant that answers questions based on provided context.' },
      { role: 'user', content: prompt }
    ])

    return answer
  }

  async ingest(documents: Array<{ id: string; text: string; metadata?: any }>) {
    // Split documents into chunks
    const chunks = documents.flatMap(doc => 
      this.splitIntoChunks(doc.text, 500).map((chunk, i) => ({
        id: `${doc.id}-chunk-${i}`,
        text: chunk,
        metadata: { ...doc.metadata, chunkIndex: i }
      }))
    )

    // Generate embeddings and store
    await this.vectorDB.upsert(chunks)
  }

  private splitIntoChunks(text: string, chunkSize: number): string[] {
    const words = text.split(' ')
    const chunks: string[] = []

    for (let i = 0; i < words.length; i += chunkSize) {
      chunks.push(words.slice(i, i + chunkSize).join(' '))
    }

    return chunks
  }
}

// Usage
const rag = new RAGSystem(llm, vectorDB)

// Ingest documents
await rag.ingest([
  { id: '1', text: 'Paris is the capital of France...', metadata: { source: 'wiki' } },
  { id: '2', text: 'The Eiffel Tower is located in Paris...', metadata: { source: 'wiki' } }
])

// Query
const answer = await rag.query('What is the capital of France?')
```

### Advanced RAG with LangChain
```typescript
import { ChatOpenAI } from '@langchain/openai'
import { OpenAIEmbeddings } from '@langchain/openai'
import { SupabaseVectorStore } from '@langchain/community/vectorstores/supabase'
import { RetrievalQAChain } from 'langchain/chains'
import { RecursiveCharacterTextSplitter } from 'langchain/text_splitter'

// Initialize components
const embeddings = new OpenAIEmbeddings({
  openAIApiKey: process.env.OPENAI_API_KEY
})

const llm = new ChatOpenAI({
  modelName: 'gpt-4-turbo',
  temperature: 0.7
})

const vectorStore = new SupabaseVectorStore(embeddings, {
  client: supabase,
  tableName: 'documents'
})

// Create RAG chain
const chain = RetrievalQAChain.fromLLM(
  llm,
  vectorStore.asRetriever(5)
)

// Ingest documents
async function ingestDocuments(texts: string[]) {
  const splitter = new RecursiveCharacterTextSplitter({
    chunkSize: 1000,
    chunkOverlap: 200
  })

  const docs = await splitter.createDocuments(texts)
  await vectorStore.addDocuments(docs)
}

// Query
const result = await chain.call({
  query: 'What is the capital of France?'
})

console.log(result.text)
```

## AI Agents

### Simple Agent with Tools
```typescript
interface Tool {
  name: string
  description: string
  execute: (input: string) => Promise<string>
}

class AIAgent {
  private tools: Tool[] = []

  constructor(private llm: LLMProvider) {}

  addTool(tool: Tool) {
    this.tools.push(tool)
  }

  async run(task: string, maxIterations: number = 5): Promise<string> {
    let iteration = 0
    let context = ''

    while (iteration < maxIterations) {
      // Ask LLM what to do next
      const prompt = `
You are an AI agent with access to the following tools:

${this.tools.map(t => `- ${t.name}: ${t.description}`).join('\n')}

Task: ${task}

${context ? `Previous actions:\n${context}\n` : ''}

What should you do next? Respond in this format:
THOUGHT: [your reasoning]
ACTION: [tool name]
INPUT: [input for the tool]

Or if the task is complete:
THOUGHT: [your reasoning]
ANSWER: [final answer]
      `.trim()

      const response = await this.llm.chat([
        { role: 'user', content: prompt }
      ])

      // Parse response
      if (response.includes('ANSWER:')) {
        const answer = response.split('ANSWER:')[1].trim()
        return answer
      }

      const thought = response.match(/THOUGHT: (.+)/)?.[1]
      const action = response.match(/ACTION: (.+)/)?.[1]
      const input = response.match(/INPUT: (.+)/)?.[1]

      if (!action || !input) {
        return 'Failed to determine next action'
      }

      // Execute tool
      const tool = this.tools.find(t => t.name === action)
      if (!tool) {
        context += `\nAttempted to use unknown tool: ${action}`
        iteration++
        continue
      }

      const result = await tool.execute(input)
      context += `\nThought: ${thought}\nAction: ${action}\nInput: ${input}\nResult: ${result}`

      iteration++
    }

    return 'Max iterations reached without completing task'
  }
}

// Define tools
const searchTool: Tool = {
  name: 'search',
  description: 'Search the web for information',
  execute: async (query: string) => {
    // Implement web search
    return `Search results for: ${query}`
  }
}

const calculatorTool: Tool = {
  name: 'calculator',
  description: 'Perform mathematical calculations',
  execute: async (expression: string) => {
    try {
      return String(eval(expression))
    } catch (error) {
      return 'Invalid expression'
    }
  }
}

// Usage
const agent = new AIAgent(llm)
agent.addTool(searchTool)
agent.addTool(calculatorTool)

const result = await agent.run('What is the population of Paris multiplied by 2?')
```

## Prompt Engineering

### Prompt Templates
```typescript
class PromptTemplate {
  constructor(private template: string) {}

  format(variables: Record<string, string>): string {
    let result = this.template

    for (const [key, value] of Object.entries(variables)) {
      result = result.replace(new RegExp(`{${key}}`, 'g'), value)
    }

    return result
  }
}

// Usage
const template = new PromptTemplate(`
You are a {role}.

Task: {task}

Context: {context}

Please provide a detailed response.
`)

const prompt = template.format({
  role: 'senior software engineer',
  task: 'Review this code for security issues',
  context: 'This is a payment processing function'
})
```

### Few-Shot Prompting
```typescript
function createFewShotPrompt(
  task: string,
  examples: Array<{ input: string; output: string }>,
  newInput: string
): string {
  const examplesText = examples
    .map(ex => `Input: ${ex.input}\nOutput: ${ex.output}`)
    .join('\n\n')

  return `
Task: ${task}

Examples:
${examplesText}

Now, please complete this:
Input: ${newInput}
Output:
  `.trim()
}

// Usage
const prompt = createFewShotPrompt(
  'Classify sentiment as positive, negative, or neutral',
  [
    { input: 'I love this product!', output: 'positive' },
    { input: 'This is terrible.', output: 'negative' },
    { input: 'It works as expected.', output: 'neutral' }
  ],
  'This is amazing!'
)
```

### Chain of Thought Prompting
```typescript
async function chainOfThought(problem: string): Promise<string> {
  const prompt = `
Let's solve this step by step:

Problem: ${problem}

Please think through this carefully:
1. First, identify what we know
2. Then, determine what we need to find
3. Finally, work through the solution step by step

Show your reasoning at each step.
  `.trim()

  return await llm.chat([
    { role: 'user', content: prompt }
  ])
}
```

## Cost Optimization

### Token Counting
```typescript
import { encoding_for_model } from 'tiktoken'

function countTokens(text: string, model: string = 'gpt-4'): number {
  const encoding = encoding_for_model(model as any)
  const tokens = encoding.encode(text)
  encoding.free()
  return tokens.length
}

// Estimate cost
function estimateCost(
  inputTokens: number,
  outputTokens: number,
  model: string = 'gpt-4-turbo'
): number {
  const pricing = {
    'gpt-4-turbo': { input: 0.01, output: 0.03 }, // per 1K tokens
    'gpt-3.5-turbo': { input: 0.0005, output: 0.0015 },
    'claude-3-opus': { input: 0.015, output: 0.075 }
  }

  const prices = pricing[model] || pricing['gpt-4-turbo']
  
  return (inputTokens / 1000 * prices.input) + (outputTokens / 1000 * prices.output)
}
```

### Response Caching
```typescript
import { createHash } from 'crypto'

class LLMCache {
  private cache = new Map<string, string>()

  private getCacheKey(messages: Message[], options?: ChatOptions): string {
    const data = JSON.stringify({ messages, options })
    return createHash('sha256').update(data).digest('hex')
  }

  async chat(
    llm: LLMProvider,
    messages: Message[],
    options?: ChatOptions
  ): Promise<string> {
    const cacheKey = this.getCacheKey(messages, options)
    
    // Check cache
    const cached = this.cache.get(cacheKey)
    if (cached) {
      console.log('Cache hit!')
      return cached
    }

    // Call LLM
    const response = await llm.chat(messages, options)
    
    // Store in cache
    this.cache.set(cacheKey, response)
    
    return response
  }
}
```

## Streaming Responses in Next.js

### Server-Sent Events (SSE)
```typescript
// app/api/chat/route.ts
import { OpenAIStream, StreamingTextResponse } from 'ai'

export async function POST(req: Request) {
  const { messages } = await req.json()

  const response = await openai.chat.completions.create({
    model: 'gpt-4-turbo',
    messages,
    stream: true
  })

  const stream = OpenAIStream(response)
  
  return new StreamingTextResponse(stream)
}
```

### Client-Side Streaming
```typescript
'use client'

import { useChat } from 'ai/react'

export function ChatComponent() {
  const { messages, input, handleInputChange, handleSubmit, isLoading } = useChat({
    api: '/api/chat'
  })

  return (
    <div>
      <div>
        {messages.map(message => (
          <div key={message.id}>
            <strong>{message.role}:</strong> {message.content}
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit}>
        <input
          value={input}
          onChange={handleInputChange}
          disabled={isLoading}
          placeholder="Type a message..."
        />
        <button type="submit" disabled={isLoading}>
          Send
        </button>
      </form>
    </div>
  )
}
```

## Best Practices

### Error Handling
```typescript
async function safeChat(prompt: string, retries: number = 3): Promise<string> {
  for (let i = 0; i < retries; i++) {
    try {
      return await llm.chat([{ role: 'user', content: prompt }])
    } catch (error: any) {
      // Rate limit error
      if (error.status === 429) {
        const retryAfter = parseInt(error.headers?.['retry-after'] || '60')
        console.log(`Rate limited. Waiting ${retryAfter}s...`)
        await new Promise(resolve => setTimeout(resolve, retryAfter * 1000))
        continue
      }

      // Server error - retry with backoff
      if (error.status >= 500 && i < retries - 1) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000))
        continue
      }

      throw error
    }
  }

  throw new Error('Max retries exceeded')
}
```

### Content Moderation
```typescript
async function moderateContent(text: string): Promise<boolean> {
  const moderation = await openai.moderations.create({
    input: text
  })

  const result = moderation.results[0]
  
  if (result.flagged) {
    console.log('Content flagged:', result.categories)
    return false
  }

  return true
}

// Use before sending to LLM
const userInput = 'User message here'
const isSafe = await moderateContent(userInput)

if (!isSafe) {
  throw new Error('Content violates policy')
}
```

## Best Practices Checklist

- [ ] Implement rate limiting and retry logic
- [ ] Cache responses when appropriate
- [ ] Monitor token usage and costs
- [ ] Use streaming for better UX
- [ ] Implement content moderation
- [ ] Handle errors gracefully
- [ ] Use prompt templates for consistency
- [ ] Validate and sanitize user inputs
- [ ] Log all LLM interactions
- [ ] Set appropriate temperature and max_tokens
- [ ] Use system prompts effectively
- [ ] Test prompts thoroughly
- [ ] Monitor model performance

## Resources

- [OpenAI API Documentation](https://platform.openai.com/docs)
- [Anthropic Claude Documentation](https://docs.anthropic.com/)
- [LangChain Documentation](https://js.langchain.com/)
- [Pinecone Documentation](https://docs.pinecone.io/)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)

---

**Remember**: Monitor costs. Cache responses. Handle errors. Moderate content. Test prompts. Optimize tokens. Stream when possible.
