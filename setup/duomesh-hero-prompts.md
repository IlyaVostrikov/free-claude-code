# DUO MESH · Art Key — Hero Animation Pipeline
## Imagen 4 Ultra + Higgsfield / Seedance · v3.0 — One Hall, One Story

---

## Исходные кадры (все 2K · 2816×1536 · 16:9)

| # | Файл | Сцена | Размер |
|---|------|-------|--------|
| 1 | `final-1-hall-wide.png` | Общий план зала от входа | 7.30 MB |
| 2 | `final-5-macro-nature.png` | Макро: камни, роса, цветы, трава | 7.09 MB |
| 3 | `final-2-flythrough.png` | Пролёт камеры к центру зала | 6.51 MB |
| 4 | `final-3-painting.png` | Рождение абстрактной картины | 7.55 MB |
| 5 | `final-4-code.png` | Трансформация в код DUO-2026-6FB45304 | 7.23 MB |

**Канонический зал (зафиксирован):**
- Прямоугольный, 30×15м, открытая крыша → голубое небо с облаками
- 4 белые колонны, стальные балки, стеклянные стены от пола до потолка
- 3 берёзы растут прямо из пола, покрытого густой травой и полевыми цветами
- Тёмные вулканические камни среди травы
- Мощный солнечный свет сверху → god rays через всё пространство

---

## Последовательность анимации

### Кадр 1 — Wide Hall (6 секунд)

**Назначение:** Hero-заставка, зритель входит в пространство.

**Higgsfield Image → Video:**
```
Slow majestic dolly-in from the entrance toward the center of a
minimalist white art gallery. Camera glides forward smoothly at
walking pace. Trees stand still, grass is subtly swaying in a
gentle breeze. Sunbeams shift very slightly as if clouds are
passing overhead. Dust particles visible in god rays. Museum-quiet
atmosphere, no sudden movements, cinematic 24fps. The eye is drawn
toward the brightest light at the far end of the hall.
Duration: 6 seconds.
```

**Параметры камеры:**
- Motion: Dolly In (медленный наезд)
- Speed: 15-20% (очень медленно)
- Easing: Ease In/Out
- Motion blur: Minimal

**Звуковой дизайн (референс):**
- Тихая реверберация пустого зала
- Едва слышный ветер через открытую крышу
- Лёгкий шелест травы

---

### Кадр 2 — Macro Nature (4 секунды)

**Назначение:** Иммерсивное погружение в детали. Природа как источник подлинности.

**Higgsfield Image → Video:**
```
Extreme close-up macro shot at floor level. Dewdrops on dark
volcanic stones catch sunlight and sparkle. The focus breathes
very subtly — shifting from the nearest dew-covered stone to a
delicate wildflower 2 inches behind it, then back. Grass blades
sway almost imperceptibly. Tiny particles of moisture floating
in the sunlight just above the ground. Shallow depth of field,
cinematic bokeh on the blurred gallery architecture in the
background. Meditative, organic pace.
Duration: 4 seconds.
```

**Параметры камеры:**
- Motion: Focus Pull / Rack Focus (переброс фокуса)
- Speed: 10% (очень медленный breathing)
- Depth of field: Shallow (f/2.0)
- Motion blur: None

---

### Кадр 3 — Flythrough (5 секунд)

**Назначение:** Динамика. Зритель движется к центру зала — к месту рождения искусства.

**Higgsfield Image → Video:**
```
First-person perspective camera moving through the centre aisle
of a white minimalist gallery at walking speed. Grass passes by
on both sides with motion blur. Birch trees slide past in
peripheral vision. The far end of the hall remains the focal
point, bathed in brightest sunlight. The camera continues its
forward motion, never stopping — a continuous dolly-in. The
motion lines emphasize depth and speed. Cinematic, immersive.
Duration: 5 seconds.
```

**Параметры камеры:**
- Motion: Dolly In (средний наезд)
- Speed: 30-40%
- Easing: Linear (без slowing down — создаёт ощущение продолжения)
- Motion blur: Strong on edges

---

### Кадр 4 — Painting Emerges (5 секунд)

**Назначение:** Кульминация. Искусство рождается из природы.

**Higgsfield Image → Video:**
```
A luminous abstract painting is materializing in the center of a
white gallery. The canvas fades in from transparency over 4 seconds,
starting as a faint glow above the grass and becoming solid. Golden
light particles float upward around the painting. The grass beneath
glows warmly as the painting brightens. Trees and columns remain
still, framing the scene. Iridescent lavender and mauve accents
shimmer on the canvas surface. Magical realism, the moment of
artistic creation. Cinematic, photorealistic.
Duration: 5 seconds.
```

**Параметры камеры:**
- Motion: Subtle Push In (очень лёгкий наезд на картину)
- Speed: 10%
- Particle animation: Floating golden dust
- Glow: Pulsing softly (opacity 0 → 100% за 4 секунды)

---

### Кадр 5 — Code Transformation (5 секунд)

**Назначение:** Финал. Искусство становится цифровым provenance-кодом.

**Higgsfield Image → Video:**
```
Surreal transformation: the bottom third of an abstract painting
remains physical canvas with dark brushstrokes, while the upper
two-thirds dissolve into streams of tiny glowing hexadecimal digits
flowing upward. The code forms a prominent provenance hash:
DUO-2026-6FB45304, rendered in iridescent lavender light. The
boundary between physical art and digital code slowly rises over
5 seconds. Code particles spiral upward through sunbeams toward
the open sky. Grass below is softly illuminated by the digital glow.
The transformation is continuous and fluid — no cuts, no jumps.
Duration: 5 seconds.
```

**Параметры камеры:**
- Motion: Static / Subtle Tilt Up (камера почти неподвижна, лёгкий tilt вверх вслед за кодом)
- Speed: 5% tilt
- Particle flow: Continuous upward stream
- Code glow: Pulsing iridescent lavender

---

## Итоговый таймлайн

```
0:00 ━━━ 0:06 ━━━ 0:10 ━━━ 0:15 ━━━ 0:20 ━━━ 0:25
  Кадр 1    Кадр 2    Кадр 3    Кадр 4    Кадр 5
  Wide      Macro     Fly       Painting  Code
  6s        4s        5s        5s        5s

Общая длительность: 25 секунд
```

## Переходы между кадрами

| Стык | Тип перехода | Длительность |
|------|-------------|-------------|
| 1 → 2 | Dissolve (напуск) | 0.8s |
| 2 → 3 | Match cut (движение травы → движение камеры) | 0.5s |
| 3 → 4 | Dissolve (камера достигает центра → появляется картина) | 1.0s |
| 4 → 5 | Morph dissolve (холст плавно перетекает в код) | 1.2s |

---

## Экспорт для продакшена

| Назначение | Размер | Формат | FPS |
|-----------|--------|--------|-----|
| Desktop hero | 1920×1080 | WebM (VP9) + MP4 (H.265) | 24 |
| Desktop retina | 2560×1440 | MP4 (H.265) | 24 |
| Tablet | 1024×576 | WebM (VP9) | 24 |
| Mobile vertical (сторис) | 1080×1920 | MP4 (H.265), кроп центра | 24 |
| Постер (fallback) | 1920×1080 | WebP 40KB | — |

---

## Порядок работы в Higgsfield

1. Открыть https://app.higgsfield.ai → Image to Video
2. Загрузить `final-1-hall-wide.png`
3. Вставить промпт из раздела «Кадр 1»
4. Motion: Camera → Dolly In
5. Duration: 6s, 24fps
6. Generate → скачать `.mp4`
7. Повторить для кадров 2-5
8. Собрать 5 видео в монтаже (DaVinci Resolve / Premiere / CapCut)
9. Добавить crossfade-переходы согласно таблице выше
10. Экспортировать финальный `.webm` + `.mp4`

## Альтернативные инструменты

| Инструмент | Тип | Подходит для |
|-----------|-----|-------------|
| **Higgsfield** | Image → Video | Все 5 кадров |
| **Runway Gen-3** | Image → Video | Сложные трансформации (кадры 4, 5) |
| **Kling 2** | Image → Video | Реалистичная камера (кадры 1, 3) |
| **Luma Dream Machine** | Image → Video | Атмосферные сцены (кадры 2, 4) |
| **Pika 2** | Image → Video | Плавные переходы |
| **Seedance** | Multi-image → Video | Сборка всей последовательности из 5 кадров |
