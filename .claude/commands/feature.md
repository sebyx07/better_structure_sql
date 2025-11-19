---
description: Build feature with documentation-first approach
argument-hint: [feature-name]
allowed-tools: Write, Read, Glob, Grep, Task
---

Build feature with documentation-first workflow.

## Documentation Structure

Create `docs/features/$ARGUMENTS/`:
- README.md: overview, use cases, configuration, examples
- architecture.md: components, responsibilities, interactions, dependencies
- plan/phase-N.md: objective, deliverables, tests, success criteria, dependencies

## Phase Planning

Each phase contains:
- Clear objective
- Specific deliverables
- Testing requirements
- Success criteria
- Phase dependencies

## Project Updates

- README.md: add concise feature description to features section
- CLAUDE.md: minimal keyword-rich context (concepts, patterns, integration points only - no code)

## Output Requirements

All documentation:
- Concise, scannable
- Keyword-rich for AI context
- Actionable acceptance criteria
- No code in CLAUDE.md
- Implementation details in feature docs only

Start with documentation, get approval, implement phases sequentially.
