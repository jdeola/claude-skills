# Sanity CMS Mutations Sub-Skill

> **Data mutation consistency patterns for `@sanity/client` operations**

## Metadata

| Property | Value |
|----------|-------|
| Version | 1.0.0 |
| Created | 2024-12-13 |
| Parent Skill | data-mutation-consistency |
| Detection | `@sanity/client` in package.json |
| Scope | CMS operations, real-time subscriptions |

---

## Overview

This sub-skill enforces consistent mutation patterns when using Sanity's Content Lake via `@sanity/client`. Unlike React Query or RTK Query which manage frontend cache, Sanity mutations interact directly with the hosted backend.

```
┌─────────────────────────────────────────────────────────────────┐
│                 SANITY MUTATION ARCHITECTURE                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Frontend (Next.js/React)                                       │
│  ├── defineLive() ────────────► Live Content API                │
│  │   └── Auto-revalidation      (Subscriptions)                 │
│  │                                                              │
│  ├── client.create() ─────────► Content Lake                    │
│  ├── client.patch() ──────────► (Direct Mutations)              │
│  └── client.delete() ─────────►                                 │
│                                                                  │
│  Sanity Studio                                                  │
│  └── Real-time collaboration ──► Content Lake                   │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  CACHE INVALIDATION STRATEGIES                                   │
│  ├── defineLive() → Automatic (via Live Content API)            │
│  ├── Webhooks → Tag-based or Path-based revalidation            │
│  └── Manual → revalidateTag() / revalidatePath()                │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Patterns

### 1. Client Configuration

```typescript
// src/sanity/lib/client.ts
import { createClient } from '@sanity/client'

export const client = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,
  apiVersion: '2024-01-01',  // Use dated version
  useCdn: true,              // CDN for reads (default)
  token: process.env.SANITY_API_WRITE_TOKEN,  // Only for mutations
})

// Read-only client for frontend
export const readClient = client.withConfig({
  useCdn: true,
  token: undefined,
})

// Write client for mutations (server-side only)
export const writeClient = client.withConfig({
  useCdn: false,  // Never use CDN for writes
  token: process.env.SANITY_API_WRITE_TOKEN,
})
```

### 2. Document Creation

```typescript
// ✅ Correct: Create with explicit structure
async function createPost(data: CreatePostInput) {
  const doc = await writeClient.create({
    _type: 'post',
    title: data.title,
    slug: { _type: 'slug', current: slugify(data.title) },
    author: { _type: 'reference', _ref: data.authorId },
    publishedAt: new Date().toISOString(),
  })
  
  // Trigger revalidation
  revalidateTag('post')
  
  return doc
}

// ❌ Wrong: Missing _type in nested objects
async function createPostBad(data: CreatePostInput) {
  return writeClient.create({
    _type: 'post',
    title: data.title,
    slug: data.slug,  // Missing { _type: 'slug', current: ... }
    author: data.authorId,  // Missing { _type: 'reference', _ref: ... }
  })
}
```

### 3. Document Patching

```typescript
// ✅ Correct: Atomic patch operations
async function updatePostTitle(id: string, title: string) {
  const result = await writeClient
    .patch(id)
    .set({ title })
    .commit()
  
  revalidateTag(`post:${id}`)
  return result
}

// ✅ Correct: Conditional patch (only if field matches)
async function publishPost(id: string) {
  const result = await writeClient
    .patch(id)
    .ifRevisionId(currentRevision)  // Optimistic locking
    .set({ 
      status: 'published',
      publishedAt: new Date().toISOString()
    })
    .commit()
  
  return result
}

// ✅ Correct: Array operations
async function addTag(postId: string, tagId: string) {
  return writeClient
    .patch(postId)
    .setIfMissing({ tags: [] })
    .append('tags', [{ _type: 'reference', _ref: tagId, _key: nanoid() }])
    .commit()
}

// ✅ Correct: Unset (remove) fields
async function removeFeaturedImage(postId: string) {
  return writeClient
    .patch(postId)
    .unset(['featuredImage'])
    .commit()
}
```

### 4. Transaction Pattern (Multi-Document)

```typescript
// ✅ Correct: Atomic multi-document operations
async function archiveCategory(categoryId: string) {
  const transaction = writeClient.transaction()
  
  // Archive the category
  transaction.patch(categoryId, patch => 
    patch.set({ status: 'archived', archivedAt: new Date().toISOString() })
  )
  
  // Remove category from all posts (batched)
  const posts = await client.fetch(
    `*[_type == "post" && references($categoryId)]._id`,
    { categoryId }
  )
  
  for (const postId of posts) {
    transaction.patch(postId, patch =>
      patch.unset([`categories[_ref == "${categoryId}"]`])
    )
  }
  
  const result = await transaction.commit()
  
  // Revalidate affected resources
  revalidateTag('category')
  revalidateTag('post')
  
  return result
}
```

### 5. Delete Operations

```typescript
// ✅ Correct: Safe delete with reference check
async function deleteAuthor(authorId: string) {
  // Check for references first
  const references = await client.fetch(
    `count(*[references($id)])`,
    { id: authorId }
  )
  
  if (references > 0) {
    throw new Error(`Cannot delete author: ${references} documents reference it`)
  }
  
  await writeClient.delete(authorId)
  revalidateTag('author')
}

// ✅ Correct: Batch delete with GROQ filter
async function deleteOldDrafts() {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  
  await writeClient.delete({
    query: `*[_type == "post" && status == "draft" && _updatedAt < $date]`,
    params: { date: thirtyDaysAgo }
  })
  
  revalidateTag('post')
}
```

---

## Cache Invalidation Strategies

### Strategy 1: Live Content API (Recommended)

Using `defineLive` from `next-sanity` provides automatic cache invalidation:

```typescript
// src/sanity/lib/live.ts
import { defineLive } from 'next-sanity'
import { client } from './client'

export const { sanityFetch, SanityLive } = defineLive({
  client: client.withConfig({ apiVersion: 'v2024-08-01' }),
  serverToken: process.env.SANITY_API_READ_TOKEN,
  browserToken: process.env.SANITY_API_READ_TOKEN,
})
```

**Pros:** Zero-config, automatic updates
**Cons:** Requires tokens, subscription-based

### Strategy 2: Webhook-Based Revalidation

```typescript
// src/app/api/revalidate/route.ts
import { revalidateTag } from 'next/cache'
import { parseBody } from 'next-sanity/webhook'

type WebhookBody = {
  _type: string
  _id: string
  slug?: { current: string }
}

export async function POST(req: Request) {
  const { isValidSignature, body } = await parseBody<WebhookBody>(
    req,
    process.env.SANITY_REVALIDATE_SECRET,
    true  // Add delay for CDN propagation
  )

  if (!isValidSignature) {
    return new Response('Invalid signature', { status: 401 })
  }

  // Revalidate by type and specific document
  revalidateTag(body._type)
  revalidateTag(`${body._type}:${body.slug?.current || body._id}`)

  return Response.json({ revalidated: true })
}
```

**Webhook Configuration (Sanity):**
- Filter: `_type in ["post", "author", "category"]`
- Projection: `{ _type, _id, slug }`

### Strategy 3: Manual Revalidation

```typescript
// After mutation, manually revalidate
async function updatePost(id: string, data: UpdatePostInput) {
  const result = await writeClient.patch(id).set(data).commit()
  
  // Path-based (specific routes)
  revalidatePath(`/posts/${result.slug.current}`)
  revalidatePath('/posts')
  
  // Tag-based (all queries with this tag)
  revalidateTag('post')
  revalidateTag(`post:${result.slug.current}`)
  
  return result
}
```

---

## Real-Time Subscriptions

### Listener Pattern

```typescript
// Subscribe to document changes
const subscription = client
  .listen('*[_type == "post" && _id == $id]', { id: postId })
  .subscribe({
    next: (update) => {
      if (update.type === 'mutation') {
        // Handle update
        console.log('Document updated:', update.result)
      }
    },
    error: (err) => console.error('Subscription error:', err),
  })

// Clean up
subscription.unsubscribe()
```

### React Hook Pattern

```typescript
import { useEffect, useState } from 'react'

function useRealtimePost(postId: string) {
  const [post, setPost] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    // Initial fetch
    client.fetch(`*[_type == "post" && _id == $id][0]`, { id: postId })
      .then(setPost)
      .catch(setError)

    // Subscribe to changes
    const subscription = client
      .listen(`*[_type == "post" && _id == $id]`, { id: postId })
      .subscribe({
        next: (update) => {
          if (update.result) setPost(update.result)
        },
        error: setError,
      })

    return () => subscription.unsubscribe()
  }, [postId])

  return { post, error }
}
```

---

## Consistency Scoring Matrix

| Pattern | Score | Criteria |
|---------|-------|----------|
| **Mutation Structure** | | |
| Uses `_type` in nested objects | +1 | Required for references, slugs |
| Uses `_key` in array items | +1 | Required for Visual Editing |
| Uses `_ref` for references | +1 | Proper reference syntax |
| **Cache Invalidation** | | |
| Triggers revalidation after mutation | +2 | Essential for consistency |
| Uses tag-based revalidation | +1 | Granular control |
| Handles webhook signatures | +1 | Security |
| **Error Handling** | | |
| Checks references before delete | +1 | Prevents orphans |
| Uses transactions for multi-doc ops | +1 | Atomicity |
| Implements optimistic locking | +1 | Conflict prevention |

**Minimum passing score: 7.0 / 10.0**

---

## Anti-Patterns

### ❌ Missing Object Types

```typescript
// ❌ Wrong
client.create({
  _type: 'post',
  slug: 'my-post',  // Should be { _type: 'slug', current: 'my-post' }
})

// ✅ Correct
client.create({
  _type: 'post',
  slug: { _type: 'slug', current: 'my-post' },
})
```

### ❌ CDN for Mutations

```typescript
// ❌ Wrong: CDN can return stale data
const client = createClient({ useCdn: true })
await client.create({ ... })

// ✅ Correct: Bypass CDN for mutations
const writeClient = client.withConfig({ useCdn: false })
await writeClient.create({ ... })
```

### ❌ Missing Array Keys

```typescript
// ❌ Wrong: Array items need _key
patch.append('tags', [{ _type: 'reference', _ref: tagId }])

// ✅ Correct: Include _key
patch.append('tags', [{ _type: 'reference', _ref: tagId, _key: nanoid() }])
```

### ❌ No Revalidation After Mutation

```typescript
// ❌ Wrong: Cache becomes stale
async function updatePost(id, data) {
  return writeClient.patch(id).set(data).commit()
}

// ✅ Correct: Trigger revalidation
async function updatePost(id, data) {
  const result = await writeClient.patch(id).set(data).commit()
  revalidateTag('post')
  return result
}
```

---

## Integration with Parent Skill

This sub-skill integrates with `data-mutation-consistency` for:

1. **Cross-Layer Validation**: Ensures Sanity mutations align with frontend cache expectations
2. **Consistency Scoring**: Contributes to overall mutation health score
3. **Regression Prevention**: Tracks mutation patterns across commits

---

## References

- [Sanity Client Documentation](https://www.sanity.io/docs/js-client)
- [GROQ Mutations](https://www.sanity.io/docs/http-mutations)
- [next-sanity Webhooks](https://github.com/sanity-io/next-sanity#webhook-helpers)
- [Live Content API](https://www.sanity.io/docs/live-content)
