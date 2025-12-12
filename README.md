# Claude Skills Library

Reusable, project-agnostic skills for Claude Code development workflows.

## Available Skills

| Skill | Version | Description |
|-------|---------|-------------|
| [context-engineering](context-engineering/SKILL.md) | 2.0.0 | Session/memory management, automation hooks, context hygiene |
| [error-lifecycle-management](error-lifecycle-management/SKILL.md) | 2.0.0 | Error tracking, triage, validation with Sentry integration |
| [data-mutation-consistency](data-mutation-consistency/SKILL.md) | 2.0.0 | Enforce consistent mutation patterns (Vercel/Next.js/Supabase) |
| [dev-flow-foundations](dev-flow-foundations/) | 1.0.0 | Foundation documents for advanced workflow patterns |

## Quick Start

### Using Skills in Projects

**Option 1: Symlink (recommended for development)**
```bash
# From your project root
ln -s /path/to/claude-skills/context-engineering skills/context-engineering
```

**Option 2: Copy (for distribution)**
```bash
cp -r /path/to/claude-skills/context-engineering skills/
```

**Option 3: Reference in CLAUDE.md**
```markdown
## Skills

Load context-engineering skill from: /path/to/claude-skills/context-engineering/SKILL.md
```

### Installing Hooks

Most skills include automation hooks. Install to your project:

```bash
# Copy hooks
cp skills/context-engineering/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh

# Configure in .claude/settings.json
```

## Skill Overview

### context-engineering

Comprehensive context management for Claude Code sessions.

**Features:**
- Session lifecycle management (start → work → done)
- Memory extraction and retrieval patterns
- Automation hooks for duplicate prevention, skill suggestions
- Context hygiene for long sessions
- MCP integration patterns

**Key Files:**
- `SKILL.md` - Main router document
- `hooks/` - Automation scripts
- `commands/` - Workflow command definitions
- `references/` - Detailed documentation
- `scripts/` - Python automation helpers

### error-lifecycle-management

Production error handling from triage to resolution.

**Features:**
- Sentry integration for error tracking
- Validation scripts for error coverage
- React Query, Server Actions, API pattern validation
- Incident response templates
- Performance debugging patterns

**Key Files:**
- `SKILL.md` - Main router document
- `scripts/` - Validation scripts with configurable project support
- `reference/` - Error patterns, Sentry queries
- `templates/` - Incident response, triage summaries

### data-mutation-consistency

Enforce consistent data mutation patterns across Vercel/Next.js/Supabase stack.

**Features:**
- Mutation pattern scoring (9.0 warning, 7.0 critical thresholds)
- Auto-detected sub-skills (React Query, Payload CMS)
- Cross-layer validation (cache tags ↔ query keys)
- Sentry integration for stale data detection
- Zen MCP memory for cross-session awareness

**Key Files:**
- `SKILL.md` - Main router document
- `scripts/` - Python analysis and fix generation
- `hooks/` - Pre-write validation and keyword detection
- `commands/` - Slash commands (`@analyze-mutations`, `@check-mutation`, `@fix-mutations`)
- `sub-skills/` - React Query and Payload CMS patterns

### dev-flow-foundations

Advanced workflow patterns and best practices.

**Documents:**
- Dependency graph mapping
- Component registry patterns
- Context hygiene strategies
- Regression prevention
- Anti-pattern detection

## Directory Structure

```
claude-skills/
├── README.md                      # This file
├── SKILL.md                       # Master orchestrator
├── scripts/                       # Sync system
│   ├── sync-skills.sh             # Main sync script
│   └── sync-config.json           # Sync configuration
├── context-engineering/           # Context & session management
│   ├── SKILL.md
│   ├── hooks/
│   ├── commands/
│   ├── references/
│   └── scripts/
├── error-lifecycle-management/    # Error handling & validation
│   ├── SKILL.md
│   ├── scripts/
│   ├── reference/
│   ├── templates/
│   └── reports/
├── data-mutation-consistency/     # Mutation pattern enforcement
│   ├── SKILL.md
│   ├── scripts/
│   ├── hooks/
│   ├── commands/
│   ├── sub-skills/
│   ├── config/
│   └── templates/
└── dev-flow-foundations/          # Foundation documents
    ├── SKILL-dependency-graph-v1.md
    ├── SKILL-component-registry-v1.md
    ├── SKILL-context-hygiene-v1.md
    ├── SKILL-regression-prevention-v1.md
    └── ...
```

## Design Principles

1. **Project-Agnostic**: No hardcoded paths or project-specific references
2. **Configurable**: Environment variables and config files for customization
3. **Progressive Disclosure**: SKILL.md as router, details in references
4. **MCP-Integrated**: First-class support for MCP servers
5. **Automation-Ready**: Hooks and scripts for workflow automation

## Syncing Skills

The repository includes a sync system that automatically distributes skills to your Claude Code configuration when you push to GitHub.

### How It Works

```
git push origin main
       │
       ▼
┌──────────────────────────────┐
│  .git/hooks/pre-push         │
│  (triggers sync)             │
└──────────────────────────────┘
       │
       ▼
┌──────────────────────────────┐
│  scripts/sync-skills.sh      │
├──────────────────────────────┤
│  • Symlinks → ~/.claude/     │
│  • Copies → project/.claude/ │
└──────────────────────────────┘
       │
       ▼
   Push continues
```

### Setup

1. **Clone the repository** to your preferred location
2. **Configure sync targets** in `scripts/sync-config.json`
3. **Run initial sync**: `./scripts/sync-skills.sh`
4. **Push changes** - sync runs automatically via pre-push hook

### Configuration

Edit `scripts/sync-config.json` to register your projects:

```json
{
  "userScope": {
    "commands": { "enabled": true, "namespace": "skills", "mode": "symlink" },
    "hooks": { "enabled": true, "mode": "symlink" }
  },
  "projects": [
    {
      "path": "~/path/to/your/project",
      "namespace": "myproject",
      "enabled": true
    }
  ]
}
```

### Sync Modes

| Target | Method | Behavior |
|--------|--------|----------|
| User scope (`~/.claude/`) | Symlinks | Changes propagate immediately |
| Project scope | Copies | Isolated snapshots per project |

### Manual Sync

```bash
# Preview changes
./scripts/sync-skills.sh --dry-run

# Full sync
./scripts/sync-skills.sh

# User-level only (symlinks to ~/.claude/)
./scripts/sync-skills.sh --user-only

# Projects only (copies to registered projects)
./scripts/sync-skills.sh --projects-only
```

### Available Commands After Sync

Commands are installed to the namespace you configure (default examples shown):

| Command | Skill | Description |
|---------|-------|-------------|
| `/namespace:start` | context-engineering | Initialize development session |
| `/namespace:done` | context-engineering | Post-implementation validation |
| `/namespace:impact-map` | context-engineering | Pre-implementation dependency analysis |
| `/namespace:context-hygiene` | context-engineering | Context window management |
| `/namespace:mutation-analyze` | data-mutation-consistency | Full codebase mutation analysis |
| `/namespace:mutation-check` | data-mutation-consistency | Single file mutation check |
| `/namespace:mutation-fix` | data-mutation-consistency | Generate fix plan |
| `/namespace:refine-skills` | skill-refinement | Capture skill improvements |
| `/namespace:review-patterns` | skill-refinement | Review tracked patterns |
| `/namespace:apply-generalization` | skill-refinement | Promote to user scope |

> **Note**: Replace `namespace` with your configured value in `sync-config.json`.

## Creating New Skills

Use the skill-creator pattern:

```bash
# Initialize new skill structure
mkdir my-new-skill
cd my-new-skill

# Create standard structure
mkdir -p commands hooks references scripts templates

# Create main SKILL.md router
touch SKILL.md
```

## Version History

- **2.1.0** (2025-12): Added sync system with pre-push hook automation
- **2.0.0** (2024-12): Generalized skills, added hooks/commands, config system
- **1.0.0** (2024-11): Initial extraction from VBA project

## License

MIT License - See LICENSE file for details.
