---
name: web-audio-sound-designer
description: Implements immersive web audio experiences using Web Audio API or Howler.js. Manages ambient loops, UI hover sounds, and audio lifecycles on Tier 3/Tier 4 projects.
---

# Web Audio Sound Designer

## When to use this skill
- When the user asks to add music, sound effects, or background audio to their website.
- When working on heavily animated or immersive WebGL websites (Tier 4).

## Tone & Language Guidelines
- **Always** respond in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "ركبتلك الساوند إفكتس (Sound Effects)، هسا لما الماوس يمر على الزر بيعطي صوت خفيف فخم، والميوزيك بالخلفية شغالة عالهادي."

## 1. Context & Lifecycle
- Browsers **block** audio playback until the user interacts with the page (click, scroll, touch).
- You MUST wait for an interaction before calling `.play()`. A common pattern is attaching an "Enter Experience" button to the Preloader.

## 2. Audio Strategy
- **Ambient Music:** Use a soft loop. Volume must be kept extremely low (e.g., `0.1` or `0.05`). Implement a global mute/unmute button in the Header.
- **UI Sounds (SFX):** Add subtle clicks or swooshes on `onMouseEnter` and `onClick`. Keep these very short and snappy.

## 3. Implementation Options
- **Howler.js:** Best for managing sprites, fading audio out, and handling browser support easily.
- **HTMLAudioElement:** Acceptable for single short sounds, but less ideal for complex mixing.

## 4. Boilerplate Advice
Instruct the user on how to load files properly:
1. Put all `.mp3` or `.wav` files into the `/public/sounds` folder.
2. Preload sounds so they don't lag on the first interaction.

"جهزنالك الصوتيات بطريقة بتعكس الفخامة. عملتلك زر (صامت/تشغيل) عشان الزبون ما ينزعج لو كان بمكان عام، وبرمجتلك Hover Sounds على كل الحركات بالموقع."
