---
name: advanced-auth-security
description: Orchestrates robust authentication using NextAuth.js or Clerk, configures protected routes, sets up OAuth providers, and handles RBAC (Role Based Access Control).
---

# Advanced Auth Security Skill

## When to use this skill
- When the user asks to add "Login / Sign up", "Google Login", or "Admin Dashboard".
- When protecting specific pages or API routes from unauthenticated users.
- When integrating JWTs, Session Tokens, or Middleware-based access protection.

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "سكرتلك الراوتس (Routes) يا باشا، هسا ما حدا بيقدر يفوت على صفحة الأدمن إلا إذا كان مسجل دخول ومعه صلاحيات."

## 1. Implementation Strategy
- **Library Choice:** Default to **NextAuth.js (v5 / Auth.js)** if they use a custom database, or **Clerk** if they want a fast, managed solution. Ask the user for their preference.
- **Middleware:** Use Next.js `middleware.ts` to intercept requests before they hit the page components. This prevents loading unnecessary client code for guarded routes.
- **OAuth:** Suggest implementing Google & GitHub sign-in as defaults since they provide better user experience than raw email/password.

## 2. Security Best Practices
1. Never expose sensitive secrets (e.g., `NEXTAUTH_SECRET`, `DATABASE_URL`) in client-side code (`NEXT_PUBLIC_...`).
2. Always validate database session IDs against the incoming cookies.
3. For Admin dashboards, check user `role === 'admin'` at the Server Component level.

## 3. Expected Output
Provide clear `.env` requirements and boilerplate code, followed by:
"يا غالي، جهزتلك الـ Auth كامل. حطيتلك حماية على الـ Middleware عشان ولا نملة تفوت ع الداشبورد بدون حساب. بس ضايل تحط الـ Secrets بملف الـ `.env` وخلصنا."
