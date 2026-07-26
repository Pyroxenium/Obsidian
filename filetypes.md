# Obsidian Engine Asset Formats

Referenz für die Asset-Dateiformate des Obsidian Engine Asset Loaders.

---

## `.obs` - Sprite-Dateien

Serialisierte Lua-Tabelle für Multi-Frame-Sprites mit Zeichen-, Vordergrund- und Hintergrund-Layern.

### Struktur

```lua
{
    width = 16,        -- Breite des Sprites in Zeichen
    height = 8,        -- Höhe des Sprites in Zeichen
    frameCount = 4,    -- Anzahl der Animationsframes
    
    -- Frames (1 bis frameCount)
    [1] = {
        [1] = { "a", "b", "c", ... },  -- Layer 1: Characters (width x height)
        [2] = { "0", "f", "e", ... },  -- Layer 2: Foreground colors (Blit-Hex)
        [3] = { "f", "0", "1", ... }   -- Layer 3: Background colors (Blit-Hex)
    },
    [2] = { ... },  -- Frame 2
    -- ...
}
```

### Regeln

- **Jeder Frame** muss genau 3 Layer haben
- **Jeder Layer** muss exakt `height` Zeilen haben
- **Jede Zeile** muss exakt `width` Zeichen haben
- **Characters**: Einzelne String-Zeichen oder Tabellen mit Single-Char-Strings
- **Colors**: Blit-Hex-Zeichen (`0-9`, `a-f`) für CC:Tweaked Farbpalette
- Transparente Zellen: Leerzeichen `" "` im Character-Layer

### Beispiel

```lua
{
    width = 3,
    height = 2,
    frameCount = 1,
    [1] = {
        [1] = { {"@", " ", "@"}, {" ", "O", " "} },  -- Chars
        [2] = { {"e", " ", "e"}, {" ", "4", " "} },  -- Fore
        [3] = { {"0", " ", "0"}, {" ", "f", " "} }   -- Back
    }
}
```

---

## `.oui` - UI-Layout-Dateien

Serialisierte Lua-Tabelle für UI-Element-Definitionen.

### Struktur

```lua
{
    elements = {
        ["elementName"] = {
            -- Beliebige Properties
            x = 10,
            y = 5,
            width = 20,
            text = "Button",
            -- ...
        },
        ["anotherElement"] = {
            -- ...
        }
    }
}
```

### Regeln

- Top-Level-Tabelle mit `elements` Key
- Jedes Element ist durch einen String-Key identifiziert
- Properties sind frei definierbar (keine Validierung durch Loader)

### Beispiel

```lua
{
    elements = {
        ["titleBar"] = {
            x = 1,
            y = 1,
            width = 51,
            height = 1,
            text = "Obsidian Engine",
            bgColor = "7"
        },
        ["menuButton"] = {
            x = 2,
            y = 3,
            text = "Start Game",
            action = "startGame"
        }
    }
}
```

---

## `.pe` - Particle Emitter-Dateien

Serialisierte Lua-Tabelle für Partikel-Emitter-Konfiguration.

### Struktur

```lua
{
    -- Optionales eingebettetes Sprite (gleiche Struktur wie .obs)
    sprite = {
        width = 1,
        height = 1,
        frameCount = 1,
        [1] = { ... }
    },
    
    -- Emitter-Properties (werden von particles.lua verwendet)
    active = true,
    spawnRate = 10,
    angle = 0,
    spread = 360,
    speedMin = 5,
    speedMax = 10,
    lifeMin = 1,
    lifeMax = 2,
    z = 1,
    bounce = false,
    gravityScale = 0,
    drag = 0,
    colors = { "0", "8", "7", "f" },  -- Farbverlauf
    chars = { ".", "o", "O", "*" }    -- Zeichen-Animation
}
```

### Regeln

- `sprite` ist optional - wenn vorhanden, wird es wie `.obs` verarbeitet
- Alle anderen Properties sind frei definierbar
- `colors` und `chars` werden für Partikel-Animation verwendet

### Beispiel

```lua
{
    sprite = {
        width = 1,
        height = 1,
        frameCount = 1,
        [1] = {
            [1] = { {"*"} },
            [2] = { {"e"} },
            [3] = { {"0"} }
        }
    },
    active = true,
    spawnRate = 20,
    angle = 270,
    spread = 30,
    speedMin = 8,
    speedMax = 15,
    lifeMin = 0.5,
    lifeMax = 1.5,
    colors = { "e", "4", "5", "8" },
    gravityScale = 1,
    bounce = true
}
```

---

## Loader API

```lua
local loader = require("core.loader")

-- Sprite laden
local sprite = loader.loadSprite("assets/player.obs")

-- UI laden
local ui = loader.loadUI("assets/menu.oui")

-- Emitter laden
local emitter = loader.loadEmitter("assets/fire.pe")

-- Cache verwalten
loader.unload("assets/player.obs")
loader.clearCache()

-- Basis-Pfad setzen
loader.setBasePath("assets/")
```

### Caching

Alle geladenen Assets werden automatisch gecacht. Beim erneuten Laden wird die gecachte Version zurückgegeben.

---

## Blit-Hex Farben (CC:Tweaked)

```
0 = white       8 = gray
1 = orange      9 = light gray
2 = magenta     a = cyan
3 = light blue  b = purple
4 = yellow      c = blue
5 = lime        d = brown
6 = pink        e = green
7 = dark gray   f = black
```