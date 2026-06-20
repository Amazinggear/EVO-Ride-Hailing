---
name: react-three-fiber-basics
description: Sets up basic React Three Fiber scenes, lighting, and integrates 3D models (GLTF/GLB) into standard web pages. Use for tier 3 hybrid sites (e.g., product viewers, car showcases).
---

# React Three Fiber (R3F) Basics Skill

## When to use this skill
- When building a "Tier 3: Hybrid 3D" site as instructed by `tier-based-architecture`.
- When the user asks to add a 3D model (like a laptop, car, or phone) to a webpage.
- When creating a hero section that features an interactive 3D object spinning or following the mouse.

## Tone & Language Guidelines (Critical)
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "يا هلا فيك! ركبت المجسم الـ 3D بالصفرين (Scene) وظبطت الإضاءات عشان يطلع طبيعي ومرتب، وجاهز لتلعب فيه بالماوس."
- Mix technical terms natively: "رح نستعمل `Canvas` والـ `useGLTF` عشان نقرأ المجسم".

## 1. Environment Setup
*Ensure these dependencies are installed: `three`, `@react-three/fiber`, `@react-three/drei`.*

```bash
npm install three @react-three/fiber @react-three/drei
```

## 2. Core Patterns

### A. The Setup / Canvas Wrapping
A 3D object must live inside a `<Canvas>`. This canvas is usually absolute/sticky positioned behind HTML text.

```tsx
"use client";
import { Canvas } from '@react-three/fiber';
import { Environment, OrbitControls, ContactShadows } from '@react-three/drei';
import { Suspense } from 'react';

export default function HeroScene() {
  return (
    <div className="w-full h-screen absolute inset-0 -z-10">
      <Canvas shadows camera={{ position: [0, 0, 5], fov: 45 }}>
        {/* Environment Map for realistic lighting reflections */}
        <Environment preset="city" />
        
        {/* Soft lighting */}
        <ambientLight intensity={0.5} />
        <directionalLight position={[10, 10, 5]} intensity={1} castShadow />
        
        <Suspense fallback={null}>
          <MyModel />
          {/* Ground shadow for realism */}
          <ContactShadows position={[0, -1.5, 0]} opacity={0.5} scale={10} blur={2} />
        </Suspense>

        {/* Allow user to drag/spin the model */}
        <OrbitControls enableZoom={false} enablePan={false} autoRotate autoRotateSpeed={0.5} />
      </Canvas>
    </div>
  );
}
```

### B. Loading a Model (GLTF/GLB)
Use `useGLTF` from Drei to load models. *Remind the user to drop the model in the `public` folder first.*

```tsx
import { useGLTF } from '@react-three/drei';
import { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

function MyModel() {
  // 1. Ask the user for the .glb file path in /public
  const { scene } = useGLTF('/model.glb');
  const modelRef = useRef<THREE.Group>(null);

  // 2. (Optional) Make it float slightly for a dynamic feel
  useFrame((state) => {
    if (modelRef.current) {
      modelRef.current.position.y = Math.sin(state.clock.elapsedTime) * 0.1;
    }
  });

  return <primitive ref={modelRef} object={scene} scale={1} position={[0, 0, 0]} />;
}
```

## 3. Workflow Checklist
If you are tasked to add a 3D model:
1.  **Ask for the Asset:** Ensure the user has provided a `.glb` or `.gltf` file and placed it in the `/public` directory.
2.  **Scaffold the Canvas:** Create the parent `Canvas` component with appropriate camera positioning.
3.  **Lighting & Environment:** Add `ambientLight`, `directionalLight`, and most importantly, an `<Environment>` from Drei for realistic metal/glass reflections.
4.  **Load the Model:** Create the inner component using `useGLTF`.
5.  **Interactivity:** Add `<OrbitControls>` or tie the model's rotation to scroll progress using Framer Motion combined with R3F (e.g., `useScroll`).
6.  **Report back in dialect:** "المجسم ركبناه ع الصفحة والإضاءات كلها مضبوطة 100%!"
