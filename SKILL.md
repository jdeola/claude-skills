# Claude Skills Orchestrator

> **Version:** 1.0.0  
> **Purpose:** Master guide for the Claude Skills ecosystem  
> **Scope:** User-scope skills applicable to any development project

---

## Understanding Skills vs Tools

```
┌─────────────────────────────────────────────────────────────────┐
│  SKILLS (This Library)                                          │
│  ════════════════════                                           │
│  • Instructions & guidance (prompt injection)                   │
│  • Workflows & decision trees                                   │
│  • Patterns & anti-patterns                                     │
│  • WHEN and HOW to use tools                                    │
│                                                                 │
│  Skills tell Claude what to do, not how to do it mechanically.  │
└─────────────────────────────────────────────────────────────────┘
                        ↓ instructs
┌─────────────────────────────────────────────────────────────────┐
│  CLAUDE CODE (Decision Maker)                                   │
│  ════════════════════════════                                   │
│  • Interprets skill guidance                                    │
│  • Selects appropriate tools                                    │
│  • Executes workflows                                           │
└─────────────────────────────────────────────────────────────────┘
                        ↓ uses
┌─────────────────────────────────────────────────────────────────┐
│  MCP SERVERS (Capabilities)                                     │
│  ══════════════════════════                                     │
│  • Sentry - Error tracking                                      │
│  • Vercel - Deployment info                                     │
│  • Zen MCP - Context persistence                                │
│  • Git - Version control                                        │
│  • Desktop Commander - File operations                          │
│                                                                 │
│  MCP servers provide the actual tools Claude calls.             │
└─────────────────────────────────────────────────────────────────┘
```

**Key Insight:** Skills are NOT tools. They guide Claude on WHEN to use tools, HOW to approach problems, and WHAT patterns to follow. MCP servers provide the actual capabilities.

---

## Available Skills

| Skill | Version | Primary Purpose |
|-------|---------|-----------------|
| [context-engineering](context-engineering/SKILL.md) | 2.0.0 | Session/memory management, context hygiene |
| [error-lifecycle-management](error-lifecycle-management/SKILL.md) | 2.0.0 | Error tracking, validation, incident response |
| [data-mutation-consistency](data-mutation-consistency/SKILL.md) | 2.0.0 | Enforce mutation patterns (Vercel/Next.js/Supabase) |
| [skill-refinement](skill-refinement/SKILL.md) | 1.0.0 | Capture and apply skill improvements |

---

## Resource Classification System

All bundled resources in skills follow this classification:

### 🔧 EXECUTE Scripts
Claude should **RUN** these scripts to perform analysis or generate outputs.
```bash
python3 scripts/some_script.py --flag value
```

### ⚡ ONE-TIME EXECUTE Scripts  
Claude should **RUN ONCE** per project for initial setup. Not for repeated use.
```bash
npx ts-node scripts/setup_something.ts
```

### 📚 REFERENCE Modules
Shared code imported by other scripts. Claude should **NOT run directly**.
These exist to support the EXECUTE scripts.

### 🪝 AUTO-TRIGGERED Hooks
Run automatically by Claude Code hooks system. Claude does **NOT invoke directly**.
Configure in `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{"type": "command", "command": ".claude/hooks/session-init.sh"}]
  }
}
```

### 📖 READ References
Documentation Claude should read for guidance, patterns, and workflows.

---

## Skill Selection Guide

### When Starting a Session
**Skill:** `context-engineering`  
**Trigger:** Session start, new task, "where were we"
```
→ Load project context
→ Check documentation freshness
→ Review component registry
```

### When Implementing Features
**Skill:** `context-engineering` → `/impact-map`  
**Trigger:** "implement", "create", "build new"
```
1. Map dependencies BEFORE writing code
2. Check component registry for reusable items
3. Follow implementation order from impact map
```

### When Debugging Errors
**Skill:** `error-lifecycle-management`  
**Trigger:** "error", "bug", "crash", "production issue"
```
1. Query Sentry for error details (MCP)
2. Run validation scripts
3. Follow triage workflow
4. Correlate with recent deployments
```

### When Session Gets Heavy
**Skill:** `context-engineering` → `/context-hygiene`  
**Trigger:** "context heavy", "slow", "confused", >25 messages
```
1. Summarize current state
2. Identify completable tasks
3. Consider new session
```

### When Finishing Work
**Skill:** `context-engineering` → `/done`  
**Trigger:** "done", "finished", "commit"
```
1. Run validation (build, lint, test)
2. Check for unstaged related files
3. Extract memories if needed
```

### When Dealing with Stale Data / Mutations
**Skill:** `data-mutation-consistency`
**Trigger:** "stale data", "not updating", "cache", "mutation", "revalidate"
```
1. Run @analyze-mutations for full codebase check
2. Check mutation scoring (9.0 warning, 7.0 critical)
3. Verify cache tags ↔ query keys alignment
4. Generate fix plan with @fix-mutations
```

### When Skills Need Improvement
**Skill:** `skill-refinement` → `/refine-skills`
**Trigger:** "skill should have", "skill missed", "false positive"
```
1. Gather context
2. Analyze expected vs actual
3. Generate and apply patch
4. Log for pattern tracking
```

---

## MCP Server Integration

Skills reference these MCP servers. Ensure they're configured:

| Server | Used By | Purpose |
|--------|---------|---------|
| **Sentry** | error-lifecycle-management | Query production errors |
| **Vercel** | error-lifecycle-management | Deployment logs, rollback |
| **Zen MCP** | context-engineering, skill-refinement | Context persistence |
| **Git** | context-engineering | Change tracking |
| **Desktop Commander** | skill-refinement | Tool call history |

### Checking MCP Availability

Before using MCP-dependent features, verify server status:
```
If MCP server unavailable:
  → Scripts have file-based fallbacks
  → Features may be limited
  → Skill will note "MCP not available"
```

---

## Installation Patterns

### Pattern 1: Symlink (Development)
```bash
ln -s ~/dev-local/claude-skills/context-engineering ~/.claude/skills/
```

### Pattern 2: Copy (Distribution)
```bash
cp -r ~/dev-local/claude-skills/context-engineering ~/.claude/skills/
```

### Pattern 3: Reference in CLAUDE.md
```markdown
## Skills
@skills/context-engineering/SKILL.md
@skills/error-lifecycle-management/SKILL.md
@skills/skill-refinement/SKILL.md
```

---

## Hook Installation

Copy hooks to project and configure:

```bash
# 1. Copy hooks
mkdir -p .claude/hooks
cp ~/dev-local/claude-skills/context-engineering/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh

# 2. Configure in .claude/settings.json
```

Example `.claude/settings.json`:
```json
{
  "hooks": {
    "SessionStart": [{
      "type": "command",
      "command": ".claude/hooks/session-init.sh"
    }],
    "PreToolUse": [
      {
        "type": "command",
        "command": ".claude/hooks/duplicate-check.sh",
        "toolNames": ["write_file", "create_file"]
      }
    ],
    "UserPromptSubmit": [{
      "type": "command",
      "command": ".claude/hooks/skill-suggester.sh"
    }]
  }
}
```

---

## Workflow Interconnections

```
┌─────────────────────────────────────────────────────────────────┐
│                     SKILL ECOSYSTEM                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐       ┌─────────────────────┐          │
│  │ context-engineering │◄─────►│ skill-refinement    │          │
│  │                     │       │                     │          │
│  │ • Session lifecycle │       │ • Improve skills    │          │
│  │ • Memory management │       │ • Track patterns    │          │
│  │ • Context hygiene   │       │ • Generate patches  │          │
│  └──────────┬──────────┘       └─────────────────────┘          │
│             │                                                   │
│             │ Provides context for                              │
│             ▼                                                   │
│  ┌─────────────────────────────────────────────────┐           │
│  │ error-lifecycle-management                      │           │
│  │                                                 │           │
│  │ • Query Sentry (MCP)     • Run validators      │           │
│  │ • Triage errors          • Track patterns      │           │
│  │ • Generate fixes         • Monitor deploys     │           │
│  └──────────┬──────────────────────────────────────┘           │
│             │                                                   │
│             │ Stale data issues trigger                         │
│             ▼                                                   │
│  ┌─────────────────────────────────────────────────┐           │
│  │ data-mutation-consistency                       │           │
│  │                                                 │           │
│  │ • Score mutations        • Check cache tags    │           │
│  │ • Validate patterns      • Cross-layer align  │           │
│  │ • Generate fixes         • React Query/Payload │           │
│  └─────────────────────────────────────────────────┘           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

Cross-skill workflows:
1. Session start → context-engineering loads context
2. Error detected → error-lifecycle-management handles
3. Stale data issue → data-mutation-consistency analyzes
4. Solution found → skill-refinement captures pattern
5. Session end → context-engineering extracts memories
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────────────┐
│                 CLAUDE SKILLS QUICK REFERENCE                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  SKILLS = Instructions/Guidance   MCP = Actual Tools            │
│  ──────────────────────────────   ─────────────────             │
│  Tell Claude WHEN/HOW             Provide capabilities          │
│  No namespace collision           mcp__server__tool             │
│                                                                 │
│  RESOURCE TYPES                   SKILL TRIGGERS                │
│  ──────────────                   ──────────────                │
│  🔧 EXECUTE    Run for output     context:  "session", "done"   │
│  ⚡ ONE-TIME   Run once/project   errors:   "bug", "crash"      │
│  📚 REFERENCE  Import only        refine:   "skill should..."   │
│  🪝 AUTO       Hooks (no invoke)                                │
│  📖 READ       Documentation                                    │
│                                                                 │
│  COMMON WORKFLOWS                                               │
│  ────────────────                                               │
│  New session:  context-engineering → /start                     │
│  New feature:  context-engineering → /impact-map                │
│  Bug fix:      error-lifecycle-management → triage              │
│  Stale data:   data-mutation-consistency → @analyze-mutations   │
│  Commit:       context-engineering → /done                      │
│  Heavy ctx:    context-engineering → /context-hygiene           │
│  Skill issue:  skill-refinement → /refine-skills                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Design Principles

1. **Skills ≠ Tools** - Skills guide, MCP provides capabilities
2. **Progressive Disclosure** - SKILL.md as router, details in references
3. **Project-Agnostic** - Configurable paths, no hardcoded values
4. **MCP-First** - Reference MCP servers, provide fallbacks
5. **Explicit Classification** - Clear markers for execute/read/auto
6. **Composable** - Skills work together, not in isolation

---

## Related Resources

- [README.md](README.md) - Installation and overview
- [dev-flow-foundations/](dev-flow-foundations/) - Advanced workflow patterns
- [SuperClaude Framework](~/.claude/) - User-scope behavior configuration
