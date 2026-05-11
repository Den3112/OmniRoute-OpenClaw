---
name: payment-integration
description: Use this skill for integrating payment systems including Stripe, PayPal, cryptocurrency payments, subscription management, webhooks, refunds, invoicing, and PCI compliance (2026).
origin: Custom
---

# Payment Integration Skill

Comprehensive guide for integrating payment systems into applications (Updated May 2026).

## When to Activate

- Integrating Stripe, PayPal, or other payment providers
- Implementing one-time payments
- Setting up subscription billing
- Handling cryptocurrency payments
- Processing refunds and disputes
- Managing invoices
- Implementing webhooks for payment events
- Ensuring PCI compliance
- Testing payment flows
- Handling payment failures

## Payment Providers Comparison

### Stripe (Recommended for most projects)
**Best for:**
- Modern web applications
- Subscription billing
- Global payments
- Developer-friendly API

**Pros:**
- Excellent documentation
- Powerful API
- Built-in fraud detection
- Supports 135+ currencies
- Great developer experience

**Cons:**
- Higher fees (2.9% + $0.30)
- Complex for simple use cases

### PayPal
**Best for:**
- Consumer trust
- International payments
- Existing PayPal users

**Pros:**
- Widely recognized
- Buyer protection
- No monthly fees

**Cons:**
- Higher fees
- Less developer-friendly
- Account holds

### Cryptocurrency (Bitcoin, Ethereum, USDT)
**Best for:**
- Decentralized payments
- Low fees
- International transfers
- Privacy-focused users

**Pros:**
- Low transaction fees
- No chargebacks
- Fast international transfers

**Cons:**
- Price volatility
- Complex for users
- Regulatory uncertainty

## Stripe Integration

### Setup
```bash
npm install stripe @stripe/stripe-js
```

```typescript
// lib/stripe.ts
import Stripe from 'stripe'

export const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, {
  apiVersion: '2024-04-10',
  typescript: true
})
```

### One-Time Payment

#### Create Payment Intent
```typescript
// app/api/create-payment-intent/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'

export async function POST(request: NextRequest) {
  try {
    const { amount, currency = 'usd', metadata } = await request.json()

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount * 100, // Convert to cents
      currency,
      automatic_payment_methods: {
        enabled: true
      },
      metadata
    })

    return NextResponse.json({
      clientSecret: paymentIntent.client_secret
    })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

#### Client-Side Payment Form
```typescript
'use client'

import { useState } from 'react'
import { loadStripe } from '@stripe/stripe-js'
import {
  Elements,
  PaymentElement,
  useStripe,
  useElements
} from '@stripe/react-stripe-js'

const stripePromise = loadStripe(process.env.NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY!)

function CheckoutForm() {
  const stripe = useStripe()
  const elements = useElements()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!stripe || !elements) return

    setLoading(true)
    setError(null)

    try {
      const { error: submitError } = await stripe.confirmPayment({
        elements,
        confirmParams: {
          return_url: `${window.location.origin}/payment/success`
        }
      })

      if (submitError) {
        setError(submitError.message || 'Payment failed')
      }
    } catch (err: any) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <PaymentElement />
      
      {error && (
        <div className="text-red-600 mt-2">{error}</div>
      )}

      <button
        type="submit"
        disabled={!stripe || loading}
        className="mt-4 w-full bg-blue-600 text-white py-2 rounded disabled:opacity-50"
      >
        {loading ? 'Processing...' : 'Pay Now'}
      </button>
    </form>
  )
}

export function PaymentPage({ clientSecret }: { clientSecret: string }) {
  const options = {
    clientSecret,
    appearance: {
      theme: 'stripe' as const
    }
  }

  return (
    <Elements stripe={stripePromise} options={options}>
      <CheckoutForm />
    </Elements>
  )
}
```

### Subscription Billing

#### Create Subscription
```typescript
// app/api/create-subscription/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'

export async function POST(request: NextRequest) {
  try {
    const { customerId, priceId, trialDays } = await request.json()

    const subscription = await stripe.subscriptions.create({
      customer: customerId,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: {
        save_default_payment_method: 'on_subscription'
      },
      expand: ['latest_invoice.payment_intent'],
      ...(trialDays && { trial_period_days: trialDays })
    })

    return NextResponse.json({
      subscriptionId: subscription.id,
      clientSecret: (subscription.latest_invoice as any).payment_intent.client_secret
    })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

#### Manage Subscription
```typescript
// Cancel subscription
async function cancelSubscription(subscriptionId: string) {
  const subscription = await stripe.subscriptions.cancel(subscriptionId)
  return subscription
}

// Update subscription
async function updateSubscription(subscriptionId: string, newPriceId: string) {
  const subscription = await stripe.subscriptions.retrieve(subscriptionId)
  
  const updatedSubscription = await stripe.subscriptions.update(subscriptionId, {
    items: [
      {
        id: subscription.items.data[0].id,
        price: newPriceId
      }
    ],
    proration_behavior: 'create_prorations'
  })

  return updatedSubscription
}

// Pause subscription
async function pauseSubscription(subscriptionId: string) {
  const subscription = await stripe.subscriptions.update(subscriptionId, {
    pause_collection: {
      behavior: 'mark_uncollectible'
    }
  })

  return subscription
}

// Resume subscription
async function resumeSubscription(subscriptionId: string) {
  const subscription = await stripe.subscriptions.update(subscriptionId, {
    pause_collection: null
  })

  return subscription
}
```

### Customer Portal
```typescript
// app/api/create-portal-session/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'

export async function POST(request: NextRequest) {
  try {
    const { customerId } = await request.json()

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard`
    })

    return NextResponse.json({ url: session.url })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

### Webhooks

#### Setup Webhook Handler
```typescript
// app/api/webhooks/stripe/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'
import Stripe from 'stripe'

const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET!

export async function POST(request: NextRequest) {
  const body = await request.text()
  const signature = request.headers.get('stripe-signature')!

  let event: Stripe.Event

  try {
    event = stripe.webhooks.constructEvent(body, signature, webhookSecret)
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err.message)
    return NextResponse.json(
      { error: 'Invalid signature' },
      { status: 400 }
    )
  }

  // Handle different event types
  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSuccess(event.data.object as Stripe.PaymentIntent)
      break

    case 'payment_intent.payment_failed':
      await handlePaymentFailure(event.data.object as Stripe.PaymentIntent)
      break

    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object as Stripe.Subscription)
      break

    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object as Stripe.Subscription)
      break

    case 'customer.subscription.deleted':
      await handleSubscriptionCancelled(event.data.object as Stripe.Subscription)
      break

    case 'invoice.paid':
      await handleInvoicePaid(event.data.object as Stripe.Invoice)
      break

    case 'invoice.payment_failed':
      await handleInvoicePaymentFailed(event.data.object as Stripe.Invoice)
      break

    default:
      console.log(`Unhandled event type: ${event.type}`)
  }

  return NextResponse.json({ received: true })
}

async function handlePaymentSuccess(paymentIntent: Stripe.PaymentIntent) {
  console.log('Payment succeeded:', paymentIntent.id)
  
  // Update database
  await prisma.payment.create({
    data: {
      stripePaymentIntentId: paymentIntent.id,
      amount: paymentIntent.amount / 100,
      currency: paymentIntent.currency,
      status: 'succeeded',
      userId: paymentIntent.metadata.userId
    }
  })

  // Send confirmation email
  await sendPaymentConfirmationEmail(paymentIntent)
}

async function handleSubscriptionCreated(subscription: Stripe.Subscription) {
  console.log('Subscription created:', subscription.id)

  await prisma.subscription.create({
    data: {
      stripeSubscriptionId: subscription.id,
      stripeCustomerId: subscription.customer as string,
      status: subscription.status,
      priceId: subscription.items.data[0].price.id,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      userId: subscription.metadata.userId
    }
  })
}

async function handleSubscriptionCancelled(subscription: Stripe.Subscription) {
  console.log('Subscription cancelled:', subscription.id)

  await prisma.subscription.update({
    where: { stripeSubscriptionId: subscription.id },
    data: {
      status: 'cancelled',
      cancelledAt: new Date()
    }
  })

  // Send cancellation email
  await sendSubscriptionCancelledEmail(subscription)
}
```

### Refunds
```typescript
// app/api/refund/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { stripe } from '@/lib/stripe'

export async function POST(request: NextRequest) {
  try {
    const { paymentIntentId, amount, reason } = await request.json()

    const refund = await stripe.refunds.create({
      payment_intent: paymentIntentId,
      amount: amount ? amount * 100 : undefined, // Partial or full refund
      reason: reason || 'requested_by_customer'
    })

    // Update database
    await prisma.payment.update({
      where: { stripePaymentIntentId: paymentIntentId },
      data: {
        status: 'refunded',
        refundedAt: new Date(),
        refundAmount: refund.amount / 100
      }
    })

    return NextResponse.json({ refund })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

## PayPal Integration

### Setup
```bash
npm install @paypal/checkout-server-sdk
```

```typescript
// lib/paypal.ts
import paypal from '@paypal/checkout-server-sdk'

const environment = process.env.NODE_ENV === 'production'
  ? new paypal.core.LiveEnvironment(
      process.env.PAYPAL_CLIENT_ID!,
      process.env.PAYPAL_CLIENT_SECRET!
    )
  : new paypal.core.SandboxEnvironment(
      process.env.PAYPAL_CLIENT_ID!,
      process.env.PAYPAL_CLIENT_SECRET!
    )

export const paypalClient = new paypal.core.PayPalHttpClient(environment)
```

### Create Order
```typescript
// app/api/paypal/create-order/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { paypalClient } from '@/lib/paypal'
import paypal from '@paypal/checkout-server-sdk'

export async function POST(request: NextRequest) {
  try {
    const { amount, currency = 'USD' } = await request.json()

    const orderRequest = new paypal.orders.OrdersCreateRequest()
    orderRequest.prefer('return=representation')
    orderRequest.requestBody({
      intent: 'CAPTURE',
      purchase_units: [
        {
          amount: {
            currency_code: currency,
            value: amount.toString()
          }
        }
      ]
    })

    const order = await paypalClient.execute(orderRequest)

    return NextResponse.json({
      orderId: order.result.id
    })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

### Capture Payment
```typescript
// app/api/paypal/capture-order/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { paypalClient } from '@/lib/paypal'
import paypal from '@paypal/checkout-server-sdk'

export async function POST(request: NextRequest) {
  try {
    const { orderId } = await request.json()

    const captureRequest = new paypal.orders.OrdersCaptureRequest(orderId)
    captureRequest.requestBody({})

    const capture = await paypalClient.execute(captureRequest)

    // Save to database
    await prisma.payment.create({
      data: {
        paypalOrderId: orderId,
        amount: parseFloat(capture.result.purchase_units[0].amount.value),
        currency: capture.result.purchase_units[0].amount.currency_code,
        status: 'completed'
      }
    })

    return NextResponse.json({ capture: capture.result })
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message },
      { status: 500 }
    )
  }
}
```

### Client-Side PayPal Button
```typescript
'use client'

import { PayPalScriptProvider, PayPalButtons } from '@paypal/react-paypal-js'

export function PayPalCheckout({ amount }: { amount: number }) {
  const createOrder = async () => {
    const response = await fetch('/api/paypal/create-order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ amount })
    })

    const { orderId } = await response.json()
    return orderId
  }

  const onApprove = async (data: any) => {
    const response = await fetch('/api/paypal/capture-order', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ orderId: data.orderID })
    })

    const result = await response.json()
    console.log('Payment successful:', result)
  }

  return (
    <PayPalScriptProvider
      options={{
        clientId: process.env.NEXT_PUBLIC_PAYPAL_CLIENT_ID!,
        currency: 'USD'
      }}
    >
      <PayPalButtons
        createOrder={createOrder}
        onApprove={onApprove}
        style={{ layout: 'vertical' }}
      />
    </PayPalScriptProvider>
  )
}
```

## Cryptocurrency Payments

### Bitcoin/Lightning Network
```typescript
// Using BTCPay Server
import axios from 'axios'

const btcpayClient = axios.create({
  baseURL: process.env.BTCPAY_SERVER_URL,
  headers: {
    'Authorization': `token ${process.env.BTCPAY_API_KEY}`
  }
})

async function createBitcoinInvoice(amount: number, currency: string = 'USD') {
  const response = await btcpayClient.post('/api/v1/invoices', {
    amount,
    currency,
    checkout: {
      speedPolicy: 'MediumSpeed',
      paymentMethods: ['BTC', 'BTC-LightningNetwork']
    }
  })

  return {
    invoiceId: response.data.id,
    checkoutLink: response.data.checkoutLink
  }
}
```

### Ethereum/USDT (Web3)
```typescript
import { ethers } from 'ethers'

// USDT Contract on Ethereum
const USDT_ADDRESS = '0xdac17f958d2ee523a2206206994597c13d831ec7'
const USDT_ABI = [
  'function transfer(address to, uint amount) returns (bool)',
  'function balanceOf(address owner) view returns (uint256)'
]

async function acceptUSDTPayment(
  recipientAddress: string,
  amount: number
) {
  // Connect to wallet (MetaMask)
  const provider = new ethers.BrowserProvider(window.ethereum)
  const signer = await provider.getSigner()

  // Connect to USDT contract
  const usdtContract = new ethers.Contract(USDT_ADDRESS, USDT_ABI, signer)

  // Convert amount to USDT decimals (6)
  const amountInWei = ethers.parseUnits(amount.toString(), 6)

  // Send transaction
  const tx = await usdtContract.transfer(recipientAddress, amountInWei)
  
  // Wait for confirmation
  const receipt = await tx.wait()

  return {
    transactionHash: receipt.hash,
    status: receipt.status === 1 ? 'success' : 'failed'
  }
}
```

### Crypto Payment Component
```typescript
'use client'

import { useState } from 'react'
import { ethers } from 'ethers'

export function CryptoPayment({ amount, recipientAddress }: {
  amount: number
  recipientAddress: string
}) {
  const [loading, setLoading] = useState(false)
  const [txHash, setTxHash] = useState<string | null>(null)

  const handlePayment = async () => {
    if (!window.ethereum) {
      alert('Please install MetaMask')
      return
    }

    setLoading(true)

    try {
      const provider = new ethers.BrowserProvider(window.ethereum)
      await provider.send('eth_requestAccounts', [])
      const signer = await provider.getSigner()

      // Send ETH
      const tx = await signer.sendTransaction({
        to: recipientAddress,
        value: ethers.parseEther(amount.toString())
      })

      const receipt = await tx.wait()
      setTxHash(receipt?.hash || null)

      // Save to database
      await fetch('/api/crypto-payment', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          txHash: receipt?.hash,
          amount,
          currency: 'ETH'
        })
      })
    } catch (error) {
      console.error('Payment failed:', error)
      alert('Payment failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div>
      <button
        onClick={handlePayment}
        disabled={loading}
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        {loading ? 'Processing...' : `Pay ${amount} ETH`}
      </button>

      {txHash && (
        <div className="mt-4">
          <p>Payment successful!</p>
          <a
            href={`https://etherscan.io/tx/${txHash}`}
            target="_blank"
            rel="noopener noreferrer"
            className="text-blue-600 underline"
          >
            View transaction
          </a>
        </div>
      )}
    </div>
  )
}
```

## Testing Payments

### Stripe Test Cards
```typescript
// Test card numbers
const TEST_CARDS = {
  success: '4242424242424242',
  declined: '4000000000000002',
  insufficientFunds: '4000000000009995',
  requiresAuthentication: '4000002500003155'
}

// Test in development
if (process.env.NODE_ENV === 'development') {
  console.log('Use test card:', TEST_CARDS.success)
}
```

### Mock Payment Provider
```typescript
// lib/mock-payment.ts
export class MockPaymentProvider {
  async createPayment(amount: number) {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 1000))

    // Simulate 90% success rate
    if (Math.random() > 0.1) {
      return {
        id: `mock_${Date.now()}`,
        status: 'succeeded',
        amount
      }
    } else {
      throw new Error('Payment failed')
    }
  }
}

// Use in tests
const paymentProvider = process.env.NODE_ENV === 'test'
  ? new MockPaymentProvider()
  : stripe
```

## Security Best Practices

### PCI Compliance
```typescript
// ✅ GOOD: Never store card details
// Use Stripe Elements or PayPal SDK to handle card data

// ❌ BAD: Never do this
const cardNumber = request.body.cardNumber // NEVER!
const cvv = request.body.cvv // NEVER!

// ✅ GOOD: Use tokens
const { token } = await stripe.tokens.create({
  card: {
    number: '4242424242424242',
    exp_month: 12,
    exp_year: 2025,
    cvc: '123'
  }
})
```

### Webhook Security
```typescript
// Always verify webhook signatures
function verifyWebhookSignature(
  payload: string,
  signature: string,
  secret: string
): boolean {
  try {
    stripe.webhooks.constructEvent(payload, signature, secret)
    return true
  } catch (err) {
    return false
  }
}
```

### Idempotency
```typescript
// Prevent duplicate charges
async function createPaymentWithIdempotency(amount: number, idempotencyKey: string) {
  const paymentIntent = await stripe.paymentIntents.create(
    {
      amount: amount * 100,
      currency: 'usd'
    },
    {
      idempotencyKey // Same key = same result
    }
  )

  return paymentIntent
}
```

## Best Practices Checklist

- [ ] Never store card details on your server
- [ ] Always use HTTPS
- [ ] Verify webhook signatures
- [ ] Implement idempotency for payments
- [ ] Handle payment failures gracefully
- [ ] Send payment confirmation emails
- [ ] Log all payment events
- [ ] Test with test cards/accounts
- [ ] Implement retry logic for failed webhooks
- [ ] Monitor payment success rates
- [ ] Handle refunds properly
- [ ] Comply with PCI DSS
- [ ] Display clear pricing
- [ ] Provide receipts/invoices
- [ ] Handle currency conversion

## Resources

- [Stripe Documentation](https://stripe.com/docs)
- [PayPal Developer](https://developer.paypal.com/)
- [BTCPay Server](https://btcpayserver.org/)
- [Ethers.js Documentation](https://docs.ethers.org/)
- [PCI Compliance Guide](https://www.pcisecuritystandards.org/)

---

**Remember**: Security first. Never store card data. Verify webhooks. Test thoroughly. Handle failures gracefully. Comply with regulations.
