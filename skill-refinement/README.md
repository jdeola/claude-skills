# Skill Refinement System

A standalone skill for capturing, applying, and generalizing refinements across the Claude Skills ecosystem.

## Overview

The Skill Refinement System enables:

- **Project-level overrides** via section patches, extensions, and configs
- **User-scope logging** for pattern tracking across projects
- **Auto-generalization** when patterns appear in 2+ projects
- **Dual persistence** via file system and Zen MCP (optional)

## Quick Start

### 1. Capture a Refinement

When a skill doesn't behave as expected:

```
/refine-skills
```

Or the system auto-detects refinement opportunities when you say things like:
- "The skill should have caught this"
- "Why didn't the hook trigger?"
- "I need to extend this skill"

### 2. Review the Proposal

The system will:
1. Identify the target skill and section
2. Gather context from your session
3. Propose a patch or extension
4. Ask for confirmation

### 3. Apply and Track

Once confirmed:
- Project override created in `.claude/skills/[skill]/`
- Refinement logged to `~/.claude/skill-refinements/`
- Pattern tracked for potential generalization

## Directory Structure

### Skill Location
```
claude-skills/skill-refinement/
├── SKILL.md                     # Main router document
├── README.md                    # This file
├── commands/
│   ├── refine-skills.md         # Main refinement command
│   ├── apply-generalization.md  # Apply patterns to user-scope
│   └── review-patterns.md       # Review tracked patterns
├── hooks/                       # (Future: automation hooks)
├── scripts/
│   ├── common/
│   │   ├── __init__.py
│   │   ├── models.py            # Data models
│   │   └── persistence.py       # File + Zen MCP sync
│   └── log_refinement.py        # CLI for logging refinements
├── templates/
│   ├── patch.md.template        # SKILL.patch.md template
│   ├── refinement-entry.md.template
│   └── pattern-entry.md.template
└── references/
    ├── override-types.md        # Override type documentation
    ├── patch-syntax.md          # Patch action reference
    └── generalization-criteria.md
```

### User-Scope Storage
```
~/.claude/skill-refinements/
├── suggested-refinements.md     # Active suggestions
├── refinement-history/          # Individual refinement records
├── aggregated-patterns.md       # Cross-project patterns
├── generalization-queue.md      # Ready for user-scope merge
└── .zen-sync                    # Zen MCP sync status
```

### Project-Scope Storage
```
.claude/skills/[skill-name]/
├── SKILL.patch.md               # Section patches
├── SKILL.extend.md              # Extensions
├── skill-config.json            # Config overrides
└── hooks/                       # Hook overrides
```

## Commands

### `/refine-skills`
Main refinement capture workflow.

**Usage:**
```
/refine-skills                    # Auto-detect target
/refine-skills context-engineering # Specify skill
```

**Workflow:**
1. Identify target skill and category
2. Gather context automatically
3. Capture expected vs actual behavior
4. Analyze and propose override
5. Confirm and apply

### `/apply-generalization`
Apply queued patterns to user-scope skills.

**Usage:**
```
/apply-generalization PATTERN-001  # Apply specific pattern
/apply-generalization --list       # List ready patterns
/apply-generalization --all        # Apply all (with confirmation)
```

### `/review-patterns`
Review tracked refinement patterns.

**Usage:**
```
/review-patterns                   # Overview
/review-patterns PATTERN-001       # Detail view
/review-patterns --status ready    # Filter by status
/review-patterns --stats           # Statistics
```

## Override Types

| Type | File | Use Case |
|------|------|----------|
| Section Patch | `SKILL.patch.md` | Targeted modifications |
| Extension | `SKILL.extend.md` | Add new capabilities |
| Config | `skill-config.json` | Environment settings |
| Full Override | `SKILL.md` | Complete replacement |
| Hook Override | `hooks/[name].sh` | Hook behavior |
| Script Override | `scripts/[name].py` | Script behavior |

## Patch Actions

```markdown
<!-- ACTION: append -->           # Add to end
<!-- ACTION: prepend -->          # Add to start
<!-- ACTION: replace-section "NAME" -->  # Replace subsection
<!-- ACTION: insert-after "MARKER" -->   # Insert after line
<!-- ACTION: insert-before "MARKER" -->  # Insert before line
<!-- ACTION: delete-section "NAME" -->   # Remove subsection
```

## Pattern Generalization

### Automatic (Count ≥ 2)
When a pattern appears in 2+ different projects, it's automatically flagged for generalization.

### Manual Promotion
```
/review-patterns PATTERN-ID --promote
```

### Manual Dismissal
```
/review-patterns PATTERN-ID --dismiss "Reason"
```

## Script Usage

### Log a Refinement (CLI)

```bash
python scripts/log_refinement.py \
  --skill context-engineering \
  --category hook \
  --target hooks/duplicate-check \
  --expected "Test fixtures should be allowed" \
  --actual "Hook blocks all matching files" \
  --patch-content "Add EXCLUDE_PATTERNS check" \
  --project my-project
```

### Options

```
--skill         Required. Target skill name
--category      Required. trigger|content|hook|tool|pattern|config|new
--target        Required. Target section path
--expected      Required. Expected behavior
--actual        Required. Actual behavior
--example       Reproduction example
--override-type patch|extend|config|full|hook|script|new (default: patch)
--patch-action  append|prepend|replace-section|insert-after|insert-before
--patch-content Content of the patch
--project       Project name
--generalization high|medium|low (default: medium)
--json          Output as JSON
```

## MCP Integration

### Required
- **Desktop Commander**: Tool call history, file operations

### Optional
- **Sentry**: Error context for pattern detection
- **Zen MCP**: Cross-project pattern persistence

## Examples

### Example 1: Hook Modification

```
User: "The duplicate-check hook keeps blocking my test fixtures"

System detects refinement opportunity:
- Skill: context-engineering
- Category: hook
- Target: hooks/duplicate-check

Proposes patch:
<!-- ACTION: insert-after "Only check paths" -->
if echo "$FILE_PATH" | grep -qE "(__tests__|fixtures)"; then
  exit 0
fi

Applied to: .claude/skills/context-engineering/SKILL.patch.md
Tracked as: REF-2024-1204-001
Pattern: PATTERN-001 (count: 1)
```

### Example 2: Trigger Extension

```
User: "The error skill should trigger for 'performance issue'"

System proposes extension:
<!-- ACTION: append -->
- "performance issue"
- "slow response"

Applied to: .claude/skills/error-lifecycle-management/SKILL.extend.md
```

### Example 3: Generalization

```
Pattern PATTERN-001 seen in 3 projects.
Status: Ready for generalization

/apply-generalization PATTERN-001

Updated:
- ~/claude-skills/context-engineering/hooks/duplicate-check.sh
- ~/claude-skills/error-lifecycle-management/scripts/common/base_validator.py

Pattern archived. Project overrides can now be removed.
```

## Best Practices

1. **Start with patches** - Prefer targeted changes over full overrides
2. **Document context** - Include examples and reproduction steps
3. **Track patterns** - Let the system identify generalizable improvements
4. **Review regularly** - Check generalization queue periodically
5. **Test before generalizing** - Verify patterns work across contexts
6. **Clean up project overrides** - Remove after generalization

## Troubleshooting

### Patch Not Applying

1. Check marker text is unique and exists in target
2. Verify section path is correct
3. Review patch syntax for errors

### Pattern Not Detected

1. Ensure refinements are logged (not just applied)
2. Check pattern matching criteria
3. Use `--promote` for manual generalization

### Zen MCP Sync Issues

1. Check `.zen-sync` timestamp
2. Verify Zen MCP connection
3. File-based storage works without MCP

## Contributing

This skill is part of the Claude Skills ecosystem. Refinements to this skill itself should be captured using the same system!

```
/refine-skills skill-refinement
```
