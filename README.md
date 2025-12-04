# Claude Skills Library

Reusable, project-agnostic skills for Claude Code development workflows.

## Available Skills

| Skill | Version | Description |
|-------|---------|-------------|
| [context-engineering](context-engineering/SKILL.md) | 2.0.0 | Session/memory management, automation hooks, context hygiene |
| [error-lifecycle-management](error-lifecycle-management/SKILL.md) | 2.0.0 | Error tracking, triage, validation with Sentry integration |
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

## Creating New Skills

Use the skill-creator pattern:

```bash
# Initialize new skill structure
python /path/to/skill-creator/init_skill.py my-new-skill

# Develop and test

# Package for distribution
python /path/to/skill-creator/package_skill.py my-new-skill
```

## Version History

- **2.0.0** (2024-12): Generalized skills, added hooks/commands, config system
- **1.0.0** (2024-11): Initial extraction from VBA project
