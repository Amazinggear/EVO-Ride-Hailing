---
name: auditing-site-performance
description: Evaluates website speed, SEO, accessibility, and best practices. Provides actionable recommendations. Use when the user asks to check site speed, run a lighthouse test, or optimize SEO.
---

# Auditing Site Performance Skill

## When to use this skill
- When the user asks "كيف سرعة الموقع؟" (How is the site speed?).
- When the user requests an SEO check or asks if the website is ready for production.
- When you need to act as a Quality Assurance (QA) tool simulating a Lighthouse audit.

## Tone & Language Guidelines
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Be analytical but practical: "يا خوي فحصتلك الموقع، السرعة ممتازة طيارة! بس عندنا شوية مشاكل بالـ SEO لازم نعدلها."

## 1. The Audit Workflow
Since you (the AI) cannot run an actual browser-based Lighthouse tool directly, you must perform a static code analysis and simulate the checks.

### A. Performance Checks
Use `grep_search` or `view_file` to check for these common bottlenecks:
1. **Unoptimized Images:** Are they using `<img src="..."/>` instead of Next.js `<Image />` component? Are images massive in size?
2. **Heavy Imports:** Are they importing entire libraries instead of specific modules (e.g., `import { x } from 'lodash'` instead of `import x from 'lodash/x'`)?
3. **Render Blocking:** Are massive CSS/JS files loaded prematurely? (Next.js handles most of this, but check custom `_document.tsx`).
4. **WebGL/3D (If applicable):** Is the `dpr` properly capped? Are uncompressed `.glb` files used?

### B. SEO Checks
1. **Metadata:** Does `app/layout.tsx` or `app/page.tsx` have exported `metadata` with `title` and `description`?
2. **Semantic HTML:** Are they using `<h1>`, `<h2>`, `<main>`, `<nav>`, `<article>` instead of endless `<div>`s?
3. **Alt Tags:** Do all `<Image>` and `<img>` tags have descriptive `alt` attributes?

### C. Accessibility (a11y)
1. **Contrast:** Are background and text colors readable (especially in dark mode)?
2. **Buttons/Links:** Do buttons have `aria-label` if they only contain icons?

## 2. Reporting
Provide the user with a structured report that looks like a real audit.

**Example Format:**
```markdown
يا هلا يا غالي، عملتلك جرد كامل للموقع وهيك النتيجة:

🟢 **السرعة (Performance):** 
الموقع طيارة، بس لاحظت إنك حاطط صورة الـ Hero بصيغة PNG وحجمها كبير، الاحسن نغيرها لـ webp أو نستعمل `next/image`.

🟢 **الـ SEO (محركات البحث):** 
ناقصك الـ `metadata` في الصفحة الرئيسية. ضيفتلك الكود تحت انسخه.

🟡 **الوصولية (Accessibility):**
أزرار السوشيال ميديا لأنها بس آيكونات (Icons)، لازم تعطيها `aria-label` عشان الـ Screen Readers.
```

## 3. Actionable Fixes
Don't just point out errors. Propose the exact CLI command or code snippet to fix them immediately.
