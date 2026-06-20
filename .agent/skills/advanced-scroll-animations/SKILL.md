---
name: advanced-scroll-animations
description: Implements high-end, smooth scrolling and complex scroll-triggered animations using Lenis, GSAP, or Framer Motion. Use when building a Premium tier site that needs dynamic elements that reveal or transform on scroll.
---

# Advanced Scroll Animations Skill

## When to use this skill
- When the `tier-based-architecture` skill calls for a "Premium 2D" or higher tier website.
- When the user asks for elements to fade in, slide up, scale, or pin as the user scrolls down the page.
- When building a storytelling-focused landing page (e.g., Apple-style product reveals).

## Tone & Language Guidelines (Critical)
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Be professional but approachable: "يا هلا"، "رتبتلك السكرول"، "الأنيميشن صار جاهز".
- Explain technical choices naturally in Arabic mixed with English web terms: "رح نستخدم `Framer Motion` عشان حركات السكرول تطلع Smooth".

## 1. Setup & Foundations
*If these libraries are missing, install them: `@studio-freight/lenis` (for smooth scrolling base) and `framer-motion` (for component-level animations).*

### Lenis Smooth Scroll Configuration
Every site using this skill **must** have a smooth scrolling base to ensure animations feel premium.
- Setup `Lenis` in a top-level component (e.g., `SmoothScrollProvider.tsx` or `layout.tsx`).

```tsx
// Example Lenis Setup
"use client";
import React, { useEffect } from 'react';
import Lenis from '@studio-freight/lenis';

export default function SmoothScroll({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.2,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: 'vertical',
      gestureOrientation: 'vertical',
      smoothWheel: true,
      wheelMultiplier: 1,
      touchMultiplier: 2,
    });

    function raf(time: number) {
      lenis.raf(time);
      requestAnimationFrame(raf);
    }
    requestAnimationFrame(raf);

    return () => {
      lenis.destroy();
    };
  }, []);

  return <>{children}</>;
}
```

## 2. Animation Patterns (Framer Motion)
When building sections, use the following patterns for a high-end feel:

### A. The "Fade Up Reveal"
Use this for headings and large text blocks as they enter the viewport.
- **Hook:** `useInView` or `<motion.div whileInView={...} viewport={{ once: true, margin: "-10%" }}>`
- **Initial State:** `opacity: 0, y: 40`
- **Animate State:** `opacity: 1, y: 0`
- **Transition:** `duration: 0.8, ease: [0.16, 1, 0.3, 1]` (custom easing is crucial for a premium feel).

### B. The "Parallax Image"
Images should move slightly slower or faster than the scroll position.
- **Hook:** `useScroll` and `useTransform`.
- **Implementation:**
```tsx
const { scrollYProgress } = useScroll({ target: containerRef, offset: ["start end", "end start"] });
const y = useTransform(scrollYProgress, [0, 1], ["-20%", "20%"]);
```
- Wrap the image in a container with `overflow-hidden`, and apply the `y` transform to the inner `motion.img`.

### C. The "Staggered List"
For feature grids, team members, or pricing cards.
- **Parent:** `<motion.div variants={containerVariants} initial="hidden" whileInView="show" viewport={{ once: true }}>`
- **Variants (Parent):** `{ hidden: { opacity: 0 }, show: { opacity: 1, transition: { staggerChildren: 0.1 } } }`
- **Variants (Child Item):** `{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0, transition: { duration: 0.5, ease: "easeOut" } } }`

## 3. Workflow Checklist
1. Copy the instructions.
2. Confirm if Lenis is installed/configured. If not, set it up first.
3. Apply standard Fade Up reveals to text content.
4. Add parallax to large media assets (images/video backgrounds).
5. Add staggered reveals to lists/grids.
6. Build the project to verify no TypeScript or Framer Motion version mismatch errors.
7. Tell the user: "خلصت يا سيدي.. ضفتلك حركات السكرول والـ Lenis، جرب اعمل سكرول بالصفحة وشوف كيف النعومة والشغل النظيف."
