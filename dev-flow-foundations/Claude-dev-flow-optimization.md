I'll help you develop a strategic approach to optimize your Claude Code workflow. Let me first examine your project structure and existing setup, then search for relevant MCP best practices.Let me fetch the SuperClaude and Zen MCP documentation to understand your current tooling better:Now I have a comprehensive picture of your tooling and pain points. Let me provide strategic recommendations that address your specific issues.

---

## Strategic Development Workflow Optimization

Based on your described pain points and existing tooling, I've identified five core problems and corresponding solutions that work together as a system:

### Problem 1: Incomplete Implementations Across Related Files

**Root Cause:** Claude doesn't maintain a mental model of file relationships and tends to implement changes in the file it's focused on without understanding dependencies.

**Strategic Solution: Pre-Implementation Impact Mapping**

Create a skill that enforces a mandatory "impact analysis" phase before any implementation begins:

```markdown
# Impact Mapping Skill

## Trigger

Before implementing ANY feature or fix, Claude must:

1. Run a dependency scan using `git grep` and AST analysis
2. Create an explicit `IMPACT_MAP.md` in the working directory:

   - Files that IMPORT the modified code
   - Files that EXPORT to the modified code
   - Shared types/interfaces affected
   - Component props that cascade
   - API routes that consume/produce affected data

3. Present the impact map and get confirmation BEFORE writing code

## Enforcement

If Claude attempts to modify code without creating the impact map first,
remind it that the workflow requires impact analysis.
```

**Pair this with Zen MCP's `planner` tool:**

```
"Use zen planner to break down this feature implementation,
ensuring every affected file is accounted for before we begin"
```

### Problem 2: Code Duplication / Not Reusing Components

**Root Cause:** Claude doesn't maintain awareness of existing utilities and components as context grows.

**Strategic Solution: Living Component Registry**

Instead of relying on Claude to remember components, create an **auto-generated registry** that's compact enough to always fit in context:

```bash
# Create a script that generates a component index
# Run this as a pre-session ritual or via cron

#!/bin/bash
# scripts/generate-component-registry.sh

echo "# Component Registry (Auto-generated)" > COMPONENT_REGISTRY.md
echo "Last updated: $(date)" >> COMPONENT_REGISTRY.md

echo -e "\n## UI Components (rhize-lms)" >> COMPONENT_REGISTRY.md
find ./rhize-lms/components -name "*.tsx" -exec basename {} .tsx \; | sort | uniq >> COMPONENT_REGISTRY.md

echo -e "\n## Utilities" >> COMPONENT_REGISTRY.md
grep -r "export function\|export const" ./rhize-lms/lib --include="*.ts" | \
  sed 's/.*export \(function\|const\) \([a-zA-Z]*\).*/\2/' | sort | uniq >> COMPONENT_REGISTRY.md

echo -e "\n## API Helpers (vba-hoops)" >> COMPONENT_REGISTRY.md
grep -r "export function\|export const" ./vba-hoops/lib --include="*.ts" | \
  sed 's/.*export \(function\|const\) \([a-zA-Z]*\).*/\2/' | sort | uniq >> COMPONENT_REGISTRY.md

echo -e "\n## Payload Collections" >> COMPONENT_REGISTRY.md
ls ./vba-hoops/collections/*.ts | xargs basename -a | sed 's/.ts$//' >> COMPONENT_REGISTRY.md
```

**Add to CLAUDE.md:**

```markdown
## BEFORE CREATING NEW CODE

Always check COMPONENT_REGISTRY.md for existing:

- UI components (search before creating)
- Utility functions (especially date, formatting, validation)
- API helpers
- Shared types

If a component exists, USE IT. If it needs modification, EXTEND it.
```

### Problem 3: Outdated CLAUDE.md and Contextual Files

**Root Cause:** Documentation drift happens because updates are manual and after-the-fact.

**Strategic Solution: Automated Context Hygiene with Git Hooks + Zen**

Create a **pre-commit skill** that validates documentation currency:

```markdown
# Context Hygiene Skill

## Pre-Commit Validation

Before committing, verify:

1. If new files were added → COMPONENT_REGISTRY.md is regenerated
2. If API routes changed → API documentation is updated
3. If new patterns introduced → PATTERNS.md is updated
4. If breaking changes → CHANGELOG.md entry exists

## Weekly Maintenance (Schedule with cron or run manually)

Use: "zen codereview focusing on documentation freshness and CLAUDE.md accuracy"

## Structure for CLAUDE.md

Keep it LEAN. Move detailed content to specialized files:

- CLAUDE.md (under 200 lines - high-level project context only)
- ARCHITECTURE.md (system design, data flow)
- PATTERNS.md (coding conventions, reusable patterns)
- CURRENT_SPRINT.md (active work, known issues)
- COMPONENT_REGISTRY.md (auto-generated)
```

**Key insight:** Your CLAUDE.md should be a **router**, not a **repository**:

```markdown
# CLAUDE.md - Keep this under 200 lines

## Quick Reference

- Architecture: See ARCHITECTURE.md
- Current Work: See CURRENT_SPRINT.md
- Components: See COMPONENT_REGISTRY.md (auto-generated)
- API Patterns: See vba-hoops/docs/API_PATTERNS.md
- Error Handling: See .claude/skills/error-triage/SKILL.md

## Critical Context (ONLY things that affect EVERY task)

- Dual repo: rhize-lms (frontend) + vba-hoops (backend)
- Always run `pnpm typecheck` before committing
- Supabase RLS policies must be considered for all data access
```

### Problem 4: Context Window Exhaustion

**Root Cause:** Loading too much context upfront, keeping error logs and debugging output in conversation.

**Strategic Solutions:**

**A. Session Segmentation with Zen Context Revival**

This is Zen MCP's killer feature - use it deliberately:

```
Session 1: "Implement the player registration feature"
→ Work until context gets heavy
→ "Save the current state to zen with context about what we've accomplished"

Session 2: "Continue with zen - restore context about player registration"
→ Claude gets caught up without re-loading everything
```

**B. Aggressive Context Offloading Skill**

```markdown
# Context Management Skill

## During Development

When errors occur or debugging begins:

1. Capture error details to a timestamped file: `logs/debug-{timestamp}.md`
2. Summarize the issue in 2-3 sentences for Claude's working memory
3. Reference the file path instead of keeping full stack traces in conversation

## Example Response Format

"Encountered TypeError in PlayerCard.tsx. Details saved to logs/debug-20241201-1430.md.
Summary: Props interface mismatch between parent and child component."

## When to Spawn New Sessions

- After 15+ back-and-forth messages on the same feature
- After any debugging session exceeds 10 messages
- When switching between frontend and backend work
```

**C. SuperClaude Session Management**

Use `/sc:save` and `/sc:load` strategically:

```
/sc:save "completed-auth-implementation"
→ Start fresh session
/sc:load "completed-auth-implementation"
→ Resume with compressed context
```

### Problem 5: Circular Debugging / Regression Loops

**Root Cause:** Fixes are applied without understanding root causes, and there's no systematic verification.

**Strategic Solution: Regression Prevention Pipeline**

**A. Mandatory Pre-Fix Protocol (Skill)**

```markdown
# Regression Prevention Skill

## Before ANY Bug Fix

Claude must complete this checklist:

### 1. Root Cause Analysis (Required)

- What is the ACTUAL cause, not just the symptom?
- Use zen thinkdeep for complex issues
- Document in: `logs/rca-{issue}.md`

### 2. Impact Assessment

- What else could this fix break?
- Run: grep for related usages
- List affected tests

### 3. Test-First Verification

- Write/identify test that reproduces the bug FIRST
- Confirm test fails before fix
- Confirm test passes after fix

### 4. Regression Check

- Run full test suite before committing
- Use zen precommit for validation

## Anti-Pattern Detection

If Claude is about to:

- "Try this quick fix..."
- "Let me just change this one line..."
- "That should work, let's test it..."

STOP. These phrases indicate we're not following the protocol.
```

**B. Automated Regression Guard with Sentry + Vercel MCPs**

Create a skill that triggers automatically:

```markdown
# Automated Error Monitoring Skill

## Triggers

Activate when user mentions: "error", "bug", "broken", "not working", "regression"

## Workflow

1. Query Sentry for recent errors in the affected area
2. Query Vercel for recent deployments that might correlate
3. Cross-reference with git log for recent changes
4. Present timeline before attempting fixes

## Integration Commands

Use these MCP tools in sequence:

- sentry:list_issues (filter by file path if known)
- vercel:deployments (last 5)
- git:log (relevant paths, last 10 commits)
```

---

## Implementation Roadmap

### Week 1: Foundation

1. Create `COMPONENT_REGISTRY.md` auto-generation script
2. Restructure CLAUDE.md to be a "router" under 200 lines
3. Create `CURRENT_SPRINT.md` for active work context

### Week 2: Skills Development

4. Implement Impact Mapping Skill
5. Implement Regression Prevention Skill
6. Configure Zen MCP with your preferred models for:
   - `codereview`: Gemini Pro (deep analysis)
   - `precommit`: O3 (reasoning about edge cases)
   - `planner`: Pro (comprehensive breakdown)

### Week 3: Workflow Integration

7. Create git hooks for context hygiene
8. Establish session segmentation patterns
9. Document your "golden path" workflows

### Week 4: Refinement

10. Review which skills are triggering correctly
11. Adjust skill descriptions for better activation
12. Add examples to skills based on real usage

---

## Quick Wins You Can Implement Today

1. **Add this to your CLAUDE.md immediately:**

```markdown
## MANDATORY BEFORE IMPLEMENTATION

1. Check COMPONENT_REGISTRY.md for existing solutions
2. Create impact map of affected files
3. Get confirmation before proceeding

## MANDATORY BEFORE COMMITTING

1. Run pnpm typecheck
2. Run affected tests
3. Use zen precommit for validation
```

2. **Start using Zen's context revival** - When your session gets heavy:

```
"Use zen to save our current context with key: 'feature-xyz-progress'"
```

Then in a new session:

```
"Use zen to restore context from key: 'feature-xyz-progress'"
```

3. **Leverage multi-model validation** - Before any significant implementation:

```
"Use zen consensus with pro and o3 to validate this approach before we implement"
```

Would you like me to create any of these skills as complete, ready-to-use packages? I can also help you structure your CLAUDE.md restructure or create the component registry generation script tailored to your actual project structure if you can share the directory layout.
