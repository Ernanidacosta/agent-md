# Progress

## Current

Status: done
Task: Add a small auditable Risk Model that scales completion evidence.
Risk: medium

## Scope

- .claude/hooks/**
- .agent-md/bin/**
- .agents/skills/agent-md-verify/**
- .githooks/**
- .agent-md/templates/memory/**
- agent-md.toml.example
- tests/**

## Next

None

## Blockers

None

## Recently Completed

- Added a four-level Risk Model that scales final evidence without classifying implementation safety.
- Added one shared required/optional verification contract with timeout, evidence classes, doctor, and CLI support.
- Formalized progress validation, transition warnings, Scope warnings, structured gotchas, pruning, and handoff.
- Established the shared policy result and severity contract.
- Added configurable source classification shared by Stop and pre-commit.
