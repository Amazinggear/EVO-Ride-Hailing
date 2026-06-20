---
name: webgl-environment-architect
description: Orchestrates full-screen immersive 3D environments using Three.js / React Three Fiber. Controls camera paths, advanced PBR materials, routing over 3D space, and scene composition for Tier 4 websites.
---

# WebGL Environment Architect Skill

## When to use this skill
- When building a "Tier 4: Immersive WebGL" site as requested by `tier-based-architecture`.
- When the user wants the entire website to be a 3D scene that they can navigate through (e.g., Peachworlds sites).
- When you need to setup an interactive HTML-over-Canvas layout (where `Canvas` is the root element and HTML is projected using `@react-three/drei`'s `Html`).

## Tone & Language Guidelines (Critical)
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "يا معلم جهزنا البيئة الـ 3D بالكامل، الكاميرا صارت تمشي مع السكرول زي الحلاوة."
- Technical terms are mixed naturally: "ركبنا الـ `Camera Controls` وعدلنا الإضاءة لتضرب على الـ `Materials` صح".

## 1. Core Architecture (The Tier 4 Approach)
Unlike a standard site where the `div` is the wrapper, in an immersive site, the `<Canvas>` is the wrapper, and HTML elements float inside the 3D space or exist completely independently on top using absolute positioning.

### A. The Setup Pattern (Full Screen Canvas)
1. Delete all default Next.js templates.
2. In `app/layout.tsx` or `app/page.tsx`, put the `<Canvas>` at the absolute root covering `100vw` and `100vh`.
3. Use `ScrollControls` from `@react-three/drei` for managing the user's progress through the scene.

```tsx
import { Canvas } from '@react-three/fiber';
import { ScrollControls, Scroll, Environment } from '@react-three/drei';

export default function ImmersiveWorld() {
  return (
    <Canvas
      shadows
      camera={{ position: [0, 2, 10], fov: 50 }}
      gl={{ antialias: false }} // Turn off default AA in heavy scenes, handle in postprocessing later
      className="fixed inset-0 z-0 bg-black"
    >
      <Environment preset="night" background />
      
      {/* Scroll controls define how "long" the page is virtually. 3 pages = 300vh */}
      <ScrollControls pages={3} damping={0.25}>
        
        {/* 1. The 3D World (Scrolls with the scene or animates based on scroll) */}
        <Scene />
        
        {/* 2. The HTML Overlay (Scrolls like normal DOM over the Canvas) */}
        <Scroll html style={{ width: '100vw' }}>
          <div className="w-screen h-screen flex items-center justify-center">
            <h1 className="text-white text-9xl uppercase font-bold mix-blend-difference">Welcome</h1>
          </div>
          <div className="w-screen h-screen flex items-center justify-start p-20">
            <h2 className="text-white text-6xl w-1/2">Discover the World</h2>
          </div>
        </Scroll>

      </ScrollControls>
    </Canvas>
  );
}
```

## 2. Advanced Camera Controls
A key part of Tier 4 is moving the camera through the environment as the user scrolls, rather than moving the object.

To do this, tie the camera's position to `useScroll`:

```tsx
import { useScroll } from '@react-three/drei';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

function Scene() {
  const scroll = useScroll();

  useFrame((state) => {
    // scroll.offset goes from 0 at the top to 1 at the bottom
    const progress = scroll.offset; 
    
    // Move the camera forward (Z-axis) as we scroll down
    state.camera.position.set(
      Math.sin(progress * Math.PI) * 5, // Sway left/right
      2, // Keep height constant
      10 - progress * 20 // Move forward from z:10 to z:-10
    );
    
    // Look at a target 
    state.camera.lookAt(0, 0, -20);
  });

  return (
    <group>
      {/* Heavy 3D assets go here (Cities, Cars, Terrain) */}
    </group>
  );
}
```

## 3. Workflow Checklist
If assigned a Tier 4 Immersive Project:
1. Ensure `three`, `@react-three/fiber` and `@react-three/drei` are installed.
2. Replace standard HTML layouts with a full-screen `Canvas`.
3. Wrap the scene in `<ScrollControls>`.
4. Position text using `<Scroll html>`.
5. Animate the camera or objects by reading `const scroll = useScroll()` inside a `useFrame` hook.
6. Tell the user in dialect: "الـ Environment جاهزة ومسار الكاميرا (Camera Path) مبرمج مع الـ Scroll."
