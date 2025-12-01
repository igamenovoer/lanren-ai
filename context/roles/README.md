# Role-Based Context

## Purpose

This directory contains role-based system prompts, memory, and context for different AI assistant personas. Each role has its own subdirectory with specialized prompts and accumulated knowledge for that specific role or domain expertise.

## Structure

Each role should have its own subdirectory containing:
- `system-prompt.md` - Role-specific instructions and behavior
- `memory.md` - Accumulated knowledge and session notes
- `context.md` - Domain-specific context and references
- `knowledge-base.md` - Specialized expertise and patterns

## Example Roles

- `backend-developer/` - Backend development expertise
- `frontend-specialist/` - UI/UX and frontend focus
- `devops-engineer/` - Infrastructure and deployment
- `data-scientist/` - ML/AI and data analysis
- `security-auditor/` - Security review and testing

## Naming Convention

- `roles/backend-developer/system-prompt.md`
- `roles/backend-developer/memory.md`
- `roles/frontend-specialist/context.md`
- `roles/devops-engineer/knowledge-base.md`

## Best Practices

- Keep role definitions focused and specific
- Update memory files after significant sessions
- Document domain-specific patterns and preferences
- Cross-reference related roles when applicable

## Document Format

Every document should start with a HEADER section containing:
- **Purpose**: What this document is for
- **Status**: Current state (active/completed/deprecated/failed)
- **Date**: When created or last updated
- **Dependencies**: What this relates to or requires
- **Target**: Intended audience (AI assistants, developers, etc.)
