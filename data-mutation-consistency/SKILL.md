# Data Mutation Consistency Skill

> **Status:** Production v2
> **Last Updated:** 2024-12-05
> **Platform:** Vercel + Next.js + Supabase
> **Tools:** Native Claude Code (Grep, Glob, Read, Bash), Task Agents
> **Integration:** Sentry MCP, Zen MCP Memory

---

## Overview

Enforces consistent data mutation patterns across Next.js applications deployed on Vercel with Supabase backends. This skill is **framework-agnostic** for state management libraries and CMS integrations—see sub-skills for specific implementations.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│         DATA MUTATION CONSISTENCY SKILL (Router)                │
│         Platform: Vercel + Next.js + Supabase                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │  react-query-    │  │  payload-cms-    │  │  (planned)     │ │
│  │  mutations       │  │  hooks           │  │  rtk-query     │ │
│  │  Sub-Skill       │  │  Sub-Skill       │  │  sanity-cms    │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│         │                      │                                 │
│         └──────────┬───────────┘                                 │
│                    │                                             │
│         ┌──────────▼───────────┐                                │
│         │  Cross-Layer         │                                │
│         │  Validation          │                                │
│         │  (cache tags ↔ keys) │                                │
│         └──────────────────────┘                                │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Sub-Skills

| Sub-Skill | Use When | Auto-Detect |
|-----------|----------|-------------|
| [react-query-mutations](./sub-skills/react-query-mutations.md) | Project uses TanStack Query / React Query | `@tanstack/react-query` in package.json |
| [payload-cms-hooks](./sub-skills/payload-cms-hooks.md) | Project uses Payload CMS | `payload` in package.json |
| redux-toolkit-mutations | Project uses RTK Query | `@reduxjs/toolkit` (planned) |
| [sanity-cms-hooks](./sub-skills/sanity-cms-hooks.md) | Project uses Sanity CMS | `@sanity/client` in package.json |

Sub-skills are auto-detected from `package.json` by default. Override in project config if needed.

---

## The Problem This Solves

```
Mutation Drift Pattern:
1. Feature A implements mutations with full patterns
2. Feature B copies but omits error handling
3. Feature C adds new table, forgets revalidation
4. Admin changes don't propagate to client cache
5. Data inconsistencies surface in production
6. Debug cycles consume context windows

Target State:
1. New mutation detected → Pattern check triggered
2. Compare against platform standards (Next.js cache, Supabase RLS)
3. Gaps identified with < 9/10 score → Warning issued
4. Analysis written to file, summary in chat
5. Fix suggestions provided, implementation proceeds
6. Consistency maintained across codebase
```

---

## Commands

### Slash Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `/jd:mutation-analyze` | `@analyze-mutations` | Full codebase mutation analysis |
| `/jd:mutation-check [file]` | `@check-mutation` | Single file quick check |
| `/jd:mutation-fix [priority]` | `@fix-mutations` | Generate fix plan for issues |

### Usage Examples

```bash
# Full analysis with dashboard
@analyze-mutations --dashboard

# Check single file
@check-mutation app/actions/players.ts

# Generate fixes for warnings and above
@fix-mutations P1

# Fix and add TODO comments to source
@fix-mutations P1 --add-todos
```

---

## Triggers

### Automatic Detection (UserPromptSubmit Hook)

The skill activates when user mentions mutation-related keywords:
- "stale data", "cache", "not updating", "out of sync"
- "mutation", "revalidate", "invalidate"
- Bug/error keywords combined with data references

**Hook:** `hooks/mutation-detector.sh`

### Pre-Write Validation (PreToolUse Hook)

Before writing/editing mutation files, checks for:
- Missing error handling
- Missing cache revalidation
- Missing type safety

**Hook:** `hooks/prewrite-check.sh`

### Sentry Integration

When debugging stale data issues from Sentry:
1. Skill suggests running `@analyze-mutations`
2. Cross-references error context with mutation analysis
3. Identifies cache/revalidation gaps

---

## Scoring System

### Thresholds

| Score | Status | Action |
|-------|--------|--------|
| ≥ 9.0 | ✅ Passing | No action needed |
| 7.0 - 8.9 | ⚠️ Warning | TODO added, proceed with warning |
| < 7.0 | 🚨 Critical | Immediate attention required |

### Weights Configuration

Scoring weights are configurable in `config/scoring-weights.yaml`:

```yaml
platform:
  error_handling: 1.5      # Required: check for .error
  cache_revalidation: 1.5  # Required: revalidateTag/Path
  type_safety: 1.3         # Required: typed responses
  input_validation: 1.0    # Recommended: Zod/validation

user_experience:
  loading_state: 1.0       # Recommended: isPending handling
  error_feedback: 1.2      # Recommended: toast/error UI
  success_feedback: 0.8    # Optional: confirmation messages
  optimistic_ui: 1.2       # Recommended for user-facing

react_query:
  query_key_factory: 1.5   # Required: use *Keys factories
  optimistic_update: 1.2   # Recommended: setQueryData
  rollback_context: 1.4    # Required if optimistic
  cache_invalidation: 1.4  # Required: invalidateQueries

payload:
  after_change_hook: 1.5   # Required: lifecycle hook
  after_change_cache: 1.5  # Required: revalidation
  after_delete_hook: 1.3   # Required: cleanup hook
  before_change_validation: 1.0  # Recommended
```

---

## Output Strategy

### File-First Approach

All detailed analysis is written to files to minimize context consumption:

```
.claude/
├── analysis/
│   ├── mutation-report-2024-12-05.md    # Full detailed report
│   ├── pending-fixes.md                  # Tracked issues
│   └── fix-plan-2024-12-05.md           # Generated fix plan
└── temp/
    └── (intermediate analysis files)
```

### Chat Response

Chat responses are kept minimal (< 10 lines):

```
## Mutation Analysis Complete

**Overall Score:** 8.2/10 ⚠️

**Stats:** 15 passing, 4 warnings, 1 critical

**Top Issues:**
1. 🚨 Missing error handling (app/actions/players.ts)
2. ⚠️ Missing cache revalidation (app/actions/games.ts)
3. ⚠️ No query key factory (hooks/useUpdateTeam.ts)

📄 Full report: `.claude/analysis/mutation-report-2024-12-05.md`
```

---

## Platform Standards

### Server Actions

```typescript
'use server'

import { revalidatePath, revalidateTag } from 'next/cache';
import { createClient } from '@/lib/supabase/server';

export async function updatePlayer(id: string, data: PlayerUpdate) {
  const supabase = await createClient();

  // ✅ Error handling
  const { data: player, error } = await supabase
    .from('players')
    .update(data)
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;

  // ✅ Cache revalidation
  revalidateTag('players');
  revalidatePath(`/players/${id}`);

  return player;
}
```

### Required Elements

| Element | Requirement | Weight |
|---------|-------------|--------|
| Typed Client | Required | 1.3 |
| Error Handling | Required | 1.5 |
| Cache Revalidation | Required | 1.5 |
| Optimistic UI | Recommended | 1.2 |
| Rollback Logic | Required if optimistic | 1.4 |

See `references/platform-standards.md` for complete patterns.

---

## Cross-Layer Validation

Ensures backend cache tags align with frontend query keys:

```typescript
// Backend (Server Action / Payload)
revalidateTag('players');

// Frontend (React Query)
export const playerKeys = {
  all: ['players'] as const,  // ✅ Matches 'players' tag
  // ...
};
```

Misalignments are detected and reported. See `references/cross-layer-validation.md`.

---

## Enforcement Mode

**Mode: Advisory** (non-blocking)

```yaml
on_violation:
  action: warn
  behavior:
    - Log warning to chat
    - Add TODO comment in generated code
    - Continue with implementation
    - Append to pending-fixes.md
```

### Generated TODO Pattern

```typescript
export async function updatePlayer(id: string, data: PlayerUpdate) {
  // TODO(mutation-consistency): Add revalidateTag('players') after mutation
  // TODO(mutation-consistency): Add error boundary for RLS failures
  // Score: 7.5/10 - See .claude/analysis/mutation-report-2024-12-05.md

  const supabase = await createClient();
  // ... implementation
}
```

---

## Integration Points

### → Sentry MCP

When investigating stale data bugs from Sentry issues:

```bash
# 1. Get issue details
mcp__sentry__get_issue_details(issueUrl='...')

# 2. If stale data related, skill suggests:
@analyze-mutations --focus=[affected-table]

# 3. Cross-reference findings with Sentry context
```

### → Zen MCP Memory

Store analysis results for cross-session awareness:

```bash
# After analysis, store key findings
mcp__zen__chat("Store mutation analysis: Score 8.2/10,
  4 warnings in players mutations,
  missing cache revalidation pattern")

# On future sessions, recall context
mcp__zen__chat("What mutation issues were found previously?")
```

### → Anti-Pattern Agent

Add to deprecated-triggers.ts:

```typescript
'supabase-no-error-check': {
  regex: /const\s*\{\s*data\s*\}\s*=\s*await\s+supabase/,
  replacement: 'const { data, error } = await supabase',
  reason: 'Supabase operations can fail silently',
},

'server-action-no-revalidate': {
  regex: /'use server'[\s\S]*?supabase[\s\S]*?(?:insert|update|delete)(?![\s\S]*?revalidate)/,
  replacement: 'Add revalidateTag or revalidatePath',
  reason: 'Server actions must revalidate cache',
},
```

### → Regression Prevention

When investigating stale data bugs:
1. Run `@analyze-mutations --focus=[affected table]`
2. Check revalidation coverage
3. Verify Supabase RLS isn't blocking
4. Add findings to RCA

---

## Configuration

### Project Override

Create `.claude/mutation-patterns.yaml` in your project:

```yaml
platform:
  deployment: vercel
  framework: nextjs
  database: supabase

sub_skills:
  mode: auto-detect  # auto-detect | manual | disabled
  enabled:
    - react-query-mutations
    - payload-cms-hooks

analysis:
  output_dir: ".claude/analysis"

enforcement:
  mode: advisory
  warning_threshold: 9.0
  critical_threshold: 7.0
  add_todos: true

scoring:
  weights_file: "config/scoring-weights.yaml"

ignore:
  paths:
    - "**/test/**"
    - "**/__mocks__/**"
    - "**/migrations/**"
  patterns:
    - "*.test.ts"
    - "*.spec.ts"
    - "*.d.ts"
```

---

## Directory Structure

```
claude-skill-data-mutation-consistency/
├── SKILL.md                              # This file (router)
├── sub-skills/
│   ├── react-query-mutations.md          # TanStack Query patterns
│   └── payload-cms-hooks.md              # Payload CMS patterns
├── scripts/
│   ├── common/
│   │   ├── __init__.py
│   │   ├── models.py                     # Data models
│   │   ├── patterns.py                   # Pattern detection
│   │   ├── scoring.py                    # Score calculation
│   │   └── output.py                     # Report generation
│   ├── analyze_mutations.py              # Full analysis
│   ├── check_single_file.py              # Single file check
│   └── generate_fixes.py                 # Fix generation
├── hooks/
│   ├── mutation-detector.sh              # UserPromptSubmit
│   └── prewrite-check.sh                 # PreToolUse
├── commands/
│   ├── analyze-mutations.md              # /jd:mutation-analyze
│   ├── check-mutation.md                 # /jd:mutation-check
│   └── fix-mutations.md                  # /jd:mutation-fix
├── config/
│   ├── scoring-weights.yaml              # Configurable weights
│   └── detection-patterns.yaml           # Pattern definitions
├── templates/
│   ├── mutation-report.md.template       # Full report template
│   ├── fix-plan.md.template              # Fix plan template
│   └── quick-summary.md.template         # Chat summary template
└── references/
    ├── IMPLEMENTATION-STRATEGY.md        # Implementation guide
    ├── platform-standards.md             # Vercel/Next/Supabase patterns
    └── cross-layer-validation.md         # Backend ↔ Frontend alignment
```

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│         DATA MUTATION CONSISTENCY (Vercel/Next/Supabase)        │
├─────────────────────────────────────────────────────────────────┤
│  PLATFORM REQUIREMENTS:                                          │
│  ✓ Typed Supabase client (@/lib/supabase)                       │
│  ✓ Error handling (check .error, try/catch)                     │
│  ✓ Cache revalidation (revalidateTag/revalidatePath)            │
│  ✓ Type-safe returns (MutationResult<T>)                        │
├─────────────────────────────────────────────────────────────────┤
│  SUB-SKILLS (auto-detected from package.json):                  │
│  • react-query-mutations - TanStack Query patterns              │
│  • payload-cms-hooks - Payload CMS lifecycle hooks              │
│  • redux-toolkit-mutations - RTK Query (planned)                │
│  • sanity-cms-hooks - Sanity CMS                                │
├─────────────────────────────────────────────────────────────────┤
│  ENFORCEMENT: Advisory (warn + TODO, don't block)               │
│  THRESHOLD: < 9.0 = warning, < 7.0 = critical                   │
├─────────────────────────────────────────────────────────────────┤
│  COMMANDS:                                                       │
│  @analyze-mutations      → Full analysis (output to file)       │
│  @check-mutation [file]  → Single file check                    │
│  @fix-mutations [P0-P2]  → Generate fix plan                    │
├─────────────────────────────────────────────────────────────────┤
│  HOOKS:                                                          │
│  mutation-detector.sh    → Detect mutation keywords             │
│  prewrite-check.sh       → Validate before writing              │
├─────────────────────────────────────────────────────────────────┤
│  INTEGRATIONS:                                                   │
│  Sentry MCP              → Stale data issue detection           │
│  Zen MCP Memory          → Cross-session awareness              │
│  Anti-Pattern Agent      → Real-time pattern enforcement        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| v2 | 2024-12-05 | Full implementation with scripts, hooks, commands |
| v1 | 2024-12-05 | Initial foundation - Vercel/Next.js/Supabase platform |
