# Native App Design Language — Johnny Hockin / Juniper Island

## Purpose

This document is a design context brief. Drop it into any conversation where you're helping me design a macOS or iOS app interface. It defines the aesthetic I'm going for, the principles that drive it, and common mistakes to avoid.

---

## Design Identity: "QuickTime Confidence"

My apps should feel like they shipped with the OS. Not like a web app crammed into a native shell, not like a developer's side project — like something Apple forgot to include.

The north star references:
- **QuickTime Player** — hero action dominates, controls are whisper-quiet
- **Apple's native panel windows** — clean, content-first, no unnecessary UI furniture
- **SubOne / SuperCut** — extreme negative space, distilled typography, everything breathes
- **Liquid glass / vibrancy** — Apple's material design language (NSVisualEffectView, .ultraThinMaterial)

If QuickTime and a luxury magazine had a baby raised by SF Pro, that's the vibe.

---

## Core Principles

### 1. The Hero Action Owns the Window

Every app has one primary action. That action should dominate the interface — it gets the most space, the most visual weight, and the most breathing room. Everything else is secondary and should feel like it could disappear without the app breaking.

**Rule of thumb:** If someone glanced at the window for half a second, they should immediately know what the app does and how to do it.

### 2. Native Above All

- **SF Pro / system font only.** No custom fonts. Ever. System fonts at the right weight and size are the most elegant thing on macOS.
- **System colors when possible.** Use `Color.accentColor`, `.secondary`, `.tertiary` — not custom hex values unless there's a strong reason.
- **Standard controls** unless a custom control genuinely improves the interaction. A native Toggle is almost always better than a custom switch.
- **Respect platform idioms.** If macOS does something a certain way (like how panels work, how sheets appear, how sidebars behave), follow that pattern.

### 3. Hierarchy Through Space and Opacity First

Borrowed from my web pattern "Iconic Simplicity" — the default instinct should be to create hierarchy through layout position, whitespace, and opacity rather than through dramatic font size changes or bold weights. That said, if a genuine UX reason calls for a different approach, follow the logic — this is a strong preference, not a religion.

**Default to this:**
- Primary elements at full opacity
- Secondary elements at 0.5–0.6 opacity or using `.secondary` / `.tertiary` foreground styles
- Generous spacing between groups (16–24pt between sections)
- Let the hero element have disproportionate space

**Avoid this:**
- Multiple competing font sizes fighting for attention
- Bold weights as the primary tool for emphasis
- Labels + helper text + hints all stacked on the same element
- Cramming elements to "fit more in"

### 4. Extreme Negative Space

Elements should float. The window should feel like it has room to breathe. If it feels tight, it's wrong.

- Prefer fewer elements with more space over more elements packed in
- Content should never touch the edges of its container without generous padding
- Groups of controls should have clear separation — whitespace is the divider, not lines or borders
- If you're debating whether to add more padding, add more padding

### 5. Avoid Unnecessary Sizzle

- **Avoid toolbar icons** unless they genuinely help. Prefer a clean panel look.
- **No heavy borders or dividers.** If you need separation, use spacing or a very subtle background difference.
- **Make decorative elements count.** If a visual flourish is there, it should be doing real work — creating delight, clarifying hierarchy, or reinforcing the brand. Don't add ornament for the sake of it.
- **Minimal or no window title.** If the app's purpose is obvious from its content, the title bar can be transparent/empty.
- **Transparent titlebar** with `.titlebarAppearsTransparent = true` when appropriate

### 6. Liquid Glass / Vibrancy

Where appropriate, use Apple's material/vibrancy system:
- `NSVisualEffectView` for window backgrounds on macOS
- `.ultraThinMaterial` or `.regularMaterial` in SwiftUI
- Subtle translucency that lets the desktop bleed through
- This creates depth and makes the app feel integrated with the system

---

## Typography Rules for Native Apps

```
Font:           SF Pro (system font) — never override this
Weight:         .regular for most text, .light for large display text, .medium sparingly for key labels
Title text:     .title2 or .title3 — not .largeTitle unless it's truly a splash/hero
Body text:      .body or .callout
Secondary:      .subheadline or .footnote, with .secondary foreground
```

**Sizing guidance:**
- Don't use more than 2–3 text styles in a single view
- Prefer Apple's built-in text styles (.title, .body, .caption) over custom sizes
- If you're setting a specific font size in points, you probably shouldn't be

**Weight guidance:**
- `.regular` (400) is the workhorse
- `.light` (300) for oversized display text or a calm, editorial feel
- `.medium` (500) only for small labels that need to hold their own (e.g., a status badge)
- `.bold` almost never — if something needs emphasis, give it space or full opacity instead

---

## Color Rules

### Dark Mode Preferred, But Design for Both
Dark mode is the starting point — design there first, then make sure light mode holds up too. Use system semantic colors (`.primary`, `.secondary`, `Color(.systemBackground)`) so both modes work naturally. Only force a dark-only appearance if the app's identity truly demands it.

### Accent Colors
Use sparingly and purposefully:
- One accent color for the hero action (e.g., red for Record, blue for primary actions)
- System colors for interactive elements (toggles, sliders)
- Monochrome for everything else

### Background Layers (Dark Mode)
```
Window background:    Vibrancy material or very dark (#1C1C1C / NSColor(white: 0.11))
Card/group background: Slightly lighter than window (rgba white 0.04–0.06)
Card borders:         1px rgba white 0.08–0.10 (barely visible)
```
In light mode, invert the logic: use system background colors and `rgba black` at similar low opacities for subtle card surfaces.

### Text Colors
```
Primary text:     .primary (full white in dark mode)
Secondary text:   .secondary (~60% opacity)
Tertiary text:    .tertiary (~30% opacity)
Disabled:         .quaternary
```

---

## Layout Principles

The layout should serve one goal: **make the app hyper-fast for power users who open it daily, and immediately clear for someone who's never seen it.**

That means the primary action is always obvious, secondary controls stay out of the way but are findable, and the overall structure feels inevitable — like it couldn't have been arranged any other way.

### Useful Starting Points

These are patterns to reach for, not rules to follow rigidly. Let the app's actual purpose drive the layout.

**The "Panel" Window** — for compact utility apps:
- Transparent titlebar, no toolbar
- Content starts immediately
- Fixed or semi-fixed size
- Works well with vibrancy

**The "Hero + Controls" Layout** — when there's one dominant action:
```
┌─────────────────────────────┐
│                             │
│                             │
│       [ HERO ACTION ]       │  ← Big, centered, lots of breathing room
│                             │
│                             │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │  ← Visual separation (space, not a line)
│                             │
│    secondary control        │
│    secondary control        │  ← Quieter, compact, clearly optional
│    secondary control        │
│                             │
│    [ status / info ]        │  ← Footer-level info, lowest hierarchy
│                             │
└─────────────────────────────┘
```

### Spacing Scale
```
Tight (within a group):     8pt
Standard (between items):   12–16pt
Section break:              24–32pt
Hero breathing room:        40–60pt above and below
Window padding:             20–24pt from edges
```

---

## Control Styling

### Sliders
- Use native SwiftUI `Slider` with `.tint()` for color
- Show the current value as a label (in the accent color) near the slider
- If the slider has discrete stops, show tick labels underneath
- Don't over-style — a tinted native slider is perfect

### Toggles / Segmented Controls
- Native `Toggle` or `Picker` with `.segmented` style
- For binary choices (30fps/60fps), a segmented control is better than a toggle
- For on/off, use a standard Toggle

### Buttons
- **Hero button:** Larger, filled with accent color, generous padding (at least 12pt vertical, 24pt horizontal), rounded corners (10–12pt radius)
- **Secondary buttons:** Text-only or subtle bordered style
- **Destructive actions:** Use `.destructive` role — don't invent your own red

### Cards / Grouped Sections
- Background: `Color.white.opacity(0.04)` to `0.06` on dark backgrounds
- Border: `1px` at `Color.white.opacity(0.08)`
- Corner radius: `10–12pt`
- Internal padding: `16pt`
- **Never stack too many cards.** If you have more than 2–3 card groups, rethink the layout.

---

## Common Anti-Patterns to Avoid

### ❌ The Dashboard Trap
Don't turn a simple utility into a dashboard with cards and metrics everywhere. If the app does one thing, the interface should reflect that.

### ❌ Web Aesthetics in Native Clothing
- No gradient backgrounds that don't match system materials
- No custom fonts
- No hover-glow effects or CSS-style animations
- No card-heavy layouts that feel like a React dashboard

### ❌ Over-Labeling
If a control is a clearly-labeled slider next to the word "Quality," you don't also need a tooltip, helper text, and an info icon. Trust the user.

### ❌ Competing for Attention
If multiple elements are "loud" (bright colors, large sizes, animations), nothing stands out. Only the hero action should be loud. Everything else whispers.

### ❌ ScrollView When You Don't Need One
If the content can fit in the window, don't wrap it in a ScrollView. Fixed layouts feel more intentional and app-like.

### ❌ Too Many Settings Visible
Show the essential controls. If there are advanced settings, put them behind a disclosure or a separate view. Don't make power-user controls compete with the core experience.

---

## Window Manager Guidance (macOS)

```swift
// Panel-style window setup
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 440, height: 600),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.appearance = NSAppearance(named: .darkAqua)
window.backgroundColor = NSColor(white: 0.11, alpha: 1.0)
window.titlebarAppearsTransparent = true
window.contentMinSize = NSSize(width: 440, height: 400) // Don't over-constrain height
```

- Set a reasonable default size, but let content drive it
- Minimum width matters more than minimum height
- Don't make windows resizable unless the content benefits from it
- Center on screen on first launch

---

## The TE Dial: Teenage Engineering Influence

My designs are influenced by Teenage Engineering's philosophy — playful minimalism, limitation as liberation, tactile joy, and the idea that professional tools can feel like beautiful toys. This influence exists on a spectrum. At the start of any design conversation, I may specify a **TE level** from 0–5 to indicate how much of this flavor to inject.

### The Scale

| Level | Name | Description |
|-------|------|-------------|
| **0** | **Pure Apple** | No TE influence. Strict native macOS/iOS conventions. QuickTime purity. |
| **1** | **Subtle Wink** | Mostly native, but with one or two moments of delight — a satisfying micro-interaction, an unexpectedly playful empty state, a single bold color choice. |
| **2** | **Warm Native** | Native foundation with TE sensibility woven through. Slightly more opinionated typography, a hint of personality in iconography, controls that feel a touch more physical/tactile. **This is the default if no level is specified.** |
| **3** | **Confident Play** | The app clearly has a point of view. Custom controls that feel like hardware knobs/buttons. Deliberate constraints (fewer options, not more). A retro-futuristic accent — maybe a monospaced readout, a single unexpected material texture, or a distinctive interaction pattern. |
| **4** | **Full TE Energy** | The app feels like a Teenage Engineering product on screen. Hardware-inspired UI (toggle switches, LED-style indicators, physical metaphors). Anti-brand aesthetic — stripped of conventional app chrome. Playful but uncompromising. Think: OP-1 screen UI translated to macOS. |
| **5** | **Art Object** | The app itself is a statement piece. Unconventional layout, extreme minimalism pushed to the edge of usability, materials and interactions that prioritize emotional response over convention. Portfolio-level design. Use rarely. |

### How TE Principles Map to Implementation

**Playful Functionality (levels 2+):**
- Interactions should have a moment of satisfaction — a button that feels "clicked," a slider that snaps to values with intent
- Empty states and onboarding should charm, not instruct
- The app should feel like something you *want* to use, not something you *have* to use

**Limitation as Liberation (levels 1+):**
- Fewer controls, more mastery. If a setting can have a smart default, hide it.
- Constraints are features. A 3-stop slider (Low / Medium / High) is often better than a 0–100 range.
- Don't expose every option. Opinionated defaults signal confidence.

**Anti-Brand Minimalism (levels 3+):**
- Strip away conventional chrome — no "About" screens with logos, no splash screens
- UI elements can reference industrial/hardware design: monospaced type for readouts, segmented displays, toggle switches
- The interface itself is the brand. No need for logos or branding within the app.

**Tactile / Physical Feel (levels 3+):**
- Controls should feel like they have weight — sliders with detents, buttons with visual "press" states
- Consider subtle haptics on iOS (`.impact(.light)` on meaningful interactions)
- Visual affordances that suggest physical materials: slightly recessed controls, raised buttons, surface texture through shadow

**Retro-Futuristic Accents (levels 4+):**
- Monospaced fonts for data readouts (SF Mono for numbers/timers)
- LED-style status indicators instead of standard badges
- Color palette can shift toward warmer, analog tones — ambers, warm whites, muted oranges
- Skeuomorphic elements used sparingly and intentionally (a VU meter, a tape counter, a hardware-style knob)

### Example: Same Control at Different TE Levels

**A recording duration display:**

| Level | Implementation |
|-------|---------------|
| 0 | `Text("12:34")` in `.body` with `.secondary` color |
| 2 | `Text("12:34")` in `.title3` with `.monospacedDigit()`, slightly warm white |
| 4 | `Text("12:34")` in SF Mono, styled like a seven-segment display, amber on dark |
| 5 | Custom drawn seven-segment numerals with subtle glow, pixel-level precision |

### Using the Dial

At the start of a design conversation, say something like:
- *"TE level 1 for this one — keep it clean Apple with just a touch of personality"*
- *"Let's go TE 3 — I want this to feel like a Teenage Engineering product"*
- *"TE 0 — pure native, no flourishes"*

If no level is specified, **default to TE 2** (Warm Native).

---

## Reference Apps and Products to Study

When in doubt, look at how these handle similar problems:

**Apple (TE 0–1):**
- **QuickTime Player** — hero record/play action, minimal controls
- **Screenshot.app** — floating panel, simple options, no sizzle
- **Messages** — how density and whitespace coexist, conversation as the hero
- **Calendar** — clean information hierarchy, lots of data but never overwhelming
- **Photos** — content-first browsing, controls appear when needed and vanish when not
- **Shortcuts** — visual clarity in a complex automation tool, smart use of color and iconography
- **Digital Color Meter** — tiny utility, no wasted space
- **Keynote Presenter Display** — large hero content, subtle controls underneath

**Teenage Engineering (TE 3–5):**
- **OP-1 field screen UI** — playful animations, hardware metaphors on screen, extreme constraint
- **Pocket Operator** — one screen, total clarity, limitation is the feature
- **TP-7 field recorder** — minimal physical controls, beautiful materials, every interaction is intentional
- **Their website (teenage.engineering)** — anti-brand web design, monospaced type, industrial grid

---

## Design Review Checklist

Before finalizing any view, run through this:

- [ ] Can I identify the hero action in under 1 second?
- [ ] Does the hero have enough breathing room?
- [ ] Is the app hyper-fast for repeat users and immediately clear for new ones?
- [ ] Am I using system font with appropriate built-in text styles?
- [ ] Are there more than 3 text sizes? (If yes, question why)
- [ ] Is hierarchy coming primarily from spacing/opacity?
- [ ] Does it feel native — could it pass for an Apple app?
- [ ] Is there a ScrollView that could be eliminated?
- [ ] Are there borders/dividers that could be replaced with space?
- [ ] Does every decorative element earn its presence?
- [ ] Does it look great in dark mode? Does it hold up in light mode?
- [ ] Am I using vibrancy/materials where appropriate?
- [ ] Would this feel at home next to Messages, Calendar, and Photos?

---

## Revision History

- **2026-02-12** — Initial version. Synthesized from Iconic Simplicity web pattern and Clipcast redesign session.
- **2026-02-12** — Added TE Dial system (Teenage Engineering influence spectrum, levels 0–5, default 2).
- **2026-02-12** — Generalized away from app-specific examples. Softened dogmatic language throughout. Reframed layout around speed/clarity. Expanded Apple reference apps. Adjusted dark/light mode guidance.
- **Context:** Emerged from Clipcast (screen recording app) UI redesign with Claude Code, influenced by SubOne reference, QuickTime simplicity, and Teenage Engineering's playful minimalism.
