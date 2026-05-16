<!--
SYNC IMPACT REPORT
==================
Version change: 1.0.0 → 1.1.0
Modified principles: None renamed
Added sections:
  - Core Principles: V. Documentation Language (zh-TW) — new principle
Removed sections: N/A
Templates updated:
  - ✅ .specify/memory/constitution.md — Principle V added, version bumped
  - ✅ .specify/templates/plan-template.md — Constitution Check gate V added
  - ✅ .specify/templates/spec-template.md — zh-TW authoring note added
  - ✅ .specify/templates/tasks-template.md — documentation language check task added
Follow-up TODOs: None — all placeholders resolved.
-->

# Demo Heat Pump Constitution

## Core Principles

### I. Code Quality (NON-NEGOTIABLE)

All code MUST meet defined quality standards before merging:

- Code MUST pass linter and static analysis checks with zero suppressed
  errors; any suppression MUST include an inline comment justifying the
  exception.
- Functions MUST have a single, clearly defined responsibility (Single
  Responsibility Principle).
- Cyclomatic complexity per function MUST NOT exceed 10.
- Code MUST be self-documenting; comments explain *why*, not *what*.
- Dead code, commented-out blocks, and unresolved TODO items older than
  one sprint MUST NOT be present in merged code.

**Rationale**: Consistent code quality prevents technical debt
accumulation and ensures long-term maintainability of the heat pump
control and simulation logic.

### II. Testing Standards (NON-NEGOTIABLE)

All features MUST be covered by automated tests before shipping:

- Unit test coverage MUST be ≥ 80% for all new or modified modules.
- Every user story MUST have at least one integration test covering the
  primary happy-path scenario.
- Tests MUST follow the Arrange-Act-Assert (AAA) pattern.
- Red-Green-Refactor cycle MUST be observed: tests are written and
  confirmed failing *before* implementation begins.
- Flaky tests MUST be resolved or removed immediately; flaky tests MUST
  NOT be committed to the main branch.

**Rationale**: Rigorous testing standards ensure correctness, enable
safe refactoring, and maintain confidence in heat pump control logic
where defects can affect equipment safety.

### III. User Experience Consistency

All user-facing interfaces MUST follow established design patterns:

- UI components MUST conform to the project's design system tokens
  (colors, spacing, typography, iconography).
- Error messages MUST be human-readable, actionable, and consistent in
  tone across the entire application.
- All user-facing workflows MUST be validated with at least one
  usability review before release.
- Breaking UX changes (navigation restructuring, label renames,
  workflow reordering) MUST be flagged in PR descriptions and reviewed
  by a second team member.
- Accessibility MUST meet WCAG 2.1 AA as the minimum standard for all
  new UI components.

**Rationale**: Consistent UX reduces cognitive load for field
technicians and end-users interacting with heat pump controls and
monitoring dashboards.

### IV. Performance Requirements

All features MUST meet defined performance thresholds before release:

- API responses and UI renders MUST complete in ≤ 500 ms at the p95
  percentile under typical load.
- Memory usage per service MUST remain within the documented budget;
  budgets MUST be defined in the plan's Technical Context section.
- Any regression in a tracked performance metric exceeding 10% MUST
  block merging until investigated and resolved.
- New database queries MUST be reviewed for index usage and query plan
  efficiency before merge.
- Performance benchmarks MUST be included in CI for changes touching
  critical paths (sensor data ingestion, control loop execution).

**Rationale**: Performance is a feature; latency and resource
regressions in heat pump monitoring directly degrade user experience
and system reliability.

### V. Documentation Language (NON-NEGOTIABLE)

All written artifacts targeting human readers MUST be authored in
Traditional Chinese (zh-TW):

- Feature specifications (`spec.md`), implementation plans (`plan.md`),
  and user-facing documentation (quickstart guides, README files,
  release notes) MUST be written in Traditional Chinese (zh-TW).
- Internal code comments and commit messages MAY be written in English
  where technical precision requires it, but SHOULD default to zh-TW.
- Error messages and UI copy visible to end-users MUST be in zh-TW.
- Locale/encoding MUST be UTF-8 for all documents; no simplified
  Chinese (zh-CN) characters MUST appear in user-facing text.
- Pull request descriptions referencing specifications MUST include a
  zh-TW summary of the change.

**Rationale**: The primary users and stakeholders of the Demo Heat Pump
project communicate in Traditional Chinese; consistent use of zh-TW
ensures clarity, reduces translation errors, and aligns documentation
directly with user needs.

## Quality Gates

### Pre-Merge Checklist

Every pull request MUST satisfy all of the following before merging:

- [ ] Linter passes with zero errors (no suppressions without justification)
- [ ] All unit and integration tests pass
- [ ] Test coverage ≥ 80% for changed modules
- [ ] No performance regression > 10% in any tracked metric
- [ ] UX changes reviewed and conformant with design system
- [ ] All spec, plan, and user-facing docs authored in Traditional Chinese (zh-TW)
- [ ] At least one peer code review approval obtained

### CI/CD Requirements

- CI pipeline MUST run on every pull request and MUST block merge on
  any failure.
- Deployment to a staging environment MUST precede every production
  release.
- Performance benchmarks MUST execute in CI for changes touching
  critical paths.

## Development Workflow

### Branch & Review Process

- Feature branches MUST follow the naming convention `###-feature-name`
  using sequential numbering (managed by `/speckit.git.feature`).
- Pull requests MUST reference the related spec and task IDs.
- All spec, plan, and task documents MUST be committed alongside the
  implementation they describe.

### Constitution Compliance

- The Constitution MUST be consulted at the start of every planning
  cycle (`/speckit.plan`) via the Constitution Check gate.
- Any deviation from a principle MUST be documented in the plan's
  Complexity Tracking section with a written justification.
- Principles marked **NON-NEGOTIABLE** MUST NOT be waived without a
  formal constitution amendment following the Governance process below.

## Governance

This Constitution supersedes all other development practices for the
Demo Heat Pump project. Amendments follow this process:

1. Propose the amendment via a PR updating `.specify/memory/constitution.md`.
2. The PR MUST include: motivation, affected principle(s), and a
   migration plan for in-flight work.
3. Approval requires at least one reviewer sign-off.
4. `CONSTITUTION_VERSION` MUST be incremented per semantic versioning:
   - **MAJOR**: Incompatible principle removal or redefinition.
   - **MINOR**: New principle or section added.
   - **PATCH**: Clarifications and non-semantic refinements.
5. `LAST_AMENDED_DATE` MUST be updated to the merge date (ISO 8601).

All PRs MUST verify compliance with this constitution. Unjustified
complexity violations MUST block merge until documented.

**Version**: 1.1.0 | **Ratified**: 2026-05-16 | **Last Amended**: 2026-05-16
