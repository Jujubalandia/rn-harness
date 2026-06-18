---
description: Regras para uso de expo-video (substituto de expo-av) no SDK 56+. Aplicar ao usar VideoView, useVideoPlayer, ou controles de playback.
globs: ["**/*.ts", "**/*.tsx"]
alwaysApply: false
---
# expo-video (SDK 56+)

## Pacote correto

```bash
# expo-av está DEPRECATED desde SDK 50
pnpm remove expo-av
npx expo install expo-video
```

## API básica

```tsx
import { VideoView, useVideoPlayer } from 'expo-video';

export function VideoPlayer({ uri }: { uri: string }) {
  const player = useVideoPlayer(uri, p => {
    p.loop = false;
    p.muted = false;
  });

  return (
    <VideoView
      player={player}
      style={{ width: '100%', height: 220 }}
      allowsFullscreen
      allowsPictureInPicture
    />
  );
}
```

## Regras

- ❌ `import { Video, Audio } from 'expo-av'` — usar expo-video + expo-audio
- ❌ `useVideoPlayer` sem cleanup — chamar `player.release()` em `useEffect` cleanup
- ✅ `allowsFullscreen` + `allowsPictureInPicture` para UX nativa
- ✅ `nativeControls` em vez de controles customizados para acessibilidade
- ✅ Gerenciar `player.playing` state via `useEvent(player, 'playingChange')`

## Poster (thumbnail antes de carregar)

```tsx
<VideoView
  player={player}
  contentFit="cover"
  style={styles.video}
/>
```

## Cleanup obrigatório

```tsx
useEffect(() => {
  return () => { player.release(); };
}, [player]);
```

## Audio separado (expo-audio)

```tsx
import { useAudioPlayer } from 'expo-audio';

const audioPlayer = useAudioPlayer(require('./assets/sound.mp3'));
audioPlayer.play();
```

## Permissões (app.json)

```json
{
  "expo": {
    "plugins": [
      ["expo-video", { "supportsBackgroundPlayback": true }]
    ]
  }
}
```
