---
name: software-architecture
description: Use this skill for software architecture, design patterns, SOLID principles, Clean Architecture, microservices, DDD, API design, system design, and architectural best practices (2026).
origin: Custom
---

# Software Architecture & Design Patterns Skill

Comprehensive guide for software architecture and design patterns (Updated May 2026).

## When to Activate

- Designing system architecture
- Implementing design patterns
- Refactoring legacy code
- Planning microservices
- Designing APIs
- Applying SOLID principles
- Domain-Driven Design (DDD)
- Scaling applications
- Code organization

## SOLID Principles

### Single Responsibility Principle (SRP)
**A class should have only one reason to change.**

```typescript
// ❌ Bad: Multiple responsibilities
class User {
  constructor(public name: string, public email: string) {}
  
  save() {
    // Database logic
    db.users.insert(this)
  }
  
  sendEmail(message: string) {
    // Email logic
    emailService.send(this.email, message)
  }
  
  generateReport() {
    // Report logic
    return `Report for ${this.name}`
  }
}

// ✅ Good: Single responsibility
class User {
  constructor(public name: string, public email: string) {}
}

class UserRepository {
  save(user: User) {
    db.users.insert(user)
  }
  
  findById(id: string): User | null {
    return db.users.findOne({ id })
  }
}

class EmailService {
  sendToUser(user: User, message: string) {
    this.send(user.email, message)
  }
  
  private send(email: string, message: string) {
    // Email logic
  }
}

class UserReportGenerator {
  generate(user: User): string {
    return `Report for ${user.name}`
  }
}
```

### Open/Closed Principle (OCP)
**Open for extension, closed for modification.**

```typescript
// ❌ Bad: Need to modify class to add new payment methods
class PaymentProcessor {
  process(type: string, amount: number) {
    if (type === 'credit_card') {
      // Process credit card
    } else if (type === 'paypal') {
      // Process PayPal
    } else if (type === 'crypto') {
      // Process crypto
    }
  }
}

// ✅ Good: Extend without modifying
interface PaymentMethod {
  process(amount: number): Promise<PaymentResult>
}

class CreditCardPayment implements PaymentMethod {
  async process(amount: number): Promise<PaymentResult> {
    // Credit card logic
    return { success: true, transactionId: '123' }
  }
}

class PayPalPayment implements PaymentMethod {
  async process(amount: number): Promise<PaymentResult> {
    // PayPal logic
    return { success: true, transactionId: '456' }
  }
}

class CryptoPayment implements PaymentMethod {
  async process(amount: number): Promise<PaymentResult> {
    // Crypto logic
    return { success: true, transactionId: '789' }
  }
}

class PaymentProcessor {
  constructor(private paymentMethod: PaymentMethod) {}
  
  async process(amount: number): Promise<PaymentResult> {
    return this.paymentMethod.process(amount)
  }
}

// Usage
const processor = new PaymentProcessor(new CreditCardPayment())
await processor.process(100)
```

### Liskov Substitution Principle (LSP)
**Subtypes must be substitutable for their base types.**

```typescript
// ❌ Bad: Square violates LSP
class Rectangle {
  constructor(protected width: number, protected height: number) {}
  
  setWidth(width: number) {
    this.width = width
  }
  
  setHeight(height: number) {
    this.height = height
  }
  
  getArea(): number {
    return this.width * this.height
  }
}

class Square extends Rectangle {
  setWidth(width: number) {
    this.width = width
    this.height = width // Violates LSP
  }
  
  setHeight(height: number) {
    this.width = height
    this.height = height // Violates LSP
  }
}

// ✅ Good: Use composition
interface Shape {
  getArea(): number
}

class Rectangle implements Shape {
  constructor(private width: number, private height: number) {}
  
  getArea(): number {
    return this.width * this.height
  }
}

class Square implements Shape {
  constructor(private side: number) {}
  
  getArea(): number {
    return this.side * this.side
  }
}
```

### Interface Segregation Principle (ISP)
**Clients should not depend on interfaces they don't use.**

```typescript
// ❌ Bad: Fat interface
interface Worker {
  work(): void
  eat(): void
  sleep(): void
}

class Human implements Worker {
  work() { console.log('Working') }
  eat() { console.log('Eating') }
  sleep() { console.log('Sleeping') }
}

class Robot implements Worker {
  work() { console.log('Working') }
  eat() { throw new Error('Robots don\'t eat') } // Problem!
  sleep() { throw new Error('Robots don\'t sleep') } // Problem!
}

// ✅ Good: Segregated interfaces
interface Workable {
  work(): void
}

interface Eatable {
  eat(): void
}

interface Sleepable {
  sleep(): void
}

class Human implements Workable, Eatable, Sleepable {
  work() { console.log('Working') }
  eat() { console.log('Eating') }
  sleep() { console.log('Sleeping') }
}

class Robot implements Workable {
  work() { console.log('Working') }
}
```

### Dependency Inversion Principle (DIP)
**Depend on abstractions, not concretions.**

```typescript
// ❌ Bad: High-level depends on low-level
class MySQLDatabase {
  save(data: any) {
    console.log('Saving to MySQL')
  }
}

class UserService {
  private db = new MySQLDatabase() // Tight coupling
  
  createUser(user: User) {
    this.db.save(user)
  }
}

// ✅ Good: Depend on abstraction
interface Database {
  save(data: any): Promise<void>
  find(id: string): Promise<any>
}

class MySQLDatabase implements Database {
  async save(data: any) {
    console.log('Saving to MySQL')
  }
  
  async find(id: string) {
    return { id, name: 'John' }
  }
}

class MongoDatabase implements Database {
  async save(data: any) {
    console.log('Saving to MongoDB')
  }
  
  async find(id: string) {
    return { id, name: 'John' }
  }
}

class UserService {
  constructor(private db: Database) {} // Dependency injection
  
  async createUser(user: User) {
    await this.db.save(user)
  }
}

// Usage
const userService = new UserService(new MySQLDatabase())
// Easy to switch: new UserService(new MongoDatabase())
```

## Design Patterns

### Creational Patterns

#### Factory Pattern
```typescript
interface Product {
  operation(): string
}

class ConcreteProductA implements Product {
  operation(): string {
    return 'Product A'
  }
}

class ConcreteProductB implements Product {
  operation(): string {
    return 'Product B'
  }
}

class ProductFactory {
  static create(type: 'A' | 'B'): Product {
    switch (type) {
      case 'A':
        return new ConcreteProductA()
      case 'B':
        return new ConcreteProductB()
      default:
        throw new Error('Unknown product type')
    }
  }
}

// Usage
const product = ProductFactory.create('A')
console.log(product.operation())
```

#### Singleton Pattern
```typescript
class Database {
  private static instance: Database
  private connection: any
  
  private constructor() {
    // Private constructor prevents direct instantiation
    this.connection = this.connect()
  }
  
  static getInstance(): Database {
    if (!Database.instance) {
      Database.instance = new Database()
    }
    return Database.instance
  }
  
  private connect() {
    console.log('Connecting to database...')
    return { connected: true }
  }
  
  query(sql: string) {
    console.log(`Executing: ${sql}`)
  }
}

// Usage
const db1 = Database.getInstance()
const db2 = Database.getInstance()
console.log(db1 === db2) // true - same instance
```

#### Builder Pattern
```typescript
class User {
  constructor(
    public name: string,
    public email: string,
    public age?: number,
    public address?: string,
    public phone?: string
  ) {}
}

class UserBuilder {
  private name: string = ''
  private email: string = ''
  private age?: number
  private address?: string
  private phone?: string
  
  setName(name: string): this {
    this.name = name
    return this
  }
  
  setEmail(email: string): this {
    this.email = email
    return this
  }
  
  setAge(age: number): this {
    this.age = age
    return this
  }
  
  setAddress(address: string): this {
    this.address = address
    return this
  }
  
  setPhone(phone: string): this {
    this.phone = phone
    return this
  }
  
  build(): User {
    return new User(this.name, this.email, this.age, this.address, this.phone)
  }
}

// Usage
const user = new UserBuilder()
  .setName('John Doe')
  .setEmail('john@example.com')
  .setAge(30)
  .build()
```

### Structural Patterns

#### Adapter Pattern
```typescript
// Old interface
class OldPaymentSystem {
  processPayment(amount: number) {
    console.log(`Processing ${amount} via old system`)
  }
}

// New interface
interface PaymentProcessor {
  pay(amount: number, currency: string): void
}

// Adapter
class PaymentAdapter implements PaymentProcessor {
  constructor(private oldSystem: OldPaymentSystem) {}
  
  pay(amount: number, currency: string): void {
    // Convert new interface to old interface
    console.log(`Currency: ${currency}`)
    this.oldSystem.processPayment(amount)
  }
}

// Usage
const oldSystem = new OldPaymentSystem()
const adapter = new PaymentAdapter(oldSystem)
adapter.pay(100, 'USD')
```

#### Decorator Pattern
```typescript
interface Coffee {
  cost(): number
  description(): string
}

class SimpleCoffee implements Coffee {
  cost(): number {
    return 5
  }
  
  description(): string {
    return 'Simple coffee'
  }
}

class MilkDecorator implements Coffee {
  constructor(private coffee: Coffee) {}
  
  cost(): number {
    return this.coffee.cost() + 2
  }
  
  description(): string {
    return this.coffee.description() + ', milk'
  }
}

class SugarDecorator implements Coffee {
  constructor(private coffee: Coffee) {}
  
  cost(): number {
    return this.coffee.cost() + 1
  }
  
  description(): string {
    return this.coffee.description() + ', sugar'
  }
}

// Usage
let coffee: Coffee = new SimpleCoffee()
console.log(coffee.description(), coffee.cost()) // Simple coffee 5

coffee = new MilkDecorator(coffee)
console.log(coffee.description(), coffee.cost()) // Simple coffee, milk 7

coffee = new SugarDecorator(coffee)
console.log(coffee.description(), coffee.cost()) // Simple coffee, milk, sugar 8
```

### Behavioral Patterns

#### Strategy Pattern
```typescript
interface SortStrategy {
  sort(data: number[]): number[]
}

class BubbleSort implements SortStrategy {
  sort(data: number[]): number[] {
    console.log('Sorting using bubble sort')
    return data.sort((a, b) => a - b)
  }
}

class QuickSort implements SortStrategy {
  sort(data: number[]): number[] {
    console.log('Sorting using quick sort')
    return data.sort((a, b) => a - b)
  }
}

class Sorter {
  constructor(private strategy: SortStrategy) {}
  
  setStrategy(strategy: SortStrategy) {
    this.strategy = strategy
  }
  
  sort(data: number[]): number[] {
    return this.strategy.sort(data)
  }
}

// Usage
const sorter = new Sorter(new BubbleSort())
sorter.sort([3, 1, 4, 1, 5])

sorter.setStrategy(new QuickSort())
sorter.sort([3, 1, 4, 1, 5])
```

#### Observer Pattern
```typescript
interface Observer {
  update(data: any): void
}

class Subject {
  private observers: Observer[] = []
  
  attach(observer: Observer): void {
    this.observers.push(observer)
  }
  
  detach(observer: Observer): void {
    const index = this.observers.indexOf(observer)
    if (index > -1) {
      this.observers.splice(index, 1)
    }
  }
  
  notify(data: any): void {
    for (const observer of this.observers) {
      observer.update(data)
    }
  }
}

class EmailNotifier implements Observer {
  update(data: any): void {
    console.log('Sending email notification:', data)
  }
}

class SMSNotifier implements Observer {
  update(data: any): void {
    console.log('Sending SMS notification:', data)
  }
}

// Usage
const subject = new Subject()
const emailNotifier = new EmailNotifier()
const smsNotifier = new SMSNotifier()

subject.attach(emailNotifier)
subject.attach(smsNotifier)

subject.notify({ message: 'New order received' })
```

#### Repository Pattern
```typescript
interface Repository<T> {
  findById(id: string): Promise<T | null>
  findAll(): Promise<T[]>
  create(item: T): Promise<T>
  update(id: string, item: Partial<T>): Promise<T>
  delete(id: string): Promise<void>
}

class UserRepository implements Repository<User> {
  constructor(private db: Database) {}
  
  async findById(id: string): Promise<User | null> {
    return this.db.users.findUnique({ where: { id } })
  }
  
  async findAll(): Promise<User[]> {
    return this.db.users.findMany()
  }
  
  async create(user: User): Promise<User> {
    return this.db.users.create({ data: user })
  }
  
  async update(id: string, data: Partial<User>): Promise<User> {
    return this.db.users.update({ where: { id }, data })
  }
  
  async delete(id: string): Promise<void> {
    await this.db.users.delete({ where: { id } })
  }
}
```

## Clean Architecture

### Layers

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│    (Controllers, UI Components)     │
├─────────────────────────────────────┤
│         Application Layer           │
│      (Use Cases, Services)          │
├─────────────────────────────────────┤
│          Domain Layer               │
│    (Entities, Business Logic)       │
├─────────────────────────────────────┤
│       Infrastructure Layer          │
│  (Database, External APIs, etc.)    │
└─────────────────────────────────────┘
```

### Implementation

```typescript
// Domain Layer - Entities
class User {
  constructor(
    public readonly id: string,
    public name: string,
    public email: string
  ) {}
  
  changeName(newName: string): void {
    if (!newName || newName.length < 2) {
      throw new Error('Invalid name')
    }
    this.name = newName
  }
}

// Domain Layer - Repository Interface
interface IUserRepository {
  findById(id: string): Promise<User | null>
  save(user: User): Promise<void>
}

// Application Layer - Use Case
class UpdateUserNameUseCase {
  constructor(private userRepository: IUserRepository) {}
  
  async execute(userId: string, newName: string): Promise<void> {
    const user = await this.userRepository.findById(userId)
    
    if (!user) {
      throw new Error('User not found')
    }
    
    user.changeName(newName)
    await this.userRepository.save(user)
  }
}

// Infrastructure Layer - Repository Implementation
class PrismaUserRepository implements IUserRepository {
  constructor(private prisma: PrismaClient) {}
  
  async findById(id: string): Promise<User | null> {
    const userData = await this.prisma.user.findUnique({ where: { id } })
    if (!userData) return null
    return new User(userData.id, userData.name, userData.email)
  }
  
  async save(user: User): Promise<void> {
    await this.prisma.user.update({
      where: { id: user.id },
      data: { name: user.name, email: user.email }
    })
  }
}

// Presentation Layer - Controller
class UserController {
  constructor(private updateUserNameUseCase: UpdateUserNameUseCase) {}
  
  async updateName(req: Request, res: Response) {
    try {
      const { userId, newName } = req.body
      await this.updateUserNameUseCase.execute(userId, newName)
      res.json({ success: true })
    } catch (error) {
      res.status(400).json({ error: error.message })
    }
  }
}

// Dependency Injection
const prisma = new PrismaClient()
const userRepository = new PrismaUserRepository(prisma)
const updateUserNameUseCase = new UpdateUserNameUseCase(userRepository)
const userController = new UserController(updateUserNameUseCase)
```

## Microservices Architecture

### Service Structure

```typescript
// User Service
class UserService {
  constructor(
    private userRepository: UserRepository,
    private eventBus: EventBus
  ) {}
  
  async createUser(data: CreateUserDTO): Promise<User> {
    const user = await this.userRepository.create(data)
    
    // Publish event for other services
    await this.eventBus.publish('user.created', {
      userId: user.id,
      email: user.email
    })
    
    return user
  }
}

// Order Service (listens to user events)
class OrderService {
  constructor(
    private orderRepository: OrderRepository,
    private eventBus: EventBus
  ) {
    this.subscribeToEvents()
  }
  
  private subscribeToEvents() {
    this.eventBus.subscribe('user.created', async (event) => {
      console.log('New user created:', event.userId)
      // Initialize user's order history
    })
  }
  
  async createOrder(userId: string, items: OrderItem[]): Promise<Order> {
    return this.orderRepository.create({ userId, items })
  }
}
```

### API Gateway Pattern

```typescript
// API Gateway
class APIGateway {
  constructor(
    private userService: UserServiceClient,
    private orderService: OrderServiceClient,
    private paymentService: PaymentServiceClient
  ) {}
  
  async getUserWithOrders(userId: string) {
    // Aggregate data from multiple services
    const [user, orders] = await Promise.all([
      this.userService.getUser(userId),
      this.orderService.getUserOrders(userId)
    ])
    
    return {
      ...user,
      orders
    }
  }
  
  async createOrderWithPayment(userId: string, orderData: any, paymentData: any) {
    // Orchestrate multiple services
    const order = await this.orderService.createOrder(userId, orderData)
    
    try {
      const payment = await this.paymentService.processPayment({
        orderId: order.id,
        ...paymentData
      })
      
      await this.orderService.confirmOrder(order.id)
      
      return { order, payment }
    } catch (error) {
      // Compensating transaction
      await this.orderService.cancelOrder(order.id)
      throw error
    }
  }
}
```

## Domain-Driven Design (DDD)

### Entities and Value Objects

```typescript
// Value Object
class Email {
  private constructor(private readonly value: string) {}
  
  static create(email: string): Email {
    if (!this.isValid(email)) {
      throw new Error('Invalid email')
    }
    return new Email(email)
  }
  
  private static isValid(email: string): boolean {
    return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  }
  
  getValue(): string {
    return this.value
  }
  
  equals(other: Email): boolean {
    return this.value === other.value
  }
}

// Entity
class Order {
  private items: OrderItem[] = []
  private status: OrderStatus = 'pending'
  
  constructor(
    public readonly id: string,
    public readonly customerId: string,
    public readonly createdAt: Date
  ) {}
  
  addItem(product: Product, quantity: number): void {
    if (this.status !== 'pending') {
      throw new Error('Cannot modify confirmed order')
    }
    
    this.items.push(new OrderItem(product, quantity))
  }
  
  confirm(): void {
    if (this.items.length === 0) {
      throw new Error('Cannot confirm empty order')
    }
    
    this.status = 'confirmed'
  }
  
  getTotalAmount(): number {
    return this.items.reduce((sum, item) => sum + item.getTotal(), 0)
  }
}

// Aggregate Root
class Customer {
  private orders: Order[] = []
  
  constructor(
    public readonly id: string,
    public name: string,
    public email: Email
  ) {}
  
  placeOrder(order: Order): void {
    if (order.customerId !== this.id) {
      throw new Error('Order does not belong to this customer')
    }
    
    this.orders.push(order)
  }
  
  getOrders(): Order[] {
    return [...this.orders] // Return copy
  }
}
```

### Domain Services

```typescript
class OrderPricingService {
  calculateTotal(order: Order, discountCode?: string): number {
    let total = order.getTotalAmount()
    
    if (discountCode) {
      const discount = this.getDiscount(discountCode)
      total = total * (1 - discount)
    }
    
    return total
  }
  
  private getDiscount(code: string): number {
    // Business logic for discounts
    const discounts: Record<string, number> = {
      'SAVE10': 0.1,
      'SAVE20': 0.2
    }
    return discounts[code] || 0
  }
}
```

## API Design Best Practices

### RESTful API Design

```typescript
// Good REST API structure
/*
GET    /api/users           - List users
GET    /api/users/:id       - Get user
POST   /api/users           - Create user
PUT    /api/users/:id       - Update user (full)
PATCH  /api/users/:id       - Update user (partial)
DELETE /api/users/:id       - Delete user

GET    /api/users/:id/orders     - Get user's orders
POST   /api/users/:id/orders     - Create order for user
*/

// Versioning
/*
/api/v1/users
/api/v2/users
*/

// Filtering, Sorting, Pagination
/*
GET /api/users?status=active&sort=createdAt:desc&page=1&limit=20
*/
```

### API Response Format

```typescript
// Success response
interface SuccessResponse<T> {
  success: true
  data: T
  meta?: {
    page?: number
    limit?: number
    total?: number
  }
}

// Error response
interface ErrorResponse {
  success: false
  error: {
    code: string
    message: string
    details?: any
  }
}

// Implementation
export async function GET(request: Request) {
  try {
    const users = await getUsers()
    
    return Response.json({
      success: true,
      data: users,
      meta: {
        total: users.length
      }
    } as SuccessResponse<User[]>)
  } catch (error) {
    return Response.json({
      success: false,
      error: {
        code: 'INTERNAL_ERROR',
        message: 'Failed to fetch users'
      }
    } as ErrorResponse, { status: 500 })
  }
}
```

## Project Structure (Clean Architecture)

```
src/
├── domain/                 # Business logic
│   ├── entities/
│   │   ├── User.ts
│   │   └── Order.ts
│   ├── value-objects/
│   │   └── Email.ts
│   ├── repositories/       # Interfaces
│   │   ├── IUserRepository.ts
│   │   └── IOrderRepository.ts
│   └── services/
│       └── OrderPricingService.ts
│
├── application/            # Use cases
│   ├── use-cases/
│   │   ├── CreateUserUseCase.ts
│   │   ├── PlaceOrderUseCase.ts
│   │   └── ProcessPaymentUseCase.ts
│   └── dto/
│       ├── CreateUserDTO.ts
│       └── CreateOrderDTO.ts
│
├── infrastructure/         # External concerns
│   ├── database/
│   │   ├── prisma/
│   │   └── repositories/
│   │       ├── PrismaUserRepository.ts
│   │       └── PrismaOrderRepository.ts
│   ├── external-services/
│   │   ├── StripePaymentService.ts
│   │   └── SendGridEmailService.ts
│   └── config/
│       └── database.ts
│
└── presentation/           # API/UI layer
    ├── api/
    │   ├── controllers/
    │   │   ├── UserController.ts
    │   │   └── OrderController.ts
    │   └── middleware/
    │       ├── auth.ts
    │       └── validation.ts
    └── di/                 # Dependency injection
        └── container.ts
```

## Best Practices Checklist

### Architecture
- [ ] Follow SOLID principles
- [ ] Use dependency injection
- [ ] Separate concerns (layers)
- [ ] Keep business logic in domain layer
- [ ] Use interfaces for abstractions
- [ ] Apply appropriate design patterns

### Code Organization
- [ ] Clear folder structure
- [ ] Consistent naming conventions
- [ ] Small, focused modules
- [ ] Avoid circular dependencies
- [ ] Document architectural decisions

### API Design
- [ ] RESTful conventions
- [ ] Consistent response format
- [ ] Proper HTTP status codes
- [ ] API versioning
- [ ] Clear error messages

### Scalability
- [ ] Stateless services
- [ ] Horizontal scaling ready
- [ ] Caching strategy
- [ ] Database optimization
- [ ] Async processing for heavy tasks

## Resources

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design](https://martinfowler.com/bliki/DomainDrivenDesign.html)
- [Design Patterns](https://refactoring.guru/design-patterns)
- [Microservices Patterns](https://microservices.io/patterns/)
- [REST API Best Practices](https://restfulapi.net/)

---

**Remember**: Good architecture is about making decisions that are easy to change later. Keep it simple. Apply patterns when needed, not because they exist.
