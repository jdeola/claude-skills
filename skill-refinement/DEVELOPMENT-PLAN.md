# Skill Refinement System - Development Plan

> **Version:** 1.0.0-draft
> **Created:** 2024-12-04
> **Status:** Planning Complete - Ready for Implementation

---

## Executive Summary

A standalone skill for capturing, applying, and generalizing refinements across the Claude Skills ecosystem. Enables project-level overrides that automatically bubble up to user-scope skills when patterns emerge across projects.

### Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Override Granularity | Section-level patches | Precise modifications without duplicating entire skills |
| Automation Level | Semi-automated + guided | Balance efficiency with accuracy; guide when ambiguous |
| Generalization Trigger | Auto (2+ occurrences) + manual queue | Catch patterns early; retain human oversight |
| Persistence | Zen MCP + file-based | Redundancy; works with/without MCP available |
| Scope | Standalone skill | Works across all skills; not tied to single skill |

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SKILL REFINEMENT SYSTEM                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  TRIGGER LAYER                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  /refine-   │  │  Keyword    │  │  Session    │  │  Manual     │       │
│  │   skills    │  │  Detection  │  │  End Hook   │  │  Invocation │       │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
│         └────────────────┴────────────────┴────────────────┘               │
│                                    │                                        │
│                                    ▼                                        │
│  CONTEXT LAYER                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     CONTEXT GATHERER                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌────────────┐ │   │
│  │  │ Session     │  │ Tool Calls  │  │ Errors      │  │ Current    │ │   │
│  │  │ History     │  │ (DC MCP)    │  │ (Sentry)    │  │ Skills     │ │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ANALYSIS LAYER                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     REFINEMENT ANALYZER                              │   │
│  │  • Gap Analysis (expected vs actual)                                 │   │
│  │  • Override Type Detection (patch/extend/config/full)                │   │
│  │  • Ambiguity Detection → Guided Mode                                 │   │
│  │  • Pattern Matching (seen before?)                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                    ┌───────────────┴───────────────┐                       │
│                    ▼                               ▼                       │
│  OUTPUT LAYER                                                               │
│  ┌─────────────────────────┐      ┌─────────────────────────────────────┐  │
│  │    PROJECT SCOPE        │      │         USER SCOPE                  │  │
│  │  .claude/skills/        │      │  ~/.claude/skill-refinements/       │  │
│  │  ├─ [skill]/            │      │  ├─ suggested-refinements.md        │  │
│  │  │  ├─ SKILL.patch.md   │      │  ├─ refinement-history/             │  │
│  │  │  ├─ config.json      │      │  ├─ aggregated-patterns.md          │  │
│  │  │  └─ overrides/       │      │  └─ generalization-queue.md         │  │
│  │  └─ refinement-log.md   │      │                                     │  │
│  └─────────────────────────┘      └─────────────────────────────────────┘  │
│                                                                             │
│  PERSISTENCE LAYER (Dual)                                                   │
│  ┌─────────────────────────┐      ┌─────────────────────────────────────┐  │
│  │      ZEN MCP            │      │         FILE SYSTEM                 │  │
│  │  • Context persistence  │ ◄──► │  • Markdown logs                    │  │
│  │  • Cross-session memory │      │  • JSON configs                     │  │
│  │  • Pattern storage      │      │  • Git-trackable history            │  │
│  └─────────────────────────┘      └─────────────────────────────────────┘  │
│                                                                             │
│  GENERALIZATION LAYER                                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     PATTERN AGGREGATOR                               │   │
│  │  • Track refinement frequency across projects                        │   │
│  │  • Auto-trigger generalization when count ≥ 2                        │   │
│  │  • Manual review queue for edge cases                                │   │
│  │  • Apply to user-scope skills                                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Skill Hierarchy & Override System

### Priority Order

```
1. PROJECT LOCAL     ./.claude/skills/[skill]/     Highest priority
2. PROJECT SHARED    ./skills/[skill]/             Team-shared (git tracked)
3. USER SCOPE        ~/claude-skills/[skill]/      Generalized defaults
```

### Override Types

| Type | File | Behavior | Use When |
|------|------|----------|----------|
| **Section Patch** | `SKILL.patch.md` | Modifies specific sections | Targeted fixes |
| **Extension** | `SKILL.extend.md` | Adds to existing skill | New patterns/triggers |
| **Config Override** | `skill-config.json` | Changes configuration values | Environment-specific |
| **Full Override** | `SKILL.md` | Replaces entire skill | Major divergence |
| **Hook Override** | `hooks/[name].sh` | Replaces specific hook | Hook behavior change |
| **Script Override** | `scripts/[name].py` | Replaces specific script | Script behavior change |

### Section Patch Format

```markdown
# SKILL.patch.md
# Patches for: context-engineering

## PATCH: triggers
<!-- ACTION: append -->
- "test fixture"
- "mock component"

## PATCH: hooks/duplicate-check
<!-- ACTION: replace-section "EXCLUDE PATTERNS" -->
# Exclude patterns (project-specific)
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-__tests__|fixtures|__mocks__|.test.|.spec.}"

## PATCH: commands/done
<!-- ACTION: insert-after "Step 4" -->
### Step 4.5: Project-Specific Validation
Run any project-specific validation scripts:
```bash
./scripts/validate-project.sh
```
```

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

## Command Definition: `/refine-skills`

### Trigger Keywords

```
Primary:
- "/refine-skills", "/refine-skill", "/skill-refine"

Auto-detected (via skill-suggester hook):
- "skill doesn't work", "skill should have", "missing trigger"
- "should have caught", "why didn't skill", "skill broke"
- "improve skill", "extend skill", "add to skill"
- "skill missed", "false positive", "false negative"
```

### Command Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      /refine-skills WORKFLOW                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  STEP 1: IDENTIFY TARGET                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Q: Which skill needs refinement?                                    │   │
│  │     [Auto-detect from context] or [User specifies]                   │   │
│  │                                                                      │   │
│  │  Q: What category?                                                   │   │
│  │     □ Trigger (when skill activates)                                 │   │
│  │     □ Content (what skill does/outputs)                              │   │
│  │     □ Hook (automation behavior)                                     │   │
│  │     □ Tool Integration (MCP usage)                                   │   │
│  │     □ Pattern (detection/validation)                                 │   │
│  │     □ Config (settings/options)                                      │   │
│  │     □ New capability (doesn't exist yet)                             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  STEP 2: GATHER CONTEXT (Automated)                                         │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Sources:                                                            │   │
│  │  • Desktop Commander: get_recent_tool_calls (last 50)                │   │
│  │  • Sentry MCP: Recent errors (if available)                          │   │
│  │  • Zen MCP: Saved context, memories (if available)                   │   │
│  │  • File system: Current skill configs, recent file changes           │   │
│  │  • Git: Recent commits, current diff                                 │   │
│  │                                                                      │   │
│  │  Output: Structured context summary                                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  STEP 3: CAPTURE USER INSIGHT                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Q: What behavior did you expect?                                    │   │
│  │  Q: What actually happened?                                          │   │
│  │  Q: Can you provide a specific example?                              │   │
│  │  Q: What's the desired outcome?                                      │   │
│  │                                                                      │   │
│  │  [GUIDED MODE if ambiguous]:                                         │   │
│  │  • Clarifying questions                                              │   │
│  │  • Example suggestions                                               │   │
│  │  • Similar past refinements shown                                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  STEP 4: ANALYZE & PROPOSE                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Analysis:                                                           │   │
│  │  • Root cause identification                                         │   │
│  │  • Similar patterns in refinement history                            │   │
│  │  • Impact assessment                                                 │   │
│  │                                                                      │   │
│  │  Proposal:                                                           │   │
│  │  • Override type recommendation                                      │   │
│  │  • Generated patch/extension content                                 │   │
│  │  • Preview of changes (diff view)                                    │   │
│  │  • Generalization potential assessment                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  STEP 5: USER CONFIRMATION                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Show:                                                               │   │
│  │  • Proposed changes (formatted diff)                                 │   │
│  │  • Files to be created/modified                                      │   │
│  │  • Generalization potential rating                                   │   │
│  │                                                                      │   │
│  │  Options:                                                            │   │
│  │  □ Apply as proposed                                                 │   │
│  │  □ Modify before applying                                            │   │
│  │  □ Apply to project only (skip user-scope logging)                   │   │
│  │  □ Cancel                                                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  STEP 6: APPLY REFINEMENT                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Project Scope:                                                      │   │
│  │  • Create/update .claude/skills/[skill]/ files                       │   │
│  │  • Update project refinement log                                     │   │
│  │                                                                      │   │
│  │  User Scope:                                                         │   │
│  │  • Log to suggested-refinements.md                                   │   │
│  │  • Save to Zen MCP context (if available)                            │   │
│  │  • Check pattern frequency → trigger aggregation if ≥2               │   │
│  │                                                                      │   │
│  │  Output:                                                             │   │
│  │  • Summary of applied changes                                        │   │
│  │  • Testing suggestions                                               │   │
│  │  • Next steps if generalization triggered                            │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Output Format

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
  [Auto-generalization triggered / Added to review queue]

✅ Applied Successfully

💡 Next Steps:
  1. Test the refinement with: [specific test scenario]
  2. Run /done to validate before committing
  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## User-Scope Refinement Logging

### Directory Structure

```
~/.claude/skill-refinements/
├── suggested-refinements.md          # Active suggestions (pending review)
├── refinement-history/               # Applied refinements by date
│   ├── 2024-12-04-context-engineering-trigger.md
│   ├── 2024-12-04-error-lifecycle-pattern.md
│   └── ...
├── aggregated-patterns.md            # Cross-project pattern tracking
├── generalization-queue.md           # Ready for user-scope merge
└── .zen-sync                         # Zen MCP sync status
```

### suggested-refinements.md

```markdown
# Suggested Skill Refinements

> Last updated: 2024-12-04T14:30:00Z
> Sync status: ✅ Zen MCP synced

## Pending Review

### REF-2024-1204-001 | context-engineering / duplicate-check hook
- **Project:** vba-lms-app
- **Category:** hook-modification
- **Date:** 2024-12-04
- **Status:** pending

**Observation:**
Hook blocks test fixture files that intentionally duplicate component patterns for testing.

**Current Behavior:**
```bash
# Blocks ANY new file matching component name in registry
if [ -n "$MATCHES" ]; then
  exit 2  # BLOCKING ERROR
fi
```

**Expected Behavior:**
Should exclude test directories (`__tests__/`, `fixtures/`, `__mocks__/`) from duplicate checking.

**Reproduction:**
```bash
# This is blocked but shouldn't be:
touch components/__tests__/fixtures/MockButton.tsx
```

**Proposed Change:**
```bash
# Add exclusion check before blocking
if [[ "$FILE_PATH" =~ (__tests__|fixtures|__mocks__|\.test\.|\.spec\.) ]]; then
  exit 0  # Allow test files
fi
```

**Override Type:** patch
**Generalization Potential:** high
**Pattern Matches:** 0 (new pattern)

---

### REF-2024-1203-002 | error-lifecycle-management / validate patterns
[... additional entries ...]

---

## Recently Applied

### REF-2024-1202-001 | context-engineering / start command ✅
- **Applied:** 2024-12-02
- **Generalized:** No (project-specific)
- **Project:** rhize-lms
```

### aggregated-patterns.md

```markdown
# Aggregated Refinement Patterns

> Auto-updated when pattern count ≥ 2
> Last aggregation: 2024-12-04T14:30:00Z

## Ready for Generalization (count ≥ 2)

### PATTERN-001: Test Directory Exclusion
- **First seen:** 2024-12-01 (vba-lms-app)
- **Also seen:** 2024-12-03 (rhize-lms), 2024-12-04 (client-project)
- **Count:** 3
- **Status:** 🟡 Pending generalization

**Affected Skills:**
- context-engineering (duplicate-check hook)
- error-lifecycle-management (all validators)

**Pattern Description:**
Hooks and validators need standard exclusion patterns for test directories.

**Proposed Generalization:**
Add `EXCLUDE_PATTERNS` environment variable to all hooks/validators with default:
```bash
EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-__tests__|fixtures|__mocks__|\.test\.|\.spec\.}"
```

**Refinement IDs:** REF-2024-1201-003, REF-2024-1203-001, REF-2024-1204-001

---

## Tracking (count = 1)

### PATTERN-002: CMS-Specific Error Validators
- **First seen:** 2024-12-02 (vba-lms-app / Payload)
- **Count:** 1
- **Status:** ⚪ Tracking

**Notes:**
If seen again with different CMS, consider plugin architecture for error-lifecycle.

---

## Archived (Generalized)

### PATTERN-000: API Pattern Configuration ✅
- **Generalized:** 2024-11-28
- **Applied to:** error-lifecycle-management v2.0.0
- **Description:** Made API detection patterns configurable via .error-lifecycle.json
```

### generalization-queue.md

```markdown
# Generalization Queue

> Refinements ready for user-scope skill updates
> Review and apply with: /apply-generalization [PATTERN-ID]

## Ready for Review

### PATTERN-001: Test Directory Exclusion
- **Priority:** High (3 occurrences)
- **Confidence:** High (consistent pattern)
- **Breaking Changes:** None (additive)

**Skills to Update:**
1. context-engineering/hooks/duplicate-check.sh
2. context-engineering/hooks/pre-commit-guard.sh  
3. error-lifecycle-management/scripts/common/base_validator.py

**Proposed Changes:**

#### context-engineering/hooks/duplicate-check.sh
```diff
+ # Configurable exclusion patterns
+ EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-__tests__|fixtures|__mocks__|\.test\.|\.spec\.}"
+ 
+ # Skip excluded paths
+ if echo "$FILE_PATH" | grep -qE "($EXCLUDE_PATTERNS)"; then
+   exit 0
+ fi
```

#### error-lifecycle-management/scripts/common/base_validator.py
```diff
+ DEFAULT_EXCLUDE_PATTERNS = [
+     r'__tests__',
+     r'fixtures', 
+     r'__mocks__',
+     r'\.test\.',
+     r'\.spec\.',
+ ]
```

**To Apply:**
```bash
/apply-generalization PATTERN-001
```

---

## Pending More Data

[Patterns with count = 1, awaiting second occurrence]
```

---

## Dual Persistence Strategy

### Zen MCP Integration

```python
# Zen MCP context structure for refinements

ZEN_CONTEXT_SCHEMA = {
    "skill_refinements": {
        "active_refinements": [
            {
                "id": "REF-2024-1204-001",
                "skill": "context-engineering",
                "category": "hook-modification",
                "status": "pending",
                "project": "vba-lms-app",
                "created": "2024-12-04T14:30:00Z",
                "pattern_id": "PATTERN-001"  # Links to pattern tracking
            }
        ],
        "patterns": {
            "PATTERN-001": {
                "name": "test-directory-exclusion",
                "count": 3,
                "projects": ["vba-lms-app", "rhize-lms", "client-project"],
                "status": "ready-for-generalization"
            }
        },
        "last_sync": "2024-12-04T14:30:00Z"
    }
}

# Zen MCP operations
OPERATIONS = {
    "save_refinement": "zen.save_context with refinement data",
    "query_patterns": "zen.restore_context filtered by pattern",
    "sync_status": "zen.list_memories for skill_refinements",
    "cross_project": "zen.search for similar refinements"
}
```

### File-Based Redundancy

```python
# Sync strategy
SYNC_STRATEGY = {
    "primary": "file-based",  # Always written first
    "secondary": "zen-mcp",   # Synced when available
    
    "on_refinement_create": [
        "1. Write to suggested-refinements.md",
        "2. Write to refinement-history/",
        "3. Update aggregated-patterns.md",
        "4. Sync to Zen MCP (async, non-blocking)"
    ],
    
    "on_session_start": [
        "1. Check Zen MCP for cross-project patterns",
        "2. Merge any new patterns to local files",
        "3. Update .zen-sync timestamp"
    ],
    
    "conflict_resolution": "file-based wins (more recent timestamp)"
}
```

---

## Automation Scripts

### Script Inventory

| Script | Purpose | Inputs | Outputs |
|--------|---------|--------|---------|
| `gather_context.py` | Collect refinement context | Session, tool calls, errors | Context JSON |
| `analyze_gap.py` | Determine refinement type | Context, user input | Analysis report |
| `generate_patch.py` | Create patch/override files | Analysis, skill files | Patch content |
| `apply_refinement.py` | Write files, update logs | Patch content, confirmation | Applied changes |
| `log_refinement.py` | Update user-scope logs | Refinement data | Log entries |
| `aggregate_patterns.py` | Track cross-project patterns | All refinements | Pattern updates |
| `sync_zen.py` | Sync with Zen MCP | Local files | Sync status |
| `apply_generalization.py` | Merge to user-scope skills | Pattern ID | Updated skills |

### gather_context.py

```python
"""
Gather context for skill refinement analysis.

Sources:
- Desktop Commander: get_recent_tool_calls
- Sentry MCP: Recent errors (optional)
- Zen MCP: Saved context (optional)
- File system: Skills, configs, git status
"""

from dataclasses import dataclass
from typing import Optional, List, Dict
from datetime import datetime
import json
import subprocess

@dataclass
class RefinementContext:
    """Context gathered for refinement analysis."""
    
    # Session context
    recent_tool_calls: List[Dict]
    session_duration: Optional[float]
    files_touched: List[str]
    
    # Error context (from Sentry if available)
    recent_errors: List[Dict]
    
    # Skill context
    target_skill: Optional[str]
    current_skill_config: Dict
    skill_files: List[str]
    
    # Git context
    git_status: str
    recent_commits: List[str]
    current_diff: str
    
    # Pattern context (from history)
    similar_refinements: List[Dict]
    pattern_matches: List[str]
    
    # Zen context (if available)
    zen_memories: Optional[List[Dict]]
    cross_project_patterns: Optional[List[Dict]]
    
    timestamp: datetime

class ContextGatherer:
    """Gather context from multiple sources."""
    
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.user_refinements_dir = Path.home() / ".claude" / "skill-refinements"
    
    async def gather(self, target_skill: Optional[str] = None) -> RefinementContext:
        """Gather all context for refinement analysis."""
        
        context = RefinementContext(
            recent_tool_calls=await self._get_tool_calls(),
            session_duration=self._estimate_session_duration(),
            files_touched=self._get_files_touched(),
            recent_errors=await self._get_sentry_errors(),
            target_skill=target_skill,
            current_skill_config=self._load_skill_config(target_skill),
            skill_files=self._list_skill_files(target_skill),
            git_status=self._get_git_status(),
            recent_commits=self._get_recent_commits(),
            current_diff=self._get_current_diff(),
            similar_refinements=self._find_similar_refinements(target_skill),
            pattern_matches=self._find_pattern_matches(target_skill),
            zen_memories=await self._get_zen_context(),
            cross_project_patterns=await self._get_cross_project_patterns(),
            timestamp=datetime.now()
        )
        
        return context
    
    async def _get_tool_calls(self) -> List[Dict]:
        """Get recent tool calls from Desktop Commander."""
        # Implementation: Call DC get_recent_tool_calls MCP
        pass
    
    async def _get_sentry_errors(self) -> List[Dict]:
        """Get recent errors from Sentry MCP if available."""
        # Implementation: Query Sentry MCP, return empty if unavailable
        pass
    
    async def _get_zen_context(self) -> Optional[List[Dict]]:
        """Get saved context from Zen MCP if available."""
        # Implementation: Query Zen MCP, return None if unavailable
        pass
    
    def _find_similar_refinements(self, skill: str) -> List[Dict]:
        """Search refinement history for similar issues."""
        # Implementation: Search refinement-history/ directory
        pass
    
    def _find_pattern_matches(self, skill: str) -> List[str]:
        """Check if this matches any tracked patterns."""
        # Implementation: Search aggregated-patterns.md
        pass
```

### analyze_gap.py

```python
"""
Analyze gap between expected and actual skill behavior.

Determines:
- Root cause of issue
- Appropriate override type
- Whether guided mode is needed
- Generalization potential
"""

from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

class OverrideType(Enum):
    SECTION_PATCH = "patch"
    EXTENSION = "extend"
    CONFIG_OVERRIDE = "config"
    FULL_OVERRIDE = "full"
    HOOK_OVERRIDE = "hook"
    SCRIPT_OVERRIDE = "script"
    NEW_CAPABILITY = "new"

class GuidedModeReason(Enum):
    AMBIGUOUS_TARGET = "Cannot determine which skill/section to modify"
    MULTIPLE_OPTIONS = "Multiple valid approaches available"
    BREAKING_CHANGE = "Proposed change may break existing behavior"
    CROSS_SKILL = "Refinement affects multiple skills"
    UNCLEAR_INTENT = "User intent not clear from context"

@dataclass
class GapAnalysis:
    """Result of gap analysis."""
    
    # Core analysis
    root_cause: str
    override_type: OverrideType
    target_section: str  # e.g., "hooks/duplicate-check" or "commands/start/Step 4"
    
    # Confidence & guidance
    confidence: float  # 0-1
    needs_guided_mode: bool
    guided_mode_reasons: List[GuidedModeReason]
    clarifying_questions: List[str]
    
    # Generalization
    generalization_potential: str  # "high", "medium", "low"
    pattern_id: Optional[str]  # Existing pattern this matches
    similar_refinements: List[str]  # IDs of similar past refinements
    
    # Impact
    affected_files: List[str]
    breaking_changes: List[str]
    
class GapAnalyzer:
    """Analyze skill gaps and determine refinement approach."""
    
    CONFIDENCE_THRESHOLD = 0.7  # Below this, trigger guided mode
    
    def analyze(
        self,
        context: RefinementContext,
        user_input: dict  # {expected, actual, example, desired_outcome}
    ) -> GapAnalysis:
        """Analyze the gap and determine refinement approach."""
        
        # Determine override type based on category and scope
        override_type = self._determine_override_type(context, user_input)
        
        # Find specific target section
        target_section = self._find_target_section(context, user_input)
        
        # Calculate confidence
        confidence = self._calculate_confidence(context, user_input, target_section)
        
        # Check if guided mode needed
        needs_guided, reasons, questions = self._check_guided_mode(
            confidence, context, user_input
        )
        
        # Assess generalization potential
        gen_potential, pattern_id = self._assess_generalization(context, user_input)
        
        return GapAnalysis(
            root_cause=self._identify_root_cause(context, user_input),
            override_type=override_type,
            target_section=target_section,
            confidence=confidence,
            needs_guided_mode=needs_guided,
            guided_mode_reasons=reasons,
            clarifying_questions=questions,
            generalization_potential=gen_potential,
            pattern_id=pattern_id,
            similar_refinements=context.similar_refinements,
            affected_files=self._list_affected_files(target_section),
            breaking_changes=self._identify_breaking_changes(context, user_input)
        )
    
    def _check_guided_mode(
        self,
        confidence: float,
        context: RefinementContext,
        user_input: dict
    ) -> tuple[bool, List[GuidedModeReason], List[str]]:
        """Determine if guided mode is needed."""
        
        reasons = []
        questions = []
        
        if confidence < self.CONFIDENCE_THRESHOLD:
            reasons.append(GuidedModeReason.AMBIGUOUS_TARGET)
            questions.append("Which specific part of the skill should be modified?")
        
        # Check for multiple valid approaches
        if self._has_multiple_approaches(context, user_input):
            reasons.append(GuidedModeReason.MULTIPLE_OPTIONS)
            questions.append("Should this be a patch to existing behavior or a new capability?")
        
        # Check for cross-skill impact
        if self._affects_multiple_skills(context, user_input):
            reasons.append(GuidedModeReason.CROSS_SKILL)
            questions.append("This affects multiple skills. Should all be updated?")
        
        return len(reasons) > 0, reasons, questions
```

### generate_patch.py

```python
"""
Generate patch/override files based on analysis.

Supports:
- Section-level patches with actions (append, replace, insert, delete)
- Full file overrides
- Config-only overrides
"""

from dataclasses import dataclass
from typing import List, Dict
import re

@dataclass
class GeneratedPatch:
    """Generated patch content and metadata."""
    
    files: Dict[str, str]  # path -> content
    preview: str  # Formatted diff preview
    description: str
    
class PatchGenerator:
    """Generate skill patches and overrides."""
    
    def generate(
        self,
        analysis: GapAnalysis,
        user_modifications: Optional[str] = None
    ) -> GeneratedPatch:
        """Generate patch based on analysis."""
        
        if analysis.override_type == OverrideType.SECTION_PATCH:
            return self._generate_section_patch(analysis)
        elif analysis.override_type == OverrideType.EXTENSION:
            return self._generate_extension(analysis)
        elif analysis.override_type == OverrideType.CONFIG_OVERRIDE:
            return self._generate_config_override(analysis)
        elif analysis.override_type == OverrideType.HOOK_OVERRIDE:
            return self._generate_hook_override(analysis)
        else:
            return self._generate_full_override(analysis)
    
    def _generate_section_patch(self, analysis: GapAnalysis) -> GeneratedPatch:
        """Generate SKILL.patch.md with section-level changes."""
        
        patch_content = f"""# SKILL.patch.md
# Patches for: {analysis.target_skill}
# Generated: {datetime.now().isoformat()}
# Refinement: {analysis.refinement_id}

## PATCH: {analysis.target_section}
<!-- ACTION: {analysis.patch_action} -->
{analysis.patch_content}
"""
        
        files = {
            f".claude/skills/{analysis.target_skill}/SKILL.patch.md": patch_content
        }
        
        preview = self._generate_diff_preview(analysis)
        
        return GeneratedPatch(
            files=files,
            preview=preview,
            description=f"Section patch for {analysis.target_section}"
        )
```

### aggregate_patterns.py

```python
"""
Aggregate refinement patterns across projects.

Triggers:
- Auto-generalization when pattern count >= 2
- Updates aggregated-patterns.md
- Populates generalization-queue.md
"""

from dataclasses import dataclass
from typing import List, Dict
from pathlib import Path
import json

GENERALIZATION_THRESHOLD = 2  # Auto-trigger at this count

@dataclass
class Pattern:
    """Tracked refinement pattern."""
    
    id: str
    name: str
    description: str
    affected_skills: List[str]
    refinement_ids: List[str]
    projects: List[str]
    count: int
    status: str  # "tracking", "ready-for-generalization", "generalized"
    proposed_changes: Dict[str, str]  # file -> change description

class PatternAggregator:
    """Track and aggregate refinement patterns."""
    
    def __init__(self, refinements_dir: Path):
        self.refinements_dir = refinements_dir
        self.patterns_file = refinements_dir / "aggregated-patterns.md"
        self.queue_file = refinements_dir / "generalization-queue.md"
    
    def process_new_refinement(self, refinement: dict) -> Optional[Pattern]:
        """Process a new refinement, update pattern tracking."""
        
        # Find or create pattern
        pattern = self._find_matching_pattern(refinement)
        
        if pattern:
            # Update existing pattern
            pattern = self._update_pattern(pattern, refinement)
        else:
            # Create new pattern (count = 1)
            pattern = self._create_pattern(refinement)
        
        # Check if threshold met
        if pattern.count >= GENERALIZATION_THRESHOLD:
            pattern.status = "ready-for-generalization"
            self._add_to_generalization_queue(pattern)
        
        # Update files
        self._write_patterns_file()
        
        return pattern
    
    def _find_matching_pattern(self, refinement: dict) -> Optional[Pattern]:
        """Find existing pattern that matches this refinement."""
        
        # Match by:
        # 1. Same skill + same section
        # 2. Similar description (semantic similarity)
        # 3. Same override type + similar content
        pass
    
    def _add_to_generalization_queue(self, pattern: Pattern):
        """Add pattern to generalization queue for review."""
        pass
```

---

## Integration Points

### Skill-Suggester Hook Update

```bash
# Add to skill-suggester.sh

# Detect refinement opportunities
if echo "$PROMPT_LOWER" | grep -qE "(skill.*wrong|skill.*broken|should.*caught|missing.*trigger|doesn't.*work|skill.*missed|false.*(positive|negative)|improve.*skill|extend.*skill|add.*skill)"; then
  SKILL="${SKILL_REFINEMENT:-/refine-skills}"
  REASON="Skill issue detected - capture refinement opportunity"
fi
```

### Session-End Hook (New)

```bash
#!/bin/bash
# session-end.sh
# Prompt for refinements after significant sessions

# Get session stats (from Desktop Commander or env)
TOOL_CALLS="${SESSION_TOOL_CALLS:-0}"
ERRORS="${SESSION_ERRORS:-0}"
DURATION="${SESSION_DURATION:-0}"

# Thresholds for prompting
TOOL_THRESHOLD=20
ERROR_THRESHOLD=1
DURATION_THRESHOLD=3600  # 1 hour in seconds

if [ "$TOOL_CALLS" -gt "$TOOL_THRESHOLD" ] || \
   [ "$ERRORS" -gt "$ERROR_THRESHOLD" ] || \
   [ "$DURATION" -gt "$DURATION_THRESHOLD" ]; then
  
  cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Session Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Session Stats:
  • Tool calls: $TOOL_CALLS
  • Errors encountered: $ERRORS
  • Duration: $(($DURATION / 60)) minutes

Any skill refinements to capture from this session?
  → Run /refine-skills to document improvements
  → Or say "no refinements" to skip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
fi
```

### MCP Integration

```yaml
# MCP servers used by skill-refinement

required:
  - name: Desktop Commander
    purpose: Get recent tool calls, session context
    operations:
      - get_recent_tool_calls
      - get_file_info
      - read_file

optional:
  - name: Sentry
    purpose: Error context for pattern detection
    operations:
      - search_issues
      - get_issue_events
    
  - name: Zen
    purpose: Cross-project pattern persistence
    operations:
      - save_context
      - restore_context
      - search (for similar patterns)
    
  - name: Git (via bash)
    purpose: Change tracking
    operations:
      - git status
      - git diff
      - git log
```

---

## File Deliverables

### Skill Structure

```
claude-skills/skill-refinement/
├── SKILL.md                          # Main router document
├── README.md                         # Setup and usage guide
├── commands/
│   ├── refine-skills.md              # Main refinement command
│   ├── apply-generalization.md       # Apply queued generalizations
│   └── review-patterns.md            # Review tracked patterns
├── hooks/
│   ├── refinement-detector.sh        # Detect refinement opportunities
│   └── session-end.sh                # Post-session prompt
├── scripts/
│   ├── common/
│   │   ├── __init__.py
│   │   ├── models.py                 # Data models
│   │   └── persistence.py            # File + Zen MCP sync
│   ├── gather_context.py             # Context gathering
│   ├── analyze_gap.py                # Gap analysis
│   ├── generate_patch.py             # Patch generation
│   ├── apply_refinement.py           # Apply changes
│   ├── log_refinement.py             # Logging
│   ├── aggregate_patterns.py         # Pattern tracking
│   ├── sync_zen.py                   # Zen MCP sync
│   └── apply_generalization.py       # Merge to user-scope
├── templates/
│   ├── patch.md.template             # SKILL.patch.md template
│   ├── refinement-entry.md.template  # Log entry template
│   └── pattern-entry.md.template     # Pattern tracking template
└── references/
    ├── override-types.md             # Override type documentation
    ├── patch-syntax.md               # Patch action syntax
    └── generalization-criteria.md    # When to generalize
```

### User-Scope Setup

```
~/.claude/skill-refinements/          # Created on first use
├── suggested-refinements.md
├── refinement-history/
├── aggregated-patterns.md
├── generalization-queue.md
└── .zen-sync
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal:** Basic refinement capture and logging

- [ ] Create skill directory structure
- [ ] Write SKILL.md router
- [ ] Implement `refine-skills.md` command (manual mode)
- [ ] Create `log_refinement.py` for file-based logging
- [ ] Set up `~/.claude/skill-refinements/` structure
- [ ] Create basic templates

**Deliverables:** Working `/refine-skills` command with manual input, file logging

### Phase 2: Context Gathering (Week 2)
**Goal:** Automated context collection

- [ ] Implement `gather_context.py`
- [ ] Integrate Desktop Commander tool call retrieval
- [ ] Add Sentry error context (optional)
- [ ] Add git context gathering
- [ ] Update command to use gathered context

**Deliverables:** Context-aware refinement capture

### Phase 3: Analysis & Patching (Week 3)
**Goal:** Semi-automated analysis and patch generation

- [ ] Implement `analyze_gap.py`
- [ ] Add guided mode for ambiguous cases
- [ ] Implement `generate_patch.py`
- [ ] Create section-level patch format and parser
- [ ] Add diff preview generation

**Deliverables:** Semi-automated refinement with previews

### Phase 4: Pattern Aggregation (Week 4)
**Goal:** Cross-project pattern tracking

- [ ] Implement `aggregate_patterns.py`
- [ ] Add pattern matching logic
- [ ] Auto-trigger generalization at threshold
- [ ] Create `generalization-queue.md` workflow
- [ ] Implement `apply_generalization.py`

**Deliverables:** Pattern tracking, auto-generalization triggers

### Phase 5: Zen Integration (Week 5)
**Goal:** Dual persistence with Zen MCP

- [ ] Implement `sync_zen.py`
- [ ] Add cross-project pattern queries
- [ ] Implement conflict resolution
- [ ] Add sync status tracking
- [ ] Test offline/online scenarios

**Deliverables:** Full dual persistence, cross-project awareness

### Phase 6: Automation & Polish (Week 6)
**Goal:** Full automation integration

- [ ] Add `refinement-detector.sh` hook
- [ ] Add `session-end.sh` hook
- [ ] Update `skill-suggester.sh` integration
- [ ] Add `/apply-generalization` command
- [ ] Add `/review-patterns` command
- [ ] Comprehensive testing
- [ ] Documentation polish

**Deliverables:** Production-ready skill-refinement system

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Refinement capture time | < 2 minutes | Time from trigger to logged |
| Pattern detection accuracy | > 80% | Correct pattern matches |
| Generalization success rate | > 90% | Generalizations that work |
| Context gathering coverage | > 70% | Relevant context captured |
| User satisfaction | > 4/5 | Feedback ratings |

---

## Open Items & Future Enhancements

### For Future Consideration

1. **IDE Integration:** VS Code extension for refinement capture
2. **Team Sharing:** Shared refinement repositories for teams
3. **ML-Assisted Matching:** Better pattern matching with embeddings
4. **Refinement Rollback:** Undo refinements that don't work
5. **Metrics Dashboard:** Track refinement effectiveness over time

### Known Limitations

1. Section-level patches require consistent markdown structure
2. Cross-project patterns require Zen MCP for full functionality
3. Auto-generalization may miss edge cases (manual review important)

---

## Appendix: Example Refinement Flow

```
USER: "The duplicate-check hook keeps blocking my test fixtures"

CLAUDE: [Triggers /refine-skills]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 Skill Refinement Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I'll help you capture this refinement.

📋 Context Gathered:
  • Recent tool calls: 47 (including 3 blocked file creations)
  • Target skill: context-engineering
  • Affected: hooks/duplicate-check.sh

📝 Let me confirm the issue:

1. **What's being blocked?**
   Looks like files in __tests__/fixtures/ directories

2. **Expected behavior:**
   Test fixtures should be allowed even if they match component names

3. **Proposed fix:**
   Add exclusion pattern for test directories

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Does this capture your issue correctly? (yes/modify/more detail)

USER: "yes"

CLAUDE: [Generates patch]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 Proposed Changes
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Override Type:** Section Patch
**File:** .claude/skills/context-engineering/SKILL.patch.md

```diff
+ ## PATCH: hooks/duplicate-check
+ <!-- ACTION: insert-after "Only check paths" -->
+ 
+ # Exclude test directories
+ EXCLUDE_PATTERNS="${EXCLUDE_PATTERNS:-__tests__|fixtures|__mocks__|\.test\.|\.spec\.}"
+ if echo "$FILE_PATH" | grep -qE "($EXCLUDE_PATTERNS)"; then
+   exit 0
+ fi
```

🔮 Generalization:
  Potential: HIGH
  Pattern matches: 0 (new pattern - will track)

Apply this refinement?
  □ Apply as proposed
  □ Modify first
  □ Cancel

USER: "apply"

CLAUDE: [Applies refinement]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Refinement Applied: REF-2024-1204-001
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Created:
  .claude/skills/context-engineering/SKILL.patch.md

📝 Logged to:
  ~/.claude/skill-refinements/suggested-refinements.md
  ~/.claude/skill-refinements/refinement-history/2024-12-04-context-engineering-hook.md

🔮 Pattern Tracking:
  New pattern created: PATTERN-005 "test-directory-exclusion"
  Will auto-generalize when seen in 1 more project

💡 Next Steps:
  1. Test: Try creating a test fixture file
  2. Verify the hook no longer blocks it
  
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
