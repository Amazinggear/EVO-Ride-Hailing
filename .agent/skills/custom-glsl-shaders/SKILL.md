---
name: custom-glsl-shaders
description: Orchestrates custom GLSL WebGL shaders for complex 3D visual effects (like water, distortion, particles) that normal Three.js materials cannot achieve.
---

# Custom GLSL Shaders Skill

## When to use this skill
- When building a "Tier 4: Immersive WebGL" site.
- When the user asks for effects like: "make it look like water", "make the image wave like a flag", "create a particle explosion", "add a glitch/distortion effect".
- Whenever standard Three.js materials (MeshStandardMaterial, MeshPhysicalMaterial) are not sufficient.

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "كتبتلك الـ Shaders يا غالي، الحركة المائية صارت شغالة والـ Performance ممتاز."
- Mix technical terms naturally: "بدنا نرفع الـ `uTime` كـ Uniform عشان الـ Vertex Shader يحرك المجسم."

## 1. What is a Shader in React Three Fiber?
Instead of using standard tags like `<meshStandardMaterial>`, you use `<shaderMaterial>` to write custom code that runs directly on the GPU.

It requires two pieces of GLSL code:
1. **Vertex Shader:** Controls the *position* of the vertices (e.g., making a flat plane wave up and down).
2. **Fragment Shader:** Controls the *color* of the pixels (e.g., mapping a texture, adding noise, or color gradients).
3. **Uniforms:** Variables passed from React (CPU) down to the GPU (e.g., time, mouse position).

## 2. Setting Up a Custom ShaderMaterial

### A. The React Component
This is how you attach your shader to a standard Three.js mesh (like a Plane) inside a `<Canvas>`.

```tsx
import { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

export default function WavingFlag() {
  const materialRef = useRef<THREE.ShaderMaterial>(null);

  // 1. Define variables to send to the GPU
  const uniforms = useMemo(
    () => ({
      uTime: { value: 0 },
      uColor: { value: new THREE.Color('#3b82f6') }, // Tailwind Blue 500
    }),
    []
  );

  // 2. Update time every frame
  useFrame((state) => {
    if (materialRef.current) {
      materialRef.current.uniforms.uTime.value = state.clock.elapsedTime;
    }
  });

  return (
    <mesh>
      {/* Geometry with enough segments to bend */}
      <planeGeometry args={[10, 10, 32, 32]} />
      
      {/* The Custom Material */}
      <shaderMaterial 
        ref={materialRef}
        uniforms={uniforms}
        vertexShader={vertexShader}
        fragmentShader={fragmentShader}
        wireframe={false}
      />
    </mesh>
  );
}
```

### B. The GLSL Code (Place above or in a separate file)

**Vertex Shader (Moving the Vertices):**
```glsl
const vertexShader = `
  uniform float uTime;
  
  // Varying variables are passed from Vertex to Fragment shader
  varying vec2 vUv;
  varying float vElevation;

  void main() {
    vUv = uv;

    // Start with the model's original position
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);

    // Add a waving effect based on the X coordinate and Time
    float elevation = sin(modelPosition.x * 2.0 - uTime * 2.0) * 0.5;
    elevation += sin(modelPosition.y * 1.5 - uTime * 1.0) * 0.5;
    
    modelPosition.z += elevation;
    vElevation = elevation; // Send the height to the fragment shader for coloring

    // Standard Three.js projection math
    vec4 viewPosition = viewMatrix * modelPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    
    gl_Position = projectedPosition;
  }
`;
```

**Fragment Shader (Coloring the Pixels):**
```glsl
const fragmentShader = `
  uniform vec3 uColor;
  
  varying vec2 vUv;
  varying float vElevation;

  void main() {
    // Darken the color in the "valleys" of the wave, lighten it on the "peaks"
    float colorMultiplier = vElevation * 2.0 + 0.8;
    vec3 finalColor = uColor * colorMultiplier;

    // Apply color
    gl_FragColor = vec4(finalColor, 1.0);
  }
`;
```

## 3. Workflow Checklist
If tasked to write a custom effect:
1. Identify if the effect alters the shape (needs Vertex Shader math) or the look/texture (needs Fragment Shader math).
2. Write the GLSL strings (or use Vite tools like `vite-plugin-glsl` if the project supports `.glsl` imports).
3. Setup the `uniforms` object in React using `useMemo()`. Include at least `uTime`.
4. Use `useFrame` to continuously update `uTime.value`.
5. Attach the `<shaderMaterial>` to a mesh that has **enough segments** in its geometry to be manipulated.
6. Verify there are no WebGL compile errors in the console.
7. Tell the user in dialect: "الـ Custom Shaders صارت راكبة، الـ التأثيرات بتجنن وبتاخد العقل!"
