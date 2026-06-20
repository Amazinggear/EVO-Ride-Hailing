---
name: i18n-localization-master
description: Handles full website localization (Arabic/English), including Next.js App Router routing setups, RTL/LTR styling with Tailwind, and dictionary management.
---

# i18n Localization Master Skill

## When to use this skill
- When the user wants the website to support multiple languages (e.g., Arabic and English).
- When converting an existing English website to right-to-left (RTL) for Arabic.
- When configuring `[lang]` dynamic routes in Next.js App router.

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "زبطتلك الـ RTL يا حب، هسا الموقع بقلب يمين وشمال مع تفاصيل التصميم بدون ما ينكسر ولا إشي."

## 1. Next.js Routing
Use the official Next.js App Router pattern for i18n:
- Move `/app/page.tsx` into `/app/[lang]/page.tsx`.
- Create a `middleware.ts` to detect user language and redirect based on headers or cookies.

## 2. Tailwind CSS RTL Setup
- Use logically responsive classes instead of physical ones: 
  - Change `ml-4` (margin-left) to `ms-4` (margin-inline-start).
  - Change `pr-2` (padding-right) to `pe-2` (padding-inline-end).
- Apply `dir="rtl"` dynamically on the `<html>` tag in `layout.tsx` when `lang === 'ar'`.

## 3. Dictionaries
Create strongly typed dictionaries in a `dictionaries/` folder:
- `ar.json` and `en.json`.
- Provide a helper function `getDictionary(lang)` to read these files.

## 4. Execution Rules
Tell the user: "جبتلك الخلاصة يا غالي، نقلت الملفات جوا لفولدر `[lang]` وضبطت كلاسات الـ Tailwind عشان تدعم الـ RTL و LTR. ضل بس تضيف ترجماتك بملف الـ JSON وبكون جاهز للتشغيل."
