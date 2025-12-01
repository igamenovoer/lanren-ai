# Known and Resolved Issues

## Purpose

This directory tracks both known (unfixed) and resolved (fixed) issues for the Lanren AI project.

## Structure

- **known/** - Ongoing, unfixed issues and current limitations
- **resolved/** - Issues that have been fixed, with notes on the resolution

## Contents

### Known Issues
Document current bugs, limitations, and ongoing problems that haven't been fixed yet. Include:
- Description of the issue
- Steps to reproduce
- Impact and severity
- Potential workarounds
- Investigation notes

### Resolved Issues
Archive of fixed issues with resolution details. Include:
- Original problem description
- Root cause analysis
- Solution implemented
- Lessons learned

## Naming Convention

Use status-based organization and descriptive filenames:
- `known/issue-gpu-oom-large-batch.md`
- `known/issue-slow-startup-on-windows.md`
- `resolved/issue-fixed-dataloader-deadlock.md`
- `resolved/issue-resolved-cuda-version-mismatch.md`

## Document Format

Every document should start with a HEADER section containing:
- **Purpose**: What this document is for
- **Status**: Current state (active/completed/deprecated/failed)
- **Date**: When created or last updated
- **Dependencies**: What this relates to or requires
- **Target**: Intended audience (AI assistants, developers, etc.)
