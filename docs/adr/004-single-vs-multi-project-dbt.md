# ADR-004: Single vs Multi-Project dbt

## Status
Accepted

## Context
Lighthouse has four business domains. dbt supports single-project and multi-project (Mesh) architectures.

## Decision
Single dbt project for MVP with domain-aligned groups and model access controls, preparing for future mesh decomposition.

## Rationale
- Simpler to develop, test, and deploy for a small team
- dbt groups and access controls enforce domain boundaries within one project
- Migration path is well-defined: extract groups into separate projects

## Consequences
- All domains share one CI/CD pipeline
- Domain boundaries enforced by `access: protected` on intermediate models
- See `docs/data-mesh-evolution.md` for the migration plan
