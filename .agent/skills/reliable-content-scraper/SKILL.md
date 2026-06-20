---
name: reliable-content-scraper
description: Scrapes reliable content from specific authoritative websites (e.g., Sunnah.com, Quran.com) and transforms it into structured quiz questions using LLM reasoning.
---

# Reliable Content Scraper

## Purpose
To populate the database with high-quality, verified Islamic content (Hadith, Quran, History) without manual entry.

## Workflow

### 1. Identify Target
- **User Request:** "Get me 50 questions about the Battle of Badr."
- **Agent Action:** Selects the appropriate source (e.g., IslamWeb History Section).

### 2. Fetch & Parse
- Use `read_url_content` to fetch the raw text from the reliable source.
- Extract the main content (Body text, Hadith narrative).

### 3. Transform (The "Brain")
- **Prompt the Model:** "Take this text and generate 3 multiple-choice questions. Format as JSON."
- **Rules:**
  - One correct answer, three plausibly wrong distractors.
  - Difficulty level (1-5).
  - Category tag (History, Fiqh, etc.).

### 4. Verify & Save
- **Structure Check:** Ensure JSON matches the database schema.
- **Save:** Write to `data/generated_questions/batch_X.json`.

## Supported Sources (Examples)
- **Sunnah.com:** For Hadith.
- **Quran.com:** For Tafsir and Meanings.
- **Al-Mawdoo3 / IslamWeb:** For Historical Events.

## Instructions
- **Accuracy First:** If the source text is ambiguous, do NOT generate a question.
- **Citation:** Always include the `source_url` in the metadata.
- **Batching:** Generate questions in batches of 10-20 to avoid context limits.

## Example Output (JSON)
```json
[
  {
    "text": "في أي سنة وقعت غزوة بدر الكبرى؟",
    "options": ["السنة الثانية للهجرة", "السنة الثالثة للهجرة", "السنة الخامسة للهجرة", "عام الفيل"],
    "correctAnswer": 0,
    "category": "history",
    "difficulty": 2,
    "source": "https://islamweb.net/..."
  }
]
```
