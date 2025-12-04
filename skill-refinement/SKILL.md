# Skill Refinement System

> **Version:** 1.0.0
> **Purpose:** Capture, apply, and generalize skill refinements across projects
> **Scope:** Standalone skill working across all Claude Skills

---

## Overview

The Skill Refinement System enables:
- **Project-level overrides** via section patches, extensions, and configs
- **User-scope logging** for pattern tracking across projects
- **Auto-generalization** when patterns appear in 2+ projects
- **Dual persistence** via file system and Zen MCP

---

## Triggers

### Primary Commands
- `/refine-skills` - Main refinement capture workflow
- `/apply-generalization` - Apply queued generalizations to user-scope skills
- `/review-patterns` - Review tracked patterns and generalization queue

### Auto-Detection Keywords
The system activates when detecting:
```
skill doesn't work, skill should have, missing trigger
should have caught, why didn't skill, skill broke
improve skill, extend skill, add to skill
skill missed, false positive, false negative
```

### Session-End Hook
Prompts for refinements after significant sessions (>20 tool calls, errors, or >1 hour duration).

---

## Override System

### Priority Order
```
1. PROJECT LOCAL     ./.claude/skills/[skill]/     Highest priority
2. PROJECT SHARED    ./skills/[skill]/             Team-shared (git tracked)
3. USER SCOPE        ~/claude-skills/[skill]/      Generalized defaults
```

### Override Types

| Type | File | Use When |
|------|------|----------|
| **Section Patch** | `SKILL.patch.md` | Targeted fixes to specific sections |
| **Extension** | `SKILL.extend.md` | Adding new patterns/triggers |
| **Config Override** | `skill-config.json` | Environment-specific settings |
| **Full Override** | `SKILL.md` | Major divergence from base skill |
| **Hook Override** | `hooks/[name].sh` | Hook behavior changes |
| **Script Override** | `scripts/[name].py` | Script behavior changes |

### Patch Actions

| Action | Syntax | Behavior |
|--------|--------|----------|
| `append` | `<!-- ACTION: append -->` | Add to end of section |
| `prepend` | `<!-- ACTION: prepend -->` | Add to start of section |
| `replace-section` | `<!-- ACTION: replace-section "NAME" -->` | Replace named subsection |
| `insert-after` | `<!-- ACTION: insert-after "MARKER" -->` | Insert after marker text |
| `insert-before` | `<!-- ACTION: insert-before "MARKER" -->` | Insert before marker text |
| `delete-section` | `<!-- ACTION: delete-section "NAME" -->` | Remove named subsection |

---

## Workflow

### Refinement Capture Flow

```
1. IDENTIFY TARGET
   → Auto-detect from context OR user specifies
   → Categorize: trigger | content | hook | tool | pattern | config | new

2. GATHER CONTEXT (Automated)
   → Session history, tool calls, errors
   → Current skill configs, git status
   → Similar past refinements

3. CAPTURE USER INSIGHT
   → Expected vs actual behavior
   → Specific examples
   → Desired outcome
   → [GUIDED MODE if ambiguous]

4. ANALYZE & PROPOSE
   → Root cause identification
   → Override type recommendation
   → Generated patch preview
   → Generalization potential

5. USER CONFIRMATION
   → Review proposed changes
   → Apply / Modify / Cancel

6. APPLY REFINEMENT
   → Create project-scope files
   → Log to user-scope
   → Track pattern frequency
   → Trigger generalization if threshold met
```

---

## Output Format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Skill Refinement: [skill-name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Category: [trigger|content|hook|tool|pattern|config]
🎯 Target: [specific section/file]
📊 Override Type: [patch|extend|config|full]

📝 Summary:
  [Brief description of the refinement]

📄 Changes:
  ┌─ .claude/skills/[skill]/SKILL.patch.md ─────────────
  │ + [added lines]
  │ - [removed lines]
  └─────────────────────────────────────────────────────

🔮 Generalization:
  Potential: [high|medium|low]
  Pattern matches: [N] previous refinement(s)

✅ Applied Successfully

💡 Next Steps:
  1. Test the refinement with: [specific test scenario]
  2. Run /done to validate before committing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## User-Scope Structure

```
~/.claude/skill-refinements/
├── suggested-refinements.md          # Active suggestions (pending review)
├── refinement-history/               # Applied refinements by date
│   └── YYYY-MM-DD-[skill]-[type].md
├── aggregated-patterns.md            # Cross-project pattern tracking
├── generalization-queue.md           # Ready for user-scope merge
└── .zen-sync                         # Zen MCP sync status
```

---

## MCP Integration

### Required
- **Desktop Commander**: Tool call history, file operations

### Optional (Enhanced Features)
- **Sentry**: Error context for pattern detection
- **Zen MCP**: Cross-project pattern persistence
- **Git**: Change tracking via bash

---

## Commands

### /refine-skills
Main refinement capture workflow. See `commands/refine-skills.md`

### /apply-generalization [PATTERN-ID]
Apply a queued generalization to user-scope skills. See `commands/apply-generalization.md`

### /review-patterns
Review tracked patterns and generalization queue. See `commands/review-patterns.md`

---

## Hooks

### refinement-detector.sh
Detects refinement opportunities from user prompts.

### session-end.sh
Prompts for refinements after significant sessions.

---

## References

- `references/override-types.md` - Detailed override type documentation
- `references/patch-syntax.md` - Patch action syntax reference
- `references/generalization-criteria.md` - When and how to generalize

---

## Related Skills

- **context-engineering**: Session management, memory lifecycle
- **error-lifecycle-management**: Error patterns, validation
- **dev-flow-foundations**: Anti-patterns, regression prevention
