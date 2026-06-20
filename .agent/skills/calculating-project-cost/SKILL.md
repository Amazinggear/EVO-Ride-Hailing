---
name: calculating-project-cost
description: Estimates software development costs for websites and apps in Jordanian Dinars (JOD) or USD based on project scope and features.
---

# Calculating Project Cost Skill

## When to use this skill
- When the user asks "كم بكلف هالمشروع؟" or "What's the price for an app like this?".
- When you are quoting a new client based on feature sets.
- When generating a business proposal.

## Tone & Language Guidelines
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Be a smart technical salesperson: "سيدي حسبتلك الحسبة، هاد الموقع بيكلف حوالي كذا دينار أردني عشان فيه تعقيد بالباك إند."

## 1. The Estimation Workflow

### Step 1: Breakdown the Scope
Never give a flat number instantly without breaking down the work. Split the project into logical phases:
- UI/UX Design (Figma, Prototyping)
- Frontend Development (React/Next.js)
- Backend & Database (Node.js, Postgres, Supabase)
- Integrations (Payment Gateways, 3rd Party APIs)
- QA & Deployment (Testing, Vercel/AWS setup)

### Step 2: The Pricing Matrix
Use this generic pricing matrix to calculate costs (adjust based on user context if they provide specific rates):

*Note: All prices below are estimated in **JOD (Jordanian Dinars)**. 1 JOD ≈ 1.41 USD.*

**Tier 1: Economic / Simple Landing Page**
- **Effort:** 3-5 days
- **Features:** 1-3 generic pages, contact form, no CMS.
- **Estimated Cost:** 300 - 600 JOD

**Tier 2: Premium Business/Corporate Site**
- **Effort:** 2-3 weeks
- **Features:** Custom UI/Glassmorphism, 5-10 pages, basic CMS (Sanity/Strapi), SEO setup.
- **Estimated Cost:** 800 - 1500 JOD

**Tier 3: E-Commerce / SaaS MVP**
- **Effort:** 1-2 months
- **Features:** Auth, Payments, Cart/Dashboard, Database, User Roles.
- **Estimated Cost:** 2500 - 5000 JOD

**Tier 4: Immersive 3D/WebGL Experience (Peachworlds style)**
- **Effort:** 1-3 months
- **Features:** Custom Shaders, optimized 3D assets, camera animations, audio design.
- **Estimated Cost:** 4000 - 8000+ JOD

### Step 3: Present the Quote
Provide a clear, itemized markdown table so the client understands what they are paying for.

```markdown
يا معلم، حسبتلك اياها بالتفصيل وهيك الترتيب لـ **(اسم المشروع)**:

| المرحلة | التفاصيل | التكلفة التقديرية (دينار أردني) |
| --- | --- | --- |
| **تصميم الواجهات (UI/UX)** | تصميم حصري فخم | 400 JOD |
| **برمجة الواجهات (Frontend)** | برمجة الصفحات والتفاعلات | 800 JOD |
| **قواعد البيانات (Backend)** | شغل السيرفرات والبوابات | 600 JOD |
| **الإجمالي (Total)** | | **1800 JOD** |

هاي الأسعار تقديرية وبتعتمد كمان على سرعة التسليم وكمية التعديلات. شو رأيك بهاي الحسبة؟
```

## 2. Dynamic Variables
- **Currency:** Ensure you ask or default to JOD if the user is in Jordan. Ask if they prefer USD.
- **Maintenance:** Always mention that monthly maintenance (servers, bug fixes) is historically priced at 10-15% of the total project cost per year.
