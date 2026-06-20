---
name: ui-ux-inspiration-scout
description: Automates finding and capturing UI/UX inspiration from the web.
---

# UI/UX Inspiration Scout

## Purpose
This skill is designed to help find high-quality UI/UX inspiration, color palettes, and component designs for specific themes (e.g., Islamic App, Gaming Dashboard, E-commerce).

## Workflow

1.  **Identified Need:** When the user asks for "inspired designs", "better UI", or "examples".
2.  **Search Strategy:**
    - Use `search_web` to find Dribbble, Behance, or Pinterest collections related to the topic.
    - Look for keywords like "UI Trend [Year]", "[Theme] App Design", "Mobile UI Kit".
3.  **Extraction:**
    - Summarize key design elements found (e.g., "Glassmorphism is trending", "Gold accents on dark blue are popular for this theme").
    - Identify specific components (Bottom Navigation, Card Styles, Typography).
4.  **Application:**
    - Propose concrete CSS/Tailwind changes based on findings.
    - Suggest color codes and font pairings.

## Example Usage

**User:** "Find me a cool design for a Ramadan App."

**Agent:**
1.  Searches for "Ramadan App UI Design Dribbble".
2.  Finds a trend of "Midnight Blue backgrounds with gold geometric patterns".
3.  Suggests: "Let's use a deep #0F172A background with a #F59E0B border and the 'Amiri' font for headings."

## Resources
- **Fonts:** Google Fonts (Amiri, Cairo, Tajawal).
- **Icons:** Lucide React, Heroicons.
- **Colors:** Tailwind Colors.
