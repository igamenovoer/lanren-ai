# Task Management

## Purpose

This directory tracks work items organized by status, providing a clear view of current, completed, and planned work.

## Structure

- **working/** - Tasks currently in progress with active development
- **done/** - Completed tasks moved here for archival and reference
- **backlog/** - Planned tasks awaiting prioritization and implementation

## Contents

Task files can include any type of work:
- Feature implementations
- Bug fixes
- Refactoring work
- Test development
- Documentation updates
- Performance optimizations

## Naming Convention

Organized by status with clear descriptive names:
- `working/task-implement-user-authentication.md`
- `working/task-fix-memory-leak.md`
- `done/task-modernize-api-endpoints.md`
- `backlog/task-add-integration-tests.md`

## Workflow

1. New tasks start in `backlog/`
2. Move to `working/` when actively developing
3. Move to `done/` when completed
4. Only one task should typically be in `working/` at a time

## Best Practices

- Keep task descriptions clear and specific
- Update status promptly as work progresses
- Archive completed tasks regularly
- Review backlog periodically
- Link related tasks, plans, and issues

## Document Format

Every document should start with a HEADER section containing:
- **Purpose**: What this document is for
- **Status**: Current state (active/completed/deprecated/failed)
- **Date**: When created or last updated
- **Dependencies**: What this relates to or requires
- **Target**: Intended audience (AI assistants, developers, etc.)
