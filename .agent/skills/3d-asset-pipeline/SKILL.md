---
name: 3d-asset-pipeline
description: Handles the preparation, compression (Draco/meshopt), and optimization of 3D assets (GLTF/GLB) before they are loaded into the browser.
---

# 3D Asset Pipeline Skill

## When to use this skill
- When the user provides a large `.glb` or `.gltf` file (over 5MB) and asks to use it on the web.
- When a Tier 3 or Tier 4 project has performance issues due to heavy geometries or large uncompressed textures.
- When generating a React component automatically from a 3D model using `gltfjsx`.

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "استلمت المجسم يا معلم، حجمه كان كبير شوي فعملتله ضغط بـ Draco عشان يصير خفيف ع المتصفح."

## 1. The Asset Compression Workflow

Never serve raw, uncompressed 3D models from Blender directly to the web if they are large.
Use the `gltf-pipeline` or `gltfjsx` tools via NPX.

### A. Draco Compression
Draco compression drastically reduces the size of geometry (vertices, normals, indices).

1. Ask the user for the path to the original `.glb` file.
2. If `gltf-pipeline` is not installed globally, run it via npx:
```bash
npx gltf-pipeline -i input_model.glb -o output_model.glb -d
```
3. Tell the user: "ضغطت الـ Geometry تبعت المجسم بالـ Draco وصار حجمه ممتاز."

### B. Texture Compression (WebP)
Often, 3D models have embedded 4K PNG textures that eat up VRAM. If the model size is bloated by textures rather than geometry:
1. Extract the `.glb` to a `.gltf` (which separates the `.bin` and textures into a folder).
2. Manually or programmatically convert the huge textures to `.webp` or `.jpg`.
3. Re-link them in the `.gltf` file and repack to `.glb`.

## 2. Generating React Components (gltfjsx)

Instead of manually writing a `<mesh>` component for every piece of a 3D object, use `gltfjsx` to read the `.glb` and generate a declarative React Three Fiber component automatically.

```bash
# Run this command in the terminal where the model is located (e.g., inside public/)
npx @react-three/gltfjsx@latest your_model.glb --transform --types
```
*Note: The `--transform` flag automatically applies Draco compression and deduplicates identical materials/geometries.*
*The `--types` flag generates TypeScript definitions.*

### Usage Post-Generation
The tool will output a `Model.tsx`. You take that file, move it to the `src/components/` folder, and fix the import path inside it:

```tsx
// Inside generated Model.tsx
import { useGLTF } from '@react-three/drei'

export function Model(props: any) {
  // Ensure the path points to the public folder correctly
  const { nodes, materials } = useGLTF('/your_model-transformed.glb') 
  return (
    <group {...props} dispose={null}>
      {/* The auto-generated meshes will be here */}
      <mesh geometry={nodes.Cube.geometry} material={materials.Material} />
    </group>
  )
}

// Preload the compressed asset
useGLTF.preload('/your_model-transformed.glb')
```

## 3. Workflow Checklist
1. Identify the heavy `.glb` file and check its size.
2. Run `npx @react-three/gltfjsx@latest file.glb --transform` to compress and generate a React file simultaneously.
3. Move the generated `.tsx` to the components directory.
4. Ensure the `-transformed.glb` is in the `public/` directory.
5. Notify the user: "عملت للـ Model ضغط ممتاز باستخدام gltfjsx، وسحبتلك إياه على شكل Component جاهز لتركبه بالشاشة مباشرة."
