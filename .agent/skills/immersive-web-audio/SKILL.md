---
name: immersive-web-audio
description: Adding ambient sounds and UI sound effects using Web Audio API or Howler.js. Use for Tier 3 and Tier 4 sites where sound design is required for a premium feel.
---

# Immersive Web Audio Skill

## When to use this skill
- When building a "Tier 3: Hybrid 3D" or "Tier 4: Immersive WebGL" site.
- When the user asks for "sound", "music", "audio", "hover sounds", or "background ambiance".
- Immersive sites feel empty without audio feedback.

## Tone & Language Guidelines (Critical)
- **Always** communicate with the user in the local Jordanian/Palestinian dialect (اللهجة الأردنية والفلسطينية).
- Example: "حطيتلك مزيكا خفيفة بالخلفية، ولما تمرر الماوس ع الزر بيطلع صوت زجاجي فخم."
- Technical terms integrated: "رح نستعمل `use-sound` أو `Howler` عشان الصوت ما يعمل Delay بالمتصفح."

## 1. Setup & Foundations
For React/Next.js projects, use `use-sound` (which wraps Howler.js) for simple UI sounds, and HTML5 Audio or standard Howler for background music.

```bash
npm install use-sound
```

*Note: Browsers block audio until the user interacts with the page (clicks/taps). You must design an "Enter Experience" button to bypass autoplay policies.*

## 2. Implementing Background Ambiance
Background music should be looping, subtle, and start only after user interaction.

```tsx
import { useState, useRef, useEffect } from 'react';
import { Volume2, VolumeX } from 'lucide-react';

export default function AudioController() {
  const [isPlaying, setIsPlaying] = useState(false);
  // Assume the user provided an ambient.mp3 in the public folder
  const audioRef = useRef<HTMLAudioElement | null>(null);

  useEffect(() => {
    audioRef.current = new Audio('/ambient.mp3');
    audioRef.current.loop = true;
    audioRef.current.volume = 0.3; // Keep it quiet
    
    return () => {
      audioRef.current?.pause();
    }
  }, []);

  const toggleMute = () => {
    if (!audioRef.current) return;
    
    if (isPlaying) {
      audioRef.current.pause();
    } else {
      audioRef.current.play();
    }
    setIsPlaying(!isPlaying);
  };

  return (
    <button 
      onClick={toggleMute}
      className="fixed bottom-8 right-8 z-50 p-3 bg-white/10 backdrop-blur-md rounded-full border border-white/20 text-white hover:bg-white/20 transition-all"
    >
      {isPlaying ? <Volume2 size={24} /> : <VolumeX size={24} />}
    </button>
  );
}
```

## 3. Implementing UI Hover Sounds
Every premium button should have a very short, subtle "click" or "hover" sound.

```tsx
import useSound from 'use-sound';

export function PremiumButton({ children, onClick }: { children: React.ReactNode, onClick: () => void }) {
  // Require soft-hover.mp3 and solid-click.mp3 in /public
  const [playHover] = useSound('/soft-hover.mp3', { volume: 0.1 });
  const [playClick] = useSound('/solid-click.mp3', { volume: 0.2 });

  return (
    <button
      onMouseEnter={() => playHover()}
      onClick={() => {
        playClick();
        onClick();
      }}
      className="btn-premium"
    >
      {children}
    </button>
  );
}
```

## 4. Workflow Checklist
1. Ensure the user provides the audio files (e.g., `.mp3`, `.wav`) in the `/public` folder. If they haven't, ask them or use placeholders if generating a demo.
2. Install `use-sound`.
3. Create a global Audio Controller component for background music.
4. Add the Controller to `layout.tsx` or the main page.
5. Create a reusable button component that incorporates hover/click sounds.
6. Verify audio plays only *after* a user interaction (to respect browser policies).
7. Tell the user in dialect: "الصوت صار شغال يا خوي! ركبتلك زر كتم الصوت تحت، وحطيت مؤثرات ع الأزرار وقت الـ Hover بتجنن."
