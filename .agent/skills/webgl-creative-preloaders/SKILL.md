---
name: webgl-creative-preloaders
description: Advanced loading screens necessary for heavy 3D websites. Uses R3F useProgress to show real-time percentage, preventing users from seeing a blank screen while MBs of GLTF assets load.
---

# WebGL Creative Preloaders Skill

## When to use this skill
- When building a "Tier 3: Hybrid 3D" or "Tier 4: Immersive WebGL" site.
- When the user asks for a loading screen, a spinner, or an "Enter Experience" button.
- Because Tier 4 sites load large geometries, images, and fonts, a preloader is not optional—it is mandatory.

## Tone & Language Guidelines (Critical)
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "برمجتلك شاشة التحميل (Preloader)، بتعطي النسبة المئوية حسب التحميل الحقيقي للملفات، مش رقم وهمي."
- Be professional yet casual: "الشاشة السودا راحت، ركبنا مكانها لودينج فخم فيه النسبة بتعد لحد ما يجهز الموقع."

## 1. The Real-Time Progress Loader

Do not use `setTimeout` or fake loading bars. Use the `useProgress` hook from `@react-three/drei`, which physically tracks XHR requests for `.glb` and image textures loading onto the GPU.

### Implementation Pattern (Z-Index Overlay)
Create a full-screen overlay that lives *outside* the `<Canvas>`, reading the loading state.

```tsx
"use client";
import { useProgress } from '@react-three/drei';
import { motion, AnimatePresence } from 'framer-motion';

export default function Preloader() {
  // `progress` goes from 0 to 100 based on actual downloaded bytes & parsed materials
  // `active` becomes false when 100% is reached
  const { active, progress, errors, item, loaded, total } = useProgress();

  return (
    <AnimatePresence>
      {active && (
        <motion.div
          key="preloader"
          initial={{ opacity: 1 }}
          exit={{ opacity: 0, transition: { duration: 1, ease: 'easeIn' } }}
          className="fixed inset-0 z-[100] flex flex-col items-center justify-center bg-neutral-950 text-white"
        >
          {/* Logo or Brand Element */}
          <div className="mb-8 text-4xl font-light tracking-[0.5em] text-zinc-400">
            ESSENZA
          </div>

          {/* Progress Bar Container */}
          <div className="relative w-64 h-[1px] bg-zinc-800 overflow-hidden">
            <motion.div
              className="absolute left-0 top-0 h-full bg-zinc-100"
              initial={{ width: 0 }}
              animate={{ width: `${progress}%` }}
              transition={{ ease: "linear" }}
            />
          </div>

          {/* Number Display */}
          <div className="mt-4 text-sm font-mono tracking-widest text-zinc-500">
            {Math.floor(progress)}%
          </div>
          
          {/* Optional: Show what is loading for debugging */}
          {/* <div className="mt-2 text-xs text-zinc-700">{item}</div> */}
        </motion.div>
      )}
    </AnimatePresence>
  );
}
```

## 2. Integration with "Enter Experience"
On Tier 4 sites, browsers block audio (background music) from playing automatically. Therefore, when `progress` hits 100%, do not hide the loader immediately. Instead, change it to an "Enter" button.

### The "Enter" Pattern
Modify the state logic:

```tsx
// Inside Preloader component...
import { useState, useEffect } from 'react';

const [showEnter, setShowEnter] = useState(false);
const [started, setStarted] = useState(false); // Controls the final exit

useEffect(() => {
  if (progress === 100) {
    setShowEnter(true);
  }
}, [progress]);

// On click handler for the Enter button:
const handleEnter = () => {
  setStarted(true);
  // Trigger global audio play here, or set global context state
};

// Replace `active &&` with `!started &&` in the AnimatePresence check.
```

## 3. Workflow Checklist
If tasked to build a Tier 3/4 Site or add a loader:
1. Ensure `framer-motion` and `@react-three/drei` are installed.
2. Build the `Preloader.tsx` component using `useProgress`.
3. Give it a high `z-index` (e.g., `z-[100]`).
4. Place the `<Preloader />` in the root layout or root page, *outside* the `<Canvas>`.
5. Ensure the styling matches the brand's aesthetic (usually a sleek dark background with a very thin white or gold loading line).
6. Tell the user in dialect: "ركبتلك شاشة الدخول يا سيدي.. بتعطي النسبة بالضبط ولما تخلص بتعطيك زر عشان تفوت الموقع ويبدأ الصوت يشتغل!"
