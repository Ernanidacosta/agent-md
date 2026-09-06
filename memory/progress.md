# Progress

## Current

Status: done
Task: Harden the verification contract with objective required evidence.

## Scope

- .claude/hooks/**
- .agent-md/bin/**
- .agents/skills/agent-md-verify/**
- .githooks/**
- agent-md.toml.example
- tests/**

## Next

None

## Blockers

None

## Recently Completed

- Added one shared required/optional verification contract with timeout, evidence classes, doctor, and CLI support.
- Formalized progress validation, transition warnings, Scope warnings, structured gotchas, pruning, and handoff.
- Established the shared policy result and severity contract.
- Added configurable source classification shared by Stop and pre-commit.
- Preserved third-party Claude and Codex hooks through idempotent merge.
