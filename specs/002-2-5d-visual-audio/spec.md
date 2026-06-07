# Feature Specification: 2.5D Visual & Audio Presentation

**Feature Branch**: `002-2-5d-visual-audio`

**Created**: 2026-06-06

**Status**: Draft

**Input**: User description: "Implement professional cutesy graphics, animations and a 2.5d art style. Cards should be displayed on the table. Only the available actions should be shown and the recommended action should be highlighted in the tutorial. There should be instrumental background music. Every action should have a sound effect."

## Clarifications

### Session 2026-06-06

- Q: Art rendering style (illustrated 2D vs low-poly 3D vs blends) → A: **Pure C — full low-poly 3D** for the table scene (room, furniture, dog characters, chips, cards, and shoe stack as simple 3D forms with real perspective and lighting); flat 2D UI overlay for the sidebar and contextual action controls only.
- Q: Visual refresh scope (which scenes get 3D vs 2D) → A: **Option D — Table 3D + shared 2D shell**. The table scene alone uses Pure C low-poly 3D; **Home, Setup, Tutorial, and all other menus** share one polished **2D UI kit** in the **Mix 2 sidebar style** (dark panel, bold colorful stat blocks, chunky typography, rounded action buttons).
- Q: Balance/advantage graphs placement → A: **Option B — overlay/drawer from sidebar**. Full balance and advantage charts open on demand via a sidebar button; the Mix 2 sidebar stays compact during play.
- Q: Narrow viewport sidebar behavior → A: **Option B — stacked layout**. On narrow viewports, the sidebar moves **above** the 3D table; shoe counter and critical stats remain visible without hiding behind a drawer.
- Q: Crowded table card legibility → A: **Option A with hover zoom** — auto-scale and fan cards per seat with minimum readable size and learner-hand priority; **hover (or focus) zoom** on any seat’s cards for closer inspection without extra clicks.
- Q: Music and sound-effect sonic direction → A: **Animal Crossing and Stardew Valley inspiration** — cozy life-sim palette (soft, melodic, gentle SFX); not jazz/speakeasy or harsh casino audio.

## Visual & Layout Direction

The table scene uses **Pure C low-poly 3D**; all other screens share a **unified 2D UI shell**
inspired by the **Mix 2 sidebar** reference.

### Shared 2D UI shell (all non-table screens + table sidebar)

- **Scope**: Home, Setup, Tutorial entry/coaching panels, options/audio controls, analytics
  access, and the **table sidebar** all use the same **2D visual language**—not low-poly 3D.
- **Mix 2 sidebar reference**: **Dark vertical panel** with clearly separated sections;
  **bold colorful blocks** for key stats (running count, true count, bankroll, recommended bet);
  **chunky high-contrast typography**; small **grid stat tiles** for hand/shoe progress; large
  **rounded rectangular buttons** for primary actions (e.g., options, analytics, confirm bet).
- **Consistency**: Menu screens (mode select, table setup, lesson picker) reuse the same panel
  styling, color accents, button shapes, and type hierarchy as the table sidebar so the app
  feels like one product—not a 3D table bolted onto unrelated menus.
- **Action controls**: Contextual play actions (hit, stand, etc.) at the table use the same 2D
  button style as menu buttons, placed near the learner's hand over the 3D scene.

### Analytics overlay (sidebar-triggered)

- **On-demand charts**: Balance and advantage graphs are **not** embedded in the compact sidebar;
  they open in a **full overlay or slide-out drawer** when the learner taps an **Analytics**
  control in the sidebar.
- **During play**: The overlay may be opened between hands or during a hand without blocking
  required play actions; closing it returns to the table view immediately.
- **Visual consistency**: The analytics overlay uses the **shared 2D UI shell** (Mix 2 style)—
  same panels, typography, and button shapes as the sidebar.

### Responsive layout (narrow viewports)

- **Desktop/tablet landscape**: **Side-by-side split**—Mix 2 sidebar on the left, 3D table
  play area on the right (default layout).
- **Narrow viewports** (tablet portrait, smaller widths): **Stacked layout**—the sidebar
  moves **above** the 3D table so the felt and cards retain usable width below.
- **Stat visibility**: Running count, true count, bankroll, and shoe remaining-card count MUST
  remain visible in the stacked top panel without requiring scroll before play actions.

### Crowded table legibility

- **Auto-scale and fan**: When many cards are on the table (multiple players, splits), cards
  **auto-scale down** and **fan per seat** before overlapping; the **learner’s hand** always
  receives **priority sizing** (largest cards on the felt).
- **Minimum readable size**: Auto-scaling MUST NOT shrink cards below a **minimum legible size**
  for rank and suit at the default camera angle.
- **Hover zoom**: Hovering (or keyboard focus) on any seat’s cards **zooms that hand** for closer
  inspection; zoom dismisses on hover/focus exit without blocking play actions.
- **Reduced motion**: Hover zoom MAY snap instantly when `prefers-reduced-motion` is enabled.

### Art style — Pure C (table scene only)

- **Rendering approach**: The table scene is rendered entirely as **simple low-poly 3D**—chunky
  cute geometry, soft warm lighting, toy-like polish (comparable to cozy indie 3D games)—not
  illustrated sprites or painted backdrops.
- **Dog characters**: Anthropomorphic dogs as **low-poly 3D models** seated around the table
  with friendly silhouettes and subtle idle/reaction animation.
- **Cards & props**: Playing cards, chips, and the shoe stack are **3D objects on the felt**;
  card faces use **clear, high-contrast textures** so rank and suit remain legible at the fixed
  camera angle.
- **Depth & lighting**: Real **3D perspective**, cast shadows, and a **single overhead lamp**
  create physical depth on the round table; tilt and fanning come from object placement in
  3D space rather than faux 2D layering.
- **UI layer**: The **sidebar** and **contextual action buttons** use the **shared 2D UI shell**
  (Mix 2 style)—the only non-3D layer in the table scene.

### Dogs Playing Poker (setting & mood)

- **Intimate poker room**: A warm, dimly lit **3D room** with deep wall tones, subtle ambient
  detail (e.g., framed wall art, a grandfather clock), and the overhead lamp casting a soft
  pool of light onto the table center—evoking classic *dogs playing poker* paintings without
  copying them literally.
- **Round table gathering**: A **circular wooden table** with green felt where dog characters
  sit around the perimeter—learner at the foreground, dealer and other players across the arc.
- **Table dressing**: 3D chip stacks in the betting area; optional cozy props (e.g., glasses)
  kept subtle so cards and counts remain the focus.

### Balatro & Mix 2 (layout & juice)

- **Split layout**: A **Mix 2-style sidebar panel** for session information (running count,
  true count, bankroll, bet recommendation, hand/shoe progress) and a **main play area** for
  the 3D felt, cards, and characters—mirroring Balatro's clear separation of *stats* vs *play*.
- **Shoe indicator**: A visible **3D shoe/deck stack** with a remaining-card counter so
  learners can connect shoe depth to true count visually.
- **Contextual actions**: Action buttons appear **near the learner's hand** only when legal
  (Balatro-style contextual controls), not as a permanent clutter of disabled options.
- **Game feel ("juice")**: Short, satisfying motion on interactions—hover wobble, deal snap,
  win sparkle, chip bounce—scaled to cutesy tone rather than Balatro's surreal intensity.
- **Bold legibility**: Sidebar and menu stats use **Mix 2-style** dark panels with **saturated
  accent color blocks** and chunky type so coaching data pops.

### Audio direction — Animal Crossing & Stardew Valley

Music and sound effects take inspiration from **Animal Crossing** and **Stardew Valley**—cozy
life-sim audio that matches the cutesy low-poly table and shared 2D UI—not traditional casino
or speakeasy sound design.

- **Background music**: **Soft, looping instrumental** tracks with gentle melody—acoustic guitar,
  piano, marimba, soft synth pads, light percussion—**mellow and repeatable** like a cozy
  village or quiet evening indoors; **no lyrics**; never loud or tense during coaching.
- **Mood fit**: Tracks should feel **warm, unhurried, and friendly**—as if dogs are gathering
  for a relaxed game night—not high-stakes Vegas energy.
- **Sound effects**: **Short, soft, satisfying** cues—muted card snaps, gentle chip clinks,
  cozy UI boops/chimes on button confirm, light sparkle or bell for wins, subdued sympathetic
  tones for losses—similar tactile feedback to **Animal Crossing / Stardew Valley** menu and
  activity sounds.
- **Mix balance**: Default music volume stays **below sound-effect prominence**, but both use
  the same gentle palette—no harsh transients, casino bells, or aggressive stingers.
- **Menus vs table**: The same sonic palette applies to **table BGM/SFX** and **menu UI sounds**;
  looping background music starts at the table scene per existing lifecycle rules.

## User Scenarios & Testing *(mandatory)*

### User Story 0 - Navigate with a Consistent 2D UI Shell (Priority: P1)

A learner moves between Home, Setup, Tutorial, and the table and recognizes a **consistent
2D interface**—dark panels, colorful stat blocks, rounded buttons—in the **Mix 2 sidebar
style**. Only the table play area switches to low-poly 3D; menus never require 3D assets.

**Why this priority**: Visual consistency across entry flows prevents a jarring split between
polished 3D play and ad-hoc menus; the shared shell is the connective tissue for the feature.

**Independent Test**: Can be tested by visiting Home → Setup → Table → Home and confirming
panel styling, typography, and button shapes match across screens while only the table center
is 3D.

**Acceptance Scenarios**:

1. **Given** any non-table screen, **When** the learner views it, **Then** it uses the shared
   2D UI shell (dark panel, bold stat blocks, rounded buttons)—not low-poly 3D.
2. **Given** the table scene, **When** the learner views the sidebar, **Then** it matches the
   same 2D shell styling as Home and Setup menus.
3. **Given** the learner opens options or audio controls from any screen, **When** the panel
   appears, **Then** it follows the shared 2D button and typography conventions.
4. **Given** the learner taps Analytics in the table sidebar, **When** the overlay opens,
   **Then** balance and advantage graphs display in the shared 2D shell and the compact sidebar
   remains unchanged underneath.
5. **Given** a narrow viewport, **When** the table scene loads, **Then** the sidebar stacks
   above the 3D table and critical stats (counts, bankroll, shoe counter) remain visible
   without scrolling.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_ui_theme.gd` | Shared theme tokens, screen classification |
| Functional | `godot/tests/functional/test_ui_shell_consistency.gd` | Shell applied per scene type |
| Integration | `godot/tests/integration/test_analytics_panel.gd` | Sidebar trigger → overlay graphs |
| Scene integration | `godot/tests/integration/test_presentation_flow.gd` | Home/Setup/Table sidebar styling match; analytics drawer |

---

### User Story 1 - Play on a Low-Poly 3D Table with Visible Cards (Priority: P1)

A learner sits at a **round felt table** in a cozy, lamp-lit **low-poly 3D poker room**
(*dogs playing poker* mood; Balatro-style layout). Playing cards appear as **3D objects on
the felt** in front of each dog character—face-up or face-down as rules dictate—so the
learner can read ranks and suits at a glance while practicing counting. Session stats
(counts, bankroll) live in a flat 2D sidebar separate from the 3D play area.

**Why this priority**: Visible cards on a believable table are the foundation of both gameplay
clarity and the requested visual upgrade. Without this, counting practice and immersion fail.

**Independent Test**: Can be fully tested by starting any hand in Tutorial or Free Play and
confirming that cards render on the table with readable faces, correct placement per seat,
and smooth deal/flip/collect animations—without requiring audio or action-highlight features.

**Acceptance Scenarios**:

1. **Given** a hand is dealt, **When** the learner views the table, **Then** each participant's
   cards appear on the felt in front of their seat with correct face-up/face-down orientation.
2. **Given** cards are on the table, **When** the learner inspects them, **Then** rank and
   suit are clearly legible at default zoom on reference desktop and tablet viewports.
3. **Given** a card state change (deal, hit, flip, split, collect), **When** the event occurs,
   **Then** a smooth animation moves or reveals the card without obscuring legibility.
4. **Given** any game screen showing the table, **When** the learner views the scene, **Then**
   the presentation shows a low-poly 3D lamp-lit room and round table, **seated stylized
   low-poly 3D dog characters** (procedural meshes or glTF—final art may ship in polish),
   3D cards on the felt with real perspective and shadows, a visible 3D shoe stack with
   **remaining-card count**, and a flat 2D sidebar for session stats—cohesive with the
   Visual & Layout Direction above.
5. **Given** cards are dealt to multiple seats, **When** hands contain more than one card,
   **Then** cards fan slightly on the felt while remaining legible.
6. **Given** many cards are on the table, **When** space is tight, **Then** cards auto-scale
   and fan per seat (learner hand largest) without falling below minimum legible size.
7. **Given** the learner hovers or focuses another seat’s cards, **When** inspection is needed,
   **Then** that hand zooms for closer reading and returns to normal on hover/focus exit.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_card_layout.gd` | Card visibility rules per seat and phase |
| Functional | `godot/tests/functional/test_table_card_layout.gd` | Placement, orientation, legibility thresholds |
| Integration | `godot/tests/integration/test_table_presentation.gd` | Hand events trigger correct card visuals |
| Scene integration | `godot/tests/integration/test_presentation_flow.gd` | Cards visible on table during live hand |

---

### User Story 2 - See Only Valid Actions (Priority: P1)

During play, the learner sees **only actions that are legal for the current hand state**,
presented as **contextual buttons near their hand** (Balatro-style). Unavailable actions
(e.g., split when cards don't match, double after a third card, hit after standing) are hidden—
not merely disabled—so the play area stays uncluttered and instructional.

**Why this priority**: Reducing noise in the action bar directly supports learning and matches
the user's explicit requirement; it prevents confusion about what can be done right now.

**Independent Test**: Can be tested by stepping through scripted hand states (insurance offer,
first-action double/split, post-hit restrictions, dealer phase) and verifying the visible
action set matches legal moves only.

**Acceptance Scenarios**:

1. **Given** it is the learner's first action on a pair, **When** split is legal, **Then**
   Split appears among the visible actions; when split is not legal, **Then** Split is absent.
2. **Given** the learner has already taken a hit, **When** double is no longer allowed,
   **Then** Double is not shown.
3. **Given** the dealer offers insurance, **When** the insurance prompt is active, **Then**
   only Accept Insurance and Decline Insurance (plus any other legal pre-action controls)
   are shown until resolved.
4. **Given** it is not the learner's turn, **When** other players or the dealer act,
   **Then** learner action controls are hidden.
5. **Given** the learner uses keyboard input, **When** an action is available, **Then**
   keyboard shortcuts map only to currently visible legal actions.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_action_menu.gd`, `godot/tests/unit/test_strategy.gd`, `godot/tests/unit/test_hand.gd` | Legal action derivation per hand state |
| Functional | `godot/tests/functional/test_action_visibility.gd` | Action set filtering across hand phases |
| Integration | `godot/tests/integration/test_practice_table.gd` | Domain hand state → visible action list |
| Scene integration | `godot/tests/integration/test_presentation_flow.gd` | UI shows/hides actions through a full hand |

---

### User Story 3 - Tutorial Highlights the Recommended Action (Priority: P1)

In **Tutorial mode**, when the lesson calls for a specific play, the **recommended action**
is visually distinguished among the visible legal actions with a **warm lamp-like glow**
(inspired by the overhead light in classic dogs-playing-poker scenes)—without forcing the
choice—so learners know what basic strategy suggests while still practicing the decision
themselves.

**Why this priority**: Tutorial effectiveness depends on guiding without overwhelming;
highlighting the recommended move is explicitly requested and pairs with filtered actions.

**Independent Test**: Can be tested in Tutorial lessons by reaching coached decision points
and verifying exactly one recommended action is highlighted when coaching is active, and
no highlight appears in Free Play.

**Acceptance Scenarios**:

1. **Given** a Tutorial lesson at a coached decision point, **When** legal actions are shown,
   **Then** the recommended basic-strategy action is visually highlighted and distinguishable
   from other visible actions.
2. **Given** a Tutorial lesson where no single strategy recommendation applies (e.g., bet
   sizing choice), **When** coaching is active, **Then** the recommended option per lesson
   script is highlighted instead.
3. **Given** Free Play mode, **When** the learner faces any decision, **Then** no recommended-
   action highlight is shown.
4. **Given** the learner selects a non-highlighted legal action in Tutorial, **When** the
   action resolves, **Then** coaching feedback explains the outcome without blocking progress
   unless the lesson requires retry.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_coaching_cue.gd`, `godot/tests/unit/test_strategy.gd`, `godot/tests/unit/test_tutorial.gd` | Recommended action per scenario |
| Functional | `godot/tests/functional/test_bet_coaching.gd` | Coaching highlight eligibility rules |
| Integration | `godot/tests/integration/test_table_presentation.gd` | Tutorial flag → highlight on action UI |
| Scene integration | `godot/tests/integration/test_tutorial_highlight.gd` | Highlight visible in lesson; absent in Free Play; non-highlight choice coaching feedback |

---

### User Story 4 - Hear Instrumental Background Music (Priority: P2)

While playing, the learner hears **looping instrumental background music** in a **cozy
life-sim style** inspired by **Animal Crossing** and **Stardew Valley**—soft, melodic, and
unhurried—pleasant and non-distracting during counting practice, with independent volume
control from sound effects.

**Why this priority**: Background music adds atmosphere but is secondary to visual clarity
and action UX; learners must be able to mute it without losing gameplay feedback.

**Independent Test**: Can be tested by entering the table, confirming music plays (when
sound is enabled), loops seamlessly, respects mute/volume settings, and pauses or stops
when leaving the table scene.

**Acceptance Scenarios**:

1. **Given** sound is enabled and the learner is at the table, **When** a session begins,
   **Then** gentle life-sim-style instrumental music (Animal Crossing / Stardew Valley mood)
   plays at a default comfortable volume.
2. **Given** background music is playing, **When** the track ends, **Then** it loops without
   an audible gap or pop on reference hardware.
3. **Given** the learner adjusts music volume or mutes music, **When** they continue playing,
   **Then** music responds immediately and the setting persists for the session.
4. **Given** the learner disables all sound, **When** they play, **Then** neither music nor
   sound effects play.
5. **Given** the learner navigates away from the table, **When** the table scene unloads,
   **Then** background music stops.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_audio_settings.gd` | Music mute/volume state |
| Functional | `godot/tests/functional/test_audio_cues.gd` | Music start/stop/loop behavior |
| Integration | `godot/tests/integration/test_table_presentation.gd` | Scene lifecycle → music control |
| Scene integration | `godot/tests/integration/test_audio_lifecycle.gd` | Music toggle and persistence |

---

### User Story 5 - Hear a Sound Effect for Every Action (Priority: P2)

Every learner-triggered and system-resolved **action category** produces a distinct, **soft
and satisfying** sound effect in the **Animal Crossing / Stardew Valley** mold—gentle UI chimes,
muted card/chip sounds, cozy confirm boops—covering betting, insurance accept/decline, hit,
stand, double, split, win, loss, push, blackjack, shuffle, chip movement, and UI confirmations.

**Why this priority**: Per-action audio reinforces learning moments and matches the requested
"satisfying" feel, but builds on the existing partial audio layer from the core game.

**Independent Test**: Can be tested by executing each action category once with sound enabled
and verifying a unique mapped effect plays; verifying mute suppresses all effects.

**Acceptance Scenarios**:

1. **Given** sound is enabled, **When** the learner performs each legal player action
   (bet, hit, stand, double, split, insurance accept/decline), **Then** a distinct, gentle
   life-sim-style sound effect plays at the moment of confirmation.
2. **Given** sound is enabled, **When** a hand settles (win, loss, push, blackjack), **Then**
   the outcome-specific sound plays once—a soft celebratory chime/sparkle for wins and subdued
   sympathetic tone for losses, consistent with Animal Crossing / Stardew Valley feedback.
3. **Given** sound is enabled, **When** the shoe reshuffles or chips move for a bet,
   **Then** an appropriate effect plays.
4. **Given** two actions occur in quick succession, **When** both have mapped sounds,
   **Then** effects do not clip unintelligibly (shorter sounds may overlap; critical
   feedback remains audible).
5. **Given** sound effects are muted but music is enabled, **When** the learner acts,
   **Then** only music plays; the inverse also holds.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_audio_action_map.gd` | Complete action-to-sound mapping |
| Functional | `godot/tests/functional/test_audio_cues.gd` | Each action category fires correct cue |
| Integration | `godot/tests/integration/test_table_presentation.gd` | Hand events → audio triggers |
| Scene integration | `godot/tests/integration/test_audio_lifecycle.gd` | Audible feedback on key actions |

---

### User Story 6 - Smooth Cutesy Animations Throughout (Priority: P2)

Motion design across the table—card flights, chip stacks, wins/losses, dog character reactions,
UI transitions—feels **smooth and polished** with Balatro-inspired "juice" (hover wobble, deal
snap, outcome sparkle) adapted to a cutesy tone, reinforcing engagement without slowing gameplay.

**Why this priority**: Animation quality defines the "professional" feel but depends on
cards-on-table and action UI being in place first.

**Independent Test**: Can be tested by playing a full hand and confirming animations complete
within acceptable duration, respect reduced-motion preference, and maintain readable card
state throughout.

**Acceptance Scenarios**:

1. **Given** standard motion preference, **When** a full hand plays out, **Then** deal,
   hit, flip, chip, and collect animations run smoothly without visible stutter on reference
   hardware.
2. **Given** `prefers-reduced-motion` is enabled, **When** any animated event occurs,
   **Then** motion is minimized or replaced with instant state changes while all information
   remains visible and gameplay stays fully usable.
3. **Given** an animation is in progress, **When** the learner needs to read card values,
   **Then** final card faces are never left illegible or off-table.
4. **Given** a win or loss, **When** the hand settles, **Then** a brief celebratory or
   sympathetic visual cue (dog reaction, chip bounce, sparkle or gentle screenshake) plays
   before the next hand prompt.
5. **Given** the learner hovers or focuses a visible action button, **When** the control is
   interactive, **Then** a subtle motion cue (wobble or scale) confirms it is selectable.

**Test Mapping** *(mandatory per constitution; Godot GUT + scene integration per constitution v3)*:

| Layer | Test File(s) | Scenarios Covered |
|-------|--------------|-------------------|
| Unit | `godot/tests/unit/test_motion_preference.gd` | Reduced-motion flag handling |
| Functional | `godot/tests/functional/test_table_card_layout.gd` | Animation skip vs full motion paths |
| Integration | `godot/tests/integration/test_table_presentation.gd` | Event → animation trigger wiring |
| Scene integration | `godot/tests/integration/test_presentation_flow.gd` | Reduced-motion path; hand completes with animations |

---

### Edge Cases

- What happens when many cards are on the table (multiple splits, five other players)—cards
  auto-scale and fan per seat; learner hand keeps priority; hover zoom available per seat.
- Does hover zoom work with keyboard focus for accessibility? **Yes** — keyboard focus on a seat’s cards triggers the same zoom as hover (FR-002d).
- What happens if auto-scale hits minimum size but overlap would still occur—does hover zoom
  become the primary inspection path for non-learner seats?
- How does the action bar behave during insurance when only two choices exist—are unrelated
  actions fully hidden?
- What happens when the recommended Tutorial action is also the only legal action—is it
  still highlighted for consistency?
- How does audio behave when the browser tab is backgrounded—music pauses per platform norms?
- What happens when sound assets fail to load—game continues silently with a non-blocking notice?
- How do keyboard shortcuts behave when the visible action set changes mid-hand?
- What happens on first visit before audio autoplay policies unlock—music starts after first
  user gesture without blocking play?
- How does reduced motion interact with tutorial highlight animations—highlight remains visible
  but non-pulsing?
- Does the sidebar remain readable when counts go negative or bankroll formats to large numbers?
- How does the round table layout accommodate five other players without crowding card legibility?
- On narrow viewports, the sidebar **stacks above** the 3D table—do critical stats and the
  shoe counter remain visible without scrolling?
- Can the learner open and close the analytics overlay without losing hand state or missing
  time-sensitive actions?
- Does the analytics overlay remain readable when opened over the 3D table on tablet viewports?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST render the **table play area** in **cutesy low-poly 3D** (Pure C)
  and render **all menus plus the table sidebar** in the **shared 2D UI shell** (Mix 2 style).
- **FR-001a**: System MUST use a **split layout** on the table scene: **Mix 2-style sidebar**
  for session stats (running count, true count, bankroll, bet guidance, hand/shoe progress)
  and main area for 3D felt, characters, and cards.
- **FR-001c**: System MUST apply the **shared 2D UI shell** consistently to **Home, Setup,
  Tutorial, options, audio controls, and analytics overlay**—same dark panel, stat blocks,
  typography, and rounded button style as the table sidebar.
- **FR-001d**: System MUST expose balance and advantage **graphs via a sidebar-triggered
  overlay or slide-out drawer**—not inline in the compact Mix 2 sidebar—and style the overlay
  with the shared 2D UI shell.
- **FR-001f**: System MUST use a **side-by-side split** (sidebar left, 3D table right) on
  desktop and tablet-landscape viewports, and a **stacked layout** (sidebar above, 3D table
  below) on narrow viewports.
- **FR-001g**: In stacked layout, running count, true count, bankroll, and shoe remaining-card
  count MUST remain **visible without scrolling** before the learner can take play actions.
- **FR-001b**: System MUST seat **low-poly 3D anthropomorphic dog characters** around a
  **circular 3D table** with green felt, warm overhead lighting, and cohesive 3D room dressing
  per Visual & Layout Direction.
- **FR-002**: System MUST display **3D playing cards on the felt** for the learner, dealer,
  and other players, with correct face-up/face-down orientation per blackjack rules.
- **FR-002a**: Cards MUST be **3D objects** placed with natural **perspective tilt** and **cast
  shadows** on the felt; card faces MUST use **legible high-contrast textures**; multi-card
  hands MAY fan in 3D space while staying readable at the fixed camera angle.
- **FR-002b**: System MUST show a **visible 3D shoe/deck stack** with **remaining-card count**
  updated as cards are dealt.
- **FR-002c**: When card density is high, system MUST **auto-scale and fan** cards per seat,
  enforce a **minimum legible card size**, and give the **learner’s hand priority sizing**.
- **FR-002d**: System MUST support **hover or keyboard-focus zoom** on any seat’s cards for
  closer inspection; zoom MUST dismiss without blocking legal play actions.
- **FR-003**: System MUST ensure card rank and suit are **legible** at default viewport sizes
  on supported desktop and tablet targets.
- **FR-003a**: Sidebar and menu stats MUST use **Mix 2-style** dark panels with **high-contrast,
  bold typography** and **saturated accent color blocks** for critical values (counts, bankroll,
  recommended bet).
- **FR-005b**: Contextual play-action buttons MUST use the **same 2D button style** as menu
  buttons (rounded rectangles from the shared UI shell).
- **FR-004**: System MUST animate card deal, flip, hit, split placement, and collection with
  smooth transitions that preserve legibility throughout each animation.
- **FR-005**: System MUST show **only legal actions** for the current hand phase; illegal
  actions MUST be hidden, not merely disabled.
- **FR-005a**: Legal actions MUST appear as **contextual controls near the learner's hand**,
  not as a permanent full action bar.
- **FR-006**: System MUST hide all learner action controls when it is not the learner's turn.
- **FR-007**: System MUST map keyboard shortcuts exclusively to currently visible legal actions.
- **FR-008**: System MUST, in **Tutorial mode only**, visually highlight the **recommended
  action** among visible legal actions at coached decision points using a **warm glow or
  accent** consistent with the table lamp aesthetic.
- **FR-009**: System MUST NOT show recommended-action highlights in **Free Play** mode.
- **FR-010**: System MUST allow learners to choose a non-highlighted legal action in Tutorial
  and receive coaching feedback afterward without hard-blocking unless the lesson script
  requires retry.
- **FR-011**: System MUST play **looping instrumental background music** at the table in a
  **cozy life-sim style** inspired by **Animal Crossing** and **Stardew Valley** (soft melody,
  acoustic or light electronic instrumentation, no lyrics)—with seamless loop and default
  volume balanced below sound-effect prominence.
- **FR-019**: System MUST apply **interaction juice** (hover wobble, deal snap, outcome
  feedback) on key events; juice MUST respect `prefers-reduced-motion`.
- **FR-012**: System MUST provide separate controls for **music volume/mute** and **sound-
  effect volume/mute** (or a master mute plus optional sub-controls).
- **FR-013**: System MUST play a **distinct sound effect** for each defined action category
  using the same **Animal Crossing / Stardew Valley-inspired** palette (gentle chimes, muted
  card/chip sounds, soft UI confirms—not harsh casino cues): bet confirm, insurance accept,
  insurance decline, hit, stand, double, split, win, loss, push, blackjack, shuffle/reshuffle,
  and chip movement.
- **FR-013a**: Menu and sidebar UI interactions (button press, toggle, panel open/close) MUST
  use **matching gentle UI sounds** from the same life-sim-inspired library.
- **FR-014**: System MUST stop background music when leaving the table scene.
- **FR-015**: System MUST honor `prefers-reduced-motion` by minimizing or disabling non-
  essential animations while keeping card states and action UI fully readable and operable.
- **FR-016**: System MUST respect browser autoplay policies—deferring music start until after
  the learner's first explicit interaction if required—without blocking gameplay.
- **FR-017**: System MUST continue gameplay silently if audio assets fail to load, with an
  optional non-blocking indicator that sound is unavailable.
- **FR-018**: System MUST persist audio preference settings (master mute, music/SFX levels)
  for the learner across sessions on the same device.

### Key Entities

- **Analytics Overlay**: Sidebar-triggered drawer/overlay showing balance-over-time and
  advantage-over-time charts; styled with the shared 2D UI shell; open/close state independent
  of hand lifecycle.
- **UI Shell**: Shared 2D design system (Mix 2 sidebar style)—dark panels, accent stat blocks,
  typography scale, rounded buttons—applied to Home, Setup, Tutorial, table sidebar, options,
  and contextual actions.
- **Table Presentation**: Visual layout of low-poly 3D round felt, lamp-lit room, dog character
  seats, chip stacks, shoe stack, 3D card positions per participant, and flat 2D sidebar stats
  panel; updated on every hand event.
- **Card Visual**: 3D card object with rank, suit texture, face-up state, seat owner, world
  position/rotation, and animation phase for each card instance on the table.
- **Action Menu**: The dynamic set of legal learner actions derived from hand state; drives
  both visible buttons and keyboard bindings.
- **Tutorial Coaching Cue**: Lesson-linked recommendation identifying which visible action
  (or bet option) should be highlighted and any post-choice feedback copy.
- **Audio Profile**: Learner preferences (master mute, music level, SFX level) and runtime
  state (playing, paused, autoplay unlocked).
- **Action Sound Map**: Mapping from action category identifiers to life-sim-inspired sound
  assets (Animal Crossing / Stardew Valley palette) and playback rules (one-shot, no overlap
  clipping for critical feedback).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In moderated usability checks, **90% of learners** correctly identify card
  rank and suit on the table without zooming during a standard hand.
- **SC-002**: Across scripted hand-state tests, **100% of illegal actions** are absent from
  the visible action menu (zero false positives showing unavailable actions).
- **SC-003**: In Tutorial coached steps, **100% of scripted recommendation points** display
  exactly one highlighted recommended action among visible legal choices.
- **SC-004**: A complete hand (deal through settlement) completes with smooth animations on
  reference hardware in **under 45 seconds** excluding learner think time.
- **SC-005**: With sound enabled, **100% of defined action categories** trigger their mapped
  sound effect in functional test coverage.
- **SC-006**: Background music loops without a gap or pop audible to testers in **95% of
  loop transitions** on reference hardware.
- **SC-007**: With `prefers-reduced-motion` enabled, learners complete a full hand with **no
  required timed animation waits** before taking the next action.
- **SC-008**: Learner satisfaction survey (or structured feedback) rates visual clarity and
  audio feedback at **4 out of 5 or higher** among pilot testers introduced to the feature.
- **SC-009**: In moderated review, **80% of testers** identify the presentation as evoking
  both a "cozy poker room with dogs" and a "clear card-game layout" without external prompting.

- **SC-010**: In cross-screen review, **90% of testers** report that Home, Setup, and table
  sidebar **look like the same product family** (consistent panels, colors, and buttons).

## Assumptions

- This feature **enhances** the existing blackjack card-counting tutorial game; core rules,
  counting logic, bet models, and persistence from the base product remain unchanged.
- **Scope split**: **Pure C low-poly 3D applies to the table play area only**; all menus and
  the table sidebar use the **shared 2D UI shell** (Mix 2 sidebar style)—no 3D assets for
  Home, Setup, or Tutorial screens.
- **Art style** is **Pure C — full low-poly 3D** for table-scene gameplay objects (room, table,
  dogs, cards, chips, shoe); UI chrome uses the shared 2D shell throughout.
- **Camera** is fixed or lightly constrained (not free-roaming) to keep card faces legible
  for counting practice.
- **Visual references** are *Dogs Playing Poker* (Cassius Coolidge) for setting and lamp-lit
  round-table mood; **Balatro** for split UI layout, shoe counter, contextual action placement,
  typography, and interaction juice—adapted to cutesy low-poly 3D rather than surreal or
  photorealistic tone.
- **Cutesy professional** tone uses chunky, friendly **low-poly dog models** with toy-like
  polish—approachable rather than photorealistic, gritty, or blocky-menacing.
- Recommended-action highlighting uses **non-blocking visual emphasis** (glow, outline, badge);
  the learner may always choose any visible legal action.
- Background music is **instrumental only** (no lyrics) in a **cozy life-sim style** inspired
  by **Animal Crossing** and **Stardew Valley**—soft, melodic, unhurried—not jazz, speakeasy,
  or traditional casino audio.
- Sound effects share the same inspiration: **gentle, tactile, satisfying**—never harsh bells,
  aggressive stingers, or high-stakes casino cues.
- Separate music and SFX volume controls are sufficient; per-category SFX sliders are out of
  scope unless added in a future feature.
- Audio autoplay restrictions are handled with a first-interaction unlock pattern standard for
  web games.
- Card legibility targets default desktop (1280×720 and above) and tablet landscape viewports
  already supported by the base product; **hover/focus zoom** supplements auto-scale on crowded
  tables.
- Existing accessibility expectations (keyboard operation, reduced motion) from the base
  product apply to all new presentation and audio behavior.

## Dependencies

- Requires the core playable blackjack table, Tutorial/Free Play modes, and hand/action domain
  logic from the base card-counting tutorial game to be functional.
- Art and audio assets (low-poly 3D room and table, lamp-lit environment, low-poly dog models,
  3D card meshes with legible face textures, **shared 2D UI shell** assets in Mix 2 sidebar
  style, 3D shoe stack, **Animal Crossing / Stardew Valley-inspired** music loop and SFX
  library) must be produced or sourced under appropriate licenses before final polish sign-off.
- Reference images and games (Dogs Playing Poker painting, Balatro screenshot, **Mix 2 mockup
  sidebar**, **Animal Crossing**, **Stardew Valley** audio direction) inform style only;
  the product MUST NOT reproduce copyrighted assets verbatim.
