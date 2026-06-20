---
name: replicating-motion
description: Extracts comprehensive animation and transition code from user-provided video files, replicating timing, easing, and properties. Use when the user requests to copy or reproduce a specific animation from a video reference.
---

# Replicating Motion & Animations

## When to use this skill
- When the user uploads a video (.mp4, .mov, .gif) of a UI interaction and asks for the code.
- When the user describes an animation verbally and provides a reference (e.g., "Make it bounce like this video").
- **Trigger:** "Make this move like this", "Copy this animation", "Extract the easing from this video", "How did they do this effect?"

## workflow
- [ ] **Video Analysis**: Analyze the uploaded video frame-by-frame to identify keyframes.
- [ ] **Property Identification**: List all changing properties (transform, opacity, scale, color, layout).
- [ ] **Timing Extraction**: Determine the exact duration (ms) and delay for each element.
- [ ] **Curve Approximation**: Identify the easing curve (e.g., `cubic-bezier(0.4, 0, 0.2, 1)`, spring physics).
- [ ] **Code Generation**: Generate a self-contained component (keep it library-agnostic unless specified, defaulting to CSS or Framer Motion).
- [ ] **Refinement**: Ask the user if the speed feel right or needs adjustment.

## Instructions

### 1. Frame-by-Frame Breakdown
Do not guess. Look at the start and end states.
- **Start State**: Where is the element before the trigger?
- **End State**: Where does it land?
- **Duration**: How long does the transition take?

### 2. The "Spring" Factor
If the animation has a bounce or overshoot, do not use standard CSS easing.
- **Use**: Spring physics parameters (stiffness, damping, mass).
- **Format**: If using Framer Motion, output `transition: { type: "spring", stiffness: 300, damping: 20 }`.

### 3. Scroll-Triggered Animations
If the video shows an element appearing as the user scrolls:
- **Use**: Intersection Observer API or Framer Motion's `whileInView`.
- **Threshold**: Estimate when it triggers (e.g., 50% visibility).

### 4. Complex Choreography (Staggering)
If multiple elements move in sequence:
- **Identify Stagger**: Calculate the delay between each element (e.g., `delay: i * 0.1`).
- **Output**: A loop or mapped array in the code to handle the stagger cleanly.

### 5. Output Format
Always provide a complete, runnable component.
```tsx
// Example Framer Motion Component
import { motion } from 'framer-motion';

export const ReplicatedComponent = () => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{
      duration: 0.6,
      ease: [0.22, 1, 0.36, 1], // Custom cubic-bezier extracted from video
    }}
  >
    {/* Content */}
  </motion.div>
);
```

## Resources
- [Framer Motion Documentation](https://www.framer.com/motion/)
- [CSS Easing Functions](https://developer.mozilla.org/en-US/docs/Web/CSS/easing-function)
