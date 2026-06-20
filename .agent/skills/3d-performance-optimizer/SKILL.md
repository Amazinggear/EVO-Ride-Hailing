---
name: 3d-performance-optimizer
description: Implements critical performance optimizations for Tier 4 WebGL sites, ensuring 60 FPS across devices via component memoization, geometry instancing, Draco compression handling, and pixel ratio control.
---

# 3D Performance Optimizer Skill

## When to use this skill
- Whenever building or reviewing a "Tier 3: Hybrid 3D" or "Tier 4: Immersive WebGL" site.
- If the user complains that "the site is lagging," "my phone gets hot," or "the fan is loud".
- When handling `.glb`/`.gltf` files larger than 5MB or scenes with thousands of objects.

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "شيكتلك الـ Performance، ضغطت المجسمات بالـ Draco ونزلت الـ Pixel Ratio عالتلفونات عشان الموقع يطير طيران وما يعلق مع الزباين."

## 1. The Core Performance Metrics
To achieve 60 FPS in React Three Fiber, you must reduce:
1. **Draw Calls:** How many individual objects the CPU tells the GPU to render.
2. **Vertices/Polygons:** How many triangles the GPU has to process.
3. **Texture Memory:** How many massive 4K PNGs are loaded into VRAM.

## 2. Key Optimization Techniques

### A. Draco Compression (Essential for 3D Assets)
If a user provides a raw `.gltf`/`.glb`, it must be compressed.
If `useGLTF` is used, specify the Draco decoder.

```tsx
import { useGLTF } from '@react-three/drei';

export function Model() {
  // Drei automatically uses a public CDN for the Draco decoder if left blank,
  // but it's best to configure it explicitly if providing local decoders.
  const { scene } = useGLTF('/model-draco.glb');
  return <primitive object={scene} />;
}
// Preload for instant visual feedback
useGLTF.preload('/model-draco.glb');
```

### B. Device Pixel Ratio (DPR) Control
Mobile phones boast insane pixel densities (3x, 4x). Rendering a full-screen WebGL canvas at 4x resolution on a weak GPU causes instant lag.
Restrict the `dpr` attribute on the `<Canvas>` to max out at `2` (Retina).

```tsx
import { Canvas } from '@react-three/fiber';

export default function App() {
  return (
    <Canvas 
      // Important: Cap DPR at 2. 
      // This means on a 3x iPhone, it only renders at 2x, saving huge GPU calculation.
      dpr={[1, 2]} 
      
      // If the scene doesn't need shadows, disable them at the root
      shadows={false}
      
      // Post-processing often breaks with default antialiasing, turn off if using EffectComposer
      gl={{ antialias: false, powerPreference: "high-performance" }}
    >
      <Scene />
    </Canvas>
  );
}
```

### C. InstancedRendering (For many identical objects)
If the scene has 1,000 trees, 1,000 floating particles, or 100 cars—do **not** map over an array and render `<mesh>` 1,000 times (1,000 draw calls). Use `<Instances>`.

```tsx
import { Instances, Instance } from '@react-three/drei';

function AsteroidField() {
  const data = Array.from({ length: 1000 }, () => ({
    position: [Math.random() * 10, Math.random() * 10, Math.random() * 10],
    scale: Math.random() * 0.5
  }));

  return (
    {/* 1 Draw Call for all 1000 objects! */}
    <Instances limit={1000}>
      <boxGeometry />
      <meshStandardMaterial color="gray" />
      {data.map((props, i) => (
        <Instance key={i} position={props.position} scale={props.scale} />
      ))}
    </Instances>
  );
}
```

### D. Avoid Doing Work in `useFrame`
`useFrame` runs 60 times a second.
- **NEVER** instantiate new objects inside it: `const pos = new THREE.Vector3()` (Triggers Garbage Collection drops).
- Instantiate objects outside, and mutate them inside.

**Bad:**
```tsx
useFrame(() => {
    meshRef.current.position.add(new THREE.Vector3(0, 0.1, 0)); // Memory leak!
});
```

**Good:**
```tsx
// Define once outside the component, or inside a useMemo
const tempVector = new THREE.Vector3(0, 0.1, 0);

useFrame(() => {
    meshRef.current.position.add(tempVector); // Mutates existing object
});
```

## 3. Workflow Checklist
If tasked to optimize a scene or build a Tier 4 site:
1. Cap the `<Canvas dpr={[1, 2]}>`.
2. Ensure `gl={{ powerPreference: "high-performance" }}` is set.
3. Check if `useGLTF` is preloading assets outside the component render cycle.
4. Replace loops of identical meshes with `<Instances>`.
5. Audit `useFrame` hooks to remove inline `new THREE.Object()` declarations.
6. Tell the user in dialect: "شيكت الأداء وتأكدت إنو المستشعر ما بحمى، الموقع طاير طيران على 60 فريم (60 FPS) يا كبير."
