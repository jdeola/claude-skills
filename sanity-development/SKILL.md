# Sanity Development Skill v1.0.0

> **Opinionated best practices for Sanity Studio configuration, GROQ queries, and frontend integration**

## Metadata

| Property | Value |
|----------|-------|
| Version | 1.0.0 |
| Created | 2024-12-13 |
| Source | [sanity-io/ai-rules](https://github.com/sanity-io/ai-rules), [Opinionated Guide](https://www.sanity.io/guides/an-opinionated-guide-to-sanity-studio) |
| Scope | User (global) |
| Dependencies | TypeScript, Sanity Studio v3+ |

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│                    SANITY DEVELOPMENT SKILL                      │
├─────────────────────────────────────────────────────────────────┤
│  KNOWLEDGE ROUTER                                                │
│  ├── Schema Design        → ./references/sanity-schema.md       │
│  ├── GROQ Queries         → ./references/sanity-groq.md         │
│  ├── Project Structure    → ./references/sanity-project.md      │
│  ├── Studio Structure     → ./references/sanity-studio.md       │
│  ├── Next.js Integration  → ./references/sanity-nextjs.md       │
│  ├── Visual Editing       → ./references/sanity-visual.md       │
│  ├── Page Builder         → ./references/sanity-pagebuilder.md  │
│  ├── Portable Text        → ./references/sanity-pte.md          │
│  ├── Images               → ./references/sanity-image.md        │
│  └── TypeGen              → ./references/sanity-typegen.md      │
├─────────────────────────────────────────────────────────────────┤
│  CORE PRINCIPLES                                                 │
│  • Model WHAT things ARE, not what they LOOK LIKE               │
│  • Use defineType, defineField, defineArrayMember ALWAYS        │
│  • Named exports only (no default exports)                      │
│  • SCREAMING_SNAKE_CASE for GROQ queries                        │
│  • Clean stega values before logic comparisons                  │
├─────────────────────────────────────────────────────────────────┤
│  COMMANDS                                                        │
│  npx sanity schema deploy    # Deploy schema to Content Lake    │
│  npx sanity typegen generate # Generate TypeScript types        │
│  npx sanity dev              # Start Studio dev server          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Knowledge Router

**BEFORE writing any Sanity code, identify relevant topics and read the corresponding reference file.**

| Topic | Trigger Keywords | Reference File |
|:------|:-----------------|:---------------|
| **Schema** | schema, model, document, field, defineType, validation | `./references/sanity-schema.md` |
| **GROQ** | groq, query, defineQuery, projection, filter, order | `./references/sanity-groq.md` |
| **Project Structure** | structure, monorepo, embedded studio, file naming | `./references/sanity-project.md` |
| **Studio Structure** | desk, sidebar, singleton, grouping, S.structure | `./references/sanity-studio.md` |
| **Next.js** | next.js, app router, server component, defineLive | `./references/sanity-nextjs.md` |
| **Visual Editing** | stega, visual editing, overlay, presentation tool | `./references/sanity-visual.md` |
| **Page Builder** | page builder, pageBuilder, block component, alignment | `./references/sanity-pagebuilder.md` |
| **Portable Text** | portable text, rich text, block content, serializer | `./references/sanity-pte.md` |
| **Images** | image, urlFor, crop, hotspot, lqip | `./references/sanity-image.md` |
| **TypeGen** | typegen, typescript, types, infer, generate | `./references/sanity-typegen.md` |

---

## Core Principles

### 1. Data > Presentation

Model **what things are**, not **what they look like**.

```typescript
// ❌ Bad: Presentation-focused
{ name: 'bigHeroText', type: 'string' }
{ name: 'redButton', type: 'object' }
{ name: 'threeColumnRow', type: 'array' }

// ✅ Good: Data-focused
{ name: 'heroStatement', type: 'string' }
{ name: 'callToAction', type: 'object' }
{ name: 'featuresSection', type: 'array' }
```

### 2. Strict Definition Syntax

**ALWAYS** use helper functions for type safety:

```typescript
import { defineType, defineField, defineArrayMember } from 'sanity'
import { TagIcon } from '@sanity/icons'

export const article = defineType({
  name: 'article',
  title: 'Article',
  type: 'document',
  icon: TagIcon,  // ALWAYS add icons
  fields: [
    defineField({
      name: 'title',
      type: 'string',
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: 'tags',
      type: 'array',
      of: [
        defineArrayMember({ type: 'reference', to: [{ type: 'tag' }] })
      ]
    })
  ]
})
```

### 3. Named Exports Only

```typescript
// ❌ Bad: Default exports cause debugging issues
export default articleType

// ✅ Good: Named exports are explicit
export const articleType = defineType({ ... })
```

### 4. GROQ Query Naming

```typescript
import { defineQuery } from 'groq'  // or 'next-sanity'

// ✅ SCREAMING_SNAKE_CASE for queries
export const POSTS_QUERY = defineQuery(`*[_type == "post"]`)
export const POST_BY_SLUG_QUERY = defineQuery(`*[_type == "post" && slug.current == $slug][0]`)
```

### 5. Clean Stega Before Logic

When Visual Editing is enabled, strings contain invisible characters. Clean them before comparisons:

```typescript
import { stegaClean } from '@sanity/client/stega'

// ❌ Bad: Will fail in Edit Mode
if (align === 'center') { ... }

// ✅ Good: Clean first
const cleanAlign = stegaClean(align)
if (cleanAlign === 'center') { ... }
```

---

## Schema Patterns

### Avoid Booleans → Use String Lists

```typescript
// ❌ Avoid
defineField({ name: 'isInternal', type: 'boolean' })

// ✅ Prefer
defineField({
  name: 'visibility',
  type: 'string',
  options: {
    list: [
      { title: 'Public', value: 'public' },
      { title: 'Internal', value: 'internal' },
      { title: 'Authenticated', value: 'authenticated' }
    ],
    layout: 'radio'
  }
})
```

### Avoid Single References → Use Arrays

```typescript
// ❌ Avoid
defineField({
  name: 'author',
  type: 'reference',
  to: [{ type: 'author' }]
})

// ✅ Prefer (even for single values)
defineField({
  name: 'authors',
  type: 'array',
  of: [defineArrayMember({ type: 'reference', to: [{ type: 'author' }] })],
  validation: (rule) => rule.max(1)  // Limit to 1 if needed
})
```

### Safe Field Deprecation

**NEVER delete fields with production data.** Use the deprecation pattern:

```typescript
defineField({
  name: 'oldTitle',
  title: 'Title (Deprecated)',
  type: 'string',
  deprecated: {
    reason: 'Use "seoTitle" instead. This will be removed in v2.'
  },
  readOnly: true,
  hidden: ({ value }) => value === undefined,
  initialValue: undefined
})
```

---

## GROQ Patterns

### Explicit Projections (No Spreads in Production)

```groq
// ❌ Bad: Over-fetching
*[_type == "post"]{ ... }

// ✅ Good: Explicit fields
*[_type == "post"]{
  _id,
  title,
  "slug": slug.current,
  author->{ name, bio }
}
```

### Filter Nulls, Set Defaults

```groq
// Filter out incomplete documents
*[_type == "post" && defined(slug.current)]

// Set default values with coalesce
*[_type == "post"]{
  "title": coalesce(seoTitle, title, "Untitled"),
  "categories": coalesce(categories[]->{ title }, [])
}
```

### Performance Rules

| Rule | Why |
|------|-----|
| Stack optimizable filters FIRST | `_type`, `defined()`, `_id` use indexes |
| Use `_ref` not `->field` in filters | Avoids expensive joins |
| Order BEFORE slice | `order()[0...N]` not `[0...N] \| order()` |
| Use cursor pagination for deep pages | Avoids sorting entire dataset |

---

## File Structure (Embedded Next.js)

```
project/
├── src/
│   ├── app/
│   │   └── studio/[[...tool]]/page.tsx  # Embedded Studio
│   └── sanity/
│       ├── lib/
│       │   ├── client.ts
│       │   ├── live.ts      # defineLive setup
│       │   └── image.ts     # urlFor helper
│       ├── schemaTypes/
│       │   ├── index.ts
│       │   ├── documents/   # post.ts, author.ts
│       │   ├── objects/     # seo.ts, link.ts
│       │   └── blocks/      # hero.ts, features.ts
│       └── structure/
│           └── index.ts     # Custom desk structure
├── sanity.config.ts
├── sanity.cli.ts
└── sanity-typegen.json
```

---

## Visual Editing Checklist

- [ ] Render `<SanityLive />` in root layout
- [ ] Render `<VisualEditing />` when Draft Mode enabled
- [ ] Set `stega: false` for `generateMetadata` (SEO critical!)
- [ ] Clean stega values before logic comparisons
- [ ] Use `_key` for React keys (never index)

---

## Update Types Workflow

When schema or queries change:

```bash
# 1. Run typegen
npm run typegen

# 2. If types don't update, restart TS server
# VS Code: Cmd+Shift+P → "TypeScript: Restart TS Server"
```

**package.json:**
```json
{
  "scripts": {
    "typegen": "sanity schema extract --path=./schema.json && sanity typegen generate"
  }
}
```

---

## References

Detailed patterns are in `./references/`:

- `sanity-schema.md` - Field types, validation, deprecation
- `sanity-groq.md` - Query optimization, fragments, performance
- `sanity-project.md` - Monorepo vs embedded, file naming
- `sanity-studio.md` - Desk structure, singletons, views
- `sanity-nextjs.md` - defineLive, caching, webhooks
- `sanity-visual.md` - Stega, overlays, presentation tool
- `sanity-pagebuilder.md` - Block components, rendering
- `sanity-pte.md` - Portable Text components, marks
- `sanity-image.md` - urlFor, hotspot, LQIP
- `sanity-typegen.md` - Type generation workflow

---

## Boundaries

### ALWAYS
- Use `defineType`, `defineField`, `defineArrayMember`
- Use `defineQuery` for all GROQ queries
- Add icons to documents and objects
- Set `stega: false` for metadata fetching
- Use `_key` for React keys in arrays
- Run typegen after schema/query changes

### ASK FIRST
- Before modifying `sanity.config.ts`
- Before deleting any schema definition file
- Before changing singleton document IDs

### NEVER
- Hardcode API tokens (use `process.env`)
- Use loose types (`any`) for Sanity content
- Use default exports for schema files
- Use index keys for Sanity arrays
- Let stega strings into `<head>` tags
