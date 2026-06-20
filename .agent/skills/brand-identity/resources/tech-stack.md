# ESSENZA Tech Stack & Implementation Rules
When generating code or UI components for this brand, you **MUST** strictly adhere to the following technology choices.

## Core Stack
* **Framework:** Next.js 14+ (App Router) - TypeScript.
* **Styling Engine:** Tailwind CSS.
* **Animation Engine:** Framer Motion (Mandatory for all interactions).
* **Scroll Engine:** Lenis (React wrapper) - strictly for "Butter-smooth" scrolling.
* **Icons:** Lucide React.

## Implementation Guidelines
### 1. Motion & Performance (High-End Standard)
* **GPU Acceleration:** Use `transform: translate3d(0,0,0)` or `will-change-transform` for heavy animations to ensure 60fps.
* **Reveal Animations:** All sections must use a "Blur-to-Focus" entrance effect using Framer Motion.
  - Example: `initial={{ opacity: 0, filter: "blur(10px)" }}`
* **Lazy Loading:** Use the `LazySection` component pattern for heavy UI parts.

### 2. Component Patterns
* **Styling:** Use Tailwind utility classes directly.
* **Glassmorphism:** Use `backdrop-blur-md` and `bg-opacity` for overlays/modals to maintain the modern aesthetic.
* **Layout:** Mobile-first, responsive grid/flex layouts.

### 3. Forbidden Patterns
* ⛔ Do NOT use standard CSS scrolling (always wrap in Lenis).
* ⛔ Do NOT use jQuery or Bootstrap.
* ⛔ Do NOT use `useEffect` for simple CSS animations (use Framer Motion).