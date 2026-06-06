# Feature Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`

**Created**: [DATE]

**Status**: Draft

**Input**: User description: "$ARGUMENTS"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - [Brief Title] (Priority: P1)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently - e.g., "Can be fully tested by [specific action] and delivers [specific value]"]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]
2. **Given** [initial state], **When** [action], **Then** [expected outcome]

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | [e.g., tests/unit/counting.test.ts] | [e.g., Hi-Lo values per rank] |
| Functional | [e.g., tests/functional/shoe.test.ts] | [e.g., shoe depletion behavior] |
| Integration | [e.g., tests/integration/lesson1.test.ts] | [e.g., lesson state + domain modules] |
| Playwright | [e.g., tests/e2e/lesson1.spec.ts] | [e.g., learner completes first drill in browser] |

---

### User Story 2 - [Brief Title] (Priority: P2)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | [path] | [scenarios] |
| Functional | [path] | [scenarios] |
| Integration | [path] | [scenarios] |
| Playwright | [path] | [scenarios] |

---

### User Story 3 - [Brief Title] (Priority: P3)

[Describe this user journey in plain language]

**Why this priority**: [Explain the value and why it has this priority level]

**Independent Test**: [Describe how this can be tested independently]

**Acceptance Scenarios**:

1. **Given** [initial state], **When** [action], **Then** [expected outcome]

**Test Mapping** *(mandatory per constitution)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | [path] | [scenarios] |
| Functional | [path] | [scenarios] |
| Integration | [path] | [scenarios] |
| Playwright | [path] | [scenarios] |

---

[Add more user stories as needed, each with an assigned priority and Test Mapping table]

### Edge Cases

- What happens when the shoe is exhausted or reshuffled?
- How does the system handle an incorrect running count submission?
- What happens when the player uses only keyboard input?
- How does the tutorial behave when `prefers-reduced-motion` is enabled?
- How are soft hands, splits, and blackjack payouts handled (if in scope)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST [specific capability, e.g., "deal cards from a configurable shoe with seedable RNG"]
- **FR-002**: System MUST [specific capability, e.g., "compute running count for the declared counting system"]
- **FR-003**: Users MUST be able to [key interaction, e.g., "complete a guided counting drill"]
- **FR-004**: System MUST [data requirement, e.g., "persist tutorial progress locally when specified"]
- **FR-005**: System MUST [behavior, e.g., "honor prefers-reduced-motion for card animations"]

*Example of marking unclear requirements:*

- **FR-006**: System MUST use [NEEDS CLARIFICATION: counting system — Hi-Lo only or selectable?]
- **FR-007**: System MUST achieve [NEEDS CLARIFICATION: performance target not specified]

### Key Entities *(include if feature involves data)*

- **[Entity 1]**: [What it represents, key attributes without implementation]
- **[Entity 2]**: [What it represents, relationships to other entities]

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: [Measurable metric, e.g., "All four test layers pass in CI for P1 stories"]
- **SC-002**: [Measurable metric, e.g., "Running count matches reference for 100% of scripted deals"]
- **SC-003**: [User satisfaction metric, e.g., "P1 tutorial completable without external instructions"]
- **SC-004**: [Accessibility metric, e.g., "Reduced-motion mode usable with static card reveals"]

## Assumptions

- [Assumption about target users, e.g., "Learners use modern desktop or tablet browsers"]
- [Assumption about scope boundaries, e.g., "Simulated play only; no real-money gambling"]
- [Assumption about data/environment, e.g., "Default counting system is Hi-Lo unless spec states otherwise"]
- [Dependency on existing system/service, e.g., "Requires Phaser 3.x and Playwright in dev toolchain"]
