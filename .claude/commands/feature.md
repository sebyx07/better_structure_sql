---
description: Research project and generate feature documentation
argument-hint: [feature-name]
allowed-tools: Write, Read, Glob, Grep, Task
---

IMPORTANT: This is a RESEARCH and DOCUMENTATION tool only. It explores the codebase and generates planning markdown files. NO implementation.

## What This Does

1. **Explore codebase**: Uses Task agents to understand project structure, patterns, conventions
2. **Gather context**: Reads files to understand existing architecture
3. **Generate documentation**: Creates markdown planning files in `docs/features/$ARGUMENTS/`

## Generated Documentation Files

`docs/features/$ARGUMENTS/`:
- README.md: overview, use cases, configuration, examples
- architecture.md: components, responsibilities, interactions, dependencies
- plan/phase-N.md: objective, deliverables, tests, success criteria, dependencies

## Phase Documents Format

Each phase-N.md contains:
- Objective statement
- Deliverables list
- Testing requirements
- Success criteria
- Dependencies

## Project Documentation Updates

- README.md: add feature to features section
- CLAUDE.md: add minimal keyword-rich context (concepts, patterns, integration points - NO code)

## Documentation Standards

All generated files must be:
- Concise, scannable
- Keyword-rich for AI context
- Actionable criteria
- No code samples in CLAUDE.md
- Architecture details only in feature docs

## Process

1. Explore codebase
2. Generate documentation
3. Done - NO implementation happens in this command
