# Design System Philosophy: The Kinetic Terminal

This design system is built for the high-performance athlete who views their body as a machine and the app as its diagnostic interface. We are moving away from the soft, rounded consumer "fitness" aesthetic toward the "Kinetic Terminal"—a visual language rooted in industrial precision, command-line interfaces, and professional gym equipment.
The Creative North Star is **Extreme Functionalism.** Every pixel must earn its place. We eschew the decorative for the descriptive. By utilizing a rigid 0px radius scale and high-contrast typography, we create an environment that feels authoritative, durable, and uncompromising.

---

## 1. Colors & Tonal Depth

This system operates in the shadows. The depth is not created by light, but by the subtle differentiation of dark surfaces.

### The Palette

- **Surface Foundation:** The `surface_container_lowest` (#0E0E0E) is our void. It represents the base of the interface.
- **The Action Accent:** We use `primary_container` (#C0392B) with surgical precision. It is a desaturated, "blood-red" that signifies effort, active states, and primary execution. It is never used for decoration; only for intent.
- **Text Hierarchy:**
- `on_surface` (White/Off-white) for critical data.
- `outline` (Muted Grey) for metadata, units (lbs/kg), and secondary labels.

### The "No-Line" Rule

Standard 1px borders are strictly prohibited for sectioning. They clutter the dense data layouts required for workout tracking. Instead, define boundaries through:

1. **Tonal Shifts:** Place a `surface_container` (#201F1F) card directly onto a `surface` (#131313) background.
2. **Negative Space:** Use the Spacing Scale (specifically `8` to `12`) to create "gutters" that act as invisible dividers.

### Surface Hierarchy & Nesting

Treat the UI as a machined part.

- **Level 0:** `surface_dim` for the global background.
- **Level 1:** `surface_container_low` for large content blocks or sidebars.
- **Level 2:** `surface_container_high` for interactive elements like input fields or active set rows.
- **Level 3:** `primary_container` (#C0392B) for the single most important action on the screen.

---

## 2. Typography: The Authority of Data

In this system, numbers are the primary UI elements. Typography must feel engineered, not "designed."

- **Display & Headlines (Space Grotesk):** Use for "Big Numbers" (weight lifted, reps, timers). These should be `display-lg` (3.5rem) or `headline-lg` (2.0rem) and set to **bold**. The technical, geometric nature of Space Grotesk mimics digital equipment readouts.
- **Body & Labels (Inter):** Use for technical data, exercise names, and logs. Inter provides the legibility required for high-density layouts.
- **Intentional Asymmetry:** Avoid centering text in large headers. Align everything to the hard left or right edges to evoke the feel of a technical manual or a terminal prompt.

---

## 3. Elevation & Depth: Sharp Layering

We reject shadows and rounded corners. This system is tactile through geometry, not softness.

- **The Layering Principle:** Depth is achieved by stacking. A `surface_container_highest` element sitting on a `surface_container_low` background creates a "mechanical" lift.
- **Zero-Radius Constraint:** Every corner is `0px`. This is non-negotiable. Sharp corners emphasize the "tool" aesthetic and allow for denser layouts without the wasted "corner air" of rounded designs.
- **The "Ghost Border" Fallback:** If a high-density table requires visual separation that tonal shifts cannot provide, use a `1px` line of `outline_variant` at 10% opacity. It should feel like a hairline trigger—barely there, but functionally distinct.

---

## 4. Components

### Buttons

- **Primary:** Solid fill `primary_container` (#C0392B) with `on_primary_fixed` text. Sharp edges. No hover glows—only a shift to a slightly brighter `primary` state.
- **Secondary:** Ghost style. No fill. A `1px` border using `outline` and `white` text.
- **Tertiary:** All caps text using `label-md`, no container.

### Input Fields

- Designed to look like a terminal entry. Use a `surface_container_highest` background.
- Instead of a full box, use a 2px bottom-bar of `outline` that turns `primary_container` (#C0392B) on focus.
- Labels should be `label-sm` and always visible (no floating labels).

### Workout Cards & Data Logs

- **Density over Beauty:** Pack information tightly. Use `title-md` for exercise names and `display-sm` for the primary weight/rep count.
- **The Grid:** Use a strict 4-column grid for set logging.
- Column 1: Set Number (Muted)
- Column 2: Weight (Bold/White)
- Column 3: Reps (Bold/White)
- Column 4: Status (Red accent checkmark)

### Chips (Tags)

- Rectangular. Background `surface_container_high`. Text `label-sm` in `on_surface_variant`. Use for muscle groups (e.g., [CHEST], [TRICEPS]).

---

## 5. Do's and Don'ts

### Do

- **Do** embrace monochromaticity. 90% of the app should be shades of black, grey, and white.
- **Do** use monospaced-style alignment. Keep numbers aligned in columns so users can scan their progress vertically.
- **Do** use `headline-lg` for timers. The passing of time should feel urgent and heavy.

### Don't

- **Don't** use gradients. Flat colors only. Gradients suggest a light source; this system is self-illuminated like a screen in a dark room.
- **Don't** use icons where text will suffice. A button that says `[ADD SET]` is more "pro-tool" than a `+` icon.
- **Don't** add "breathing room" just for the sake of it. While the layout shouldn't be cluttered, it should feel "pro-density"—efficient and information-rich.
- **Don't** use any corner radius. A single 4px corner breaks the industrial immersion.
