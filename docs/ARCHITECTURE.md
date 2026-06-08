# Arquitectura de Orbit Survivor 🏗️

## Diagrama de arquitectura (ASCII)

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTOLOADS (singletons)                       │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────┐  │
│  │  SignalBus   │  │ GameConstants│  │       GameManager         │  │
│  │  (signals.gd)│  │ (globals.gd) │  │     (game_manager.gd)    │  │
│  └──────┬───────┘  └──────────────┘  └────────────┬──────────────┘  │
│         │                                          │                 │
│         ▼                                          ▼                 │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │                      MANAGERS LAYER                          │   │
│  │                                                              │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │   │
│  │  │ LevelManager │  │ SaveManager  │  │  AudioManager    │   │   │
│  │  │ Carga JSONs  │  │ Guarda pro-  │  │  SFX + Música    │   │   │
│  │  │ de niveles   │  │ greso en disco│  │                  │   │   │
│  │  └──────┬───────┘  └──────────────┘  └──────────────────┘   │   │
│  │         │                                                    │   │
│  │  ┌──────────────┐  ┌──────────────────┐                     │   │
│  │  │  Difficulty  │  │   StarSystem     │                     │   │
│  │  │  Manager     │  │   Calcula        │                     │   │
│  │  │  Escala dif. │  │   estrellas      │                     │   │
│  │  └──────────────┘  └──────────────────┘                     │   │
│  └───────────────────────────────────────────────────────────────┘   │
│                                                                     │
│         │ emiten/reciben señales via SignalBus                      │
│         ▼                                                           │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    SCENE LAYER                               │   │
│  │                                                              │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐ │   │
│  │  │ MainMenu  │  │LevelSelect │  │      LevelScene        │ │   │
│  │  │           │  │            │  │  ┌──────────────────┐  │ │   │
│  │  │           │  │            │  │  │  OrbitSystem     │  │ │   │
│  │  │           │  │            │  │  │  ┌────────────┐  │  │ │   │
│  │  │           │  │            │  │  │  │ OrbitNode  │  │  │ │   │
│  │  │           │  │            │  │  │  │ OrbitNode  │  │  │ │   │
│  │  │           │  │            │  │  │  │ PlayerOrb. │  │  │ │   │
│  │  │           │  │            │  │  │  │ Asteroids  │  │  │ │   │
│  │  │           │  │            │  │  │  │ Lasers     │  │  │ │   │
│  │  │           │  │            │  │  │  │ Mines      │  │  │ │   │
│  │  │           │  │            │  │  │  │ MagneticZ. │  │  │ │   │
│  │  │           │  │            │  │  │  └────────────┘  │  │ │   │
│  │  └────────────┘  └────────────┘  │  └──────────────────┘  │ │   │
│  │                                 │  ┌──────────────────┐  │ │   │
│  │                                 │  │ GameHUD          │  │ │   │
│  │                                 │  │ VictoryScreen    │  │ │   │
│  │                                 │  │ GameOverScreen   │  │ │   │
│  │                                 │  └──────────────────┘  │ │   │
│  │  ┌────────────┐  ┌────────────┐ └────────────────────────┘ │   │
│  │  │ ShopScreen │  │ Settings   │                             │   │
│  │  │            │  │ Screen     │                             │   │
│  │  └────────────┘  └────────────┘                             │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Managers y sus responsabilidades

### SignalBus (`scripts/core/signals.gd`)
Autoload singleton. **Canal central de comunicación** entre todos los sistemas del juego. Ningún sistema se comunica directamente con otro — todos emiten y reciben señales a través de `SignalBus`. Esto desacopla completamente las capas.

Señales principales:
- `game_started`, `game_over`, `level_completed` — flujo de juego
- `player_hit`, `orbit_changed` — jugador
- `crystal_collected`, `key_collected`, `portal_reached` — recolectables
- `level_selected` — selección de nivel
- `scene_changed` — navegación entre escenas
- `settings_changed`, `save_loaded` — sistema

### GameManager (`scripts/core/game_manager.gd`)
**Coordinador central** del juego. Orquesta el flujo de la partida: iniciar, pausar, terminar, reiniciar y avanzar al siguiente nivel. Mantiene referencias a los otros managers, pero no conoce sus detalles internos. Delega toda la lógica específica a los managers correspondientes.

### LevelManager (`scripts/managers/level_manager.gd`)
Carga niveles desde archivos JSON en `data/levels/`. Lee el archivo, parsea el JSON, y emite `level_loaded` con los datos estructurados para que `OrbitSystem` los consuma. Maneja la descarga del nivel anterior antes de cargar uno nuevo.

### SaveManager (`scripts/managers/save_manager.gd`)
Persistencia del progreso del jugador: estrellas por nivel, cristales acumulados, llaves recolectadas. Guarda y carga desde `user://orbit_survivor_save.json` usando `FileAccess`. Provee métodos para leer/escribir estrellas, cristales y llaves. No depende de ningún otro sistema.

### AudioManager (`scripts/managers/audio_manager.gd`)
Reproduce efectos de sonido (SFX) y música. Crea dinámicamente `AudioStreamPlayer2D` para SFX y música por separado. Busca archivos en `assets/audio/sfx/` y `assets/audio/music/`. Soporta `.ogg` y `.wav`. Volumen configurable mediante `set_sfx_volume` / `set_music_volume`.

### DifficultyManager (`scripts/managers/difficulty_manager.gd`)
Escala la dificultad por nivel según `data/difficulty/scale.json`. Proporciona multiplicadores de velocidad, cantidad de enemigos, densidad de obstáculos, salud de enemigos, tiempo objetivo y multiplicador de puntuación. Los valores se usan combinados con los del JSON del nivel.

### StarSystem (`scripts/managers/star_system.gd`)
Calcula la calificación de estrellas (1-3) por nivel basándose en:
- **3 estrellas:** completar en menos del `time_target` con 0 muertes
- **2 estrellas:** completar en menos de 2× `time_target` con ≤ 2 muertes
- **1 estrella:** cualquier otro resultado

---

## Sistema de señales (SignalBus)

El patrón de comunicación es **SignalBus centralizado**:

```
┌──────────┐       ┌────────────┐       ┌──────────┐
│ Sistema A │──────▶│ SignalBus  │◀──────│ Sistema B │
│           │       │            │       │          │
│  Emite    │       │  Enruta    │       │  Escucha │
└──────────┘       └────────────┘       └──────────┘
```

**Principios:**
- Ningún sistema importa o referencia directamente a otro (excepto autoloads)
- Las señales se conectan en `_ready()` y se desconectan en `_exit_tree()`
- `SignalBus` es el único punto de acoplamiento
- Los datos viajan como parámetros tipados en las señales

---

## Flujo de juego

```
[MENÚ PRINCIPAL]
       │
       ▼
[LEVEL SELECT] ◀──────────────────────────────┐
       │                                      │
       ▼ (selecciona nivel)                   │
[LEVEL SCENE]                                 │
  ├── LevelManager.load_level(id)             │
  ├── OrbitSystem.build_from_level_data()     │
  │     ├── Crea OrbitNodes                   │
  │     ├── Crea PlayerOrbiter                │
  │     ├── Spawnea crystals, portal, key     │
  │     └── Spawnea obstacles, enemies, etc.  │
  ├── GameHUD.start_hud()                     │
  │                                           │
  ├── Player muere ──► [GAME OVER] ──► Retry ─┤
  │                                           │
  └── Portal alcanzado ──► [VICTORY]          │
         ├── Calcula estrellas                │
         ├── Guarda progreso                  │
         ├── Siguiente nivel ─────────────────┘
         └── Volver a niveles ────────────────┘
```

**Transiciones entre escenas:**
- `MainMenu` → emite `SignalBus.scene_changed.emit("main_menu", "level_select")`
- `LevelSelect` → emite `SignalBus.level_selected.emit(level_id)`
- `LevelScene` → cuando el jugador llega al portal → `LevelManager.load_level()` del siguiente
- `VictoryScreen` / `GameOverScreen` → emiten `scene_changed` o `level_selected` para navegar

---

## Principios de diseño

### SOLID aplicado

| Principio | Aplicación |
|-----------|------------|
| **S** — Single Responsibility | Cada manager tiene una única responsabilidad (cargar niveles, guardar, audio, dificultad, estrellas) |
| **O** — Open/Closed | Los sistemas son extensibles via señales y composición; no requieren modificar código existente para agregar features |
| **L** — Liskov Substitution | `Asteroid`, `Laser`, `Mine` etc. son hijos de `Area2D`; cualquier enemigo puede sustituir a otro sin romper el sistema |
| **I** — Interface Segregation | `SignalBus` tiene señales específicas por dominio (game flow, player, collectibles, progression, system) |
| **D** — Dependency Inversion | Los sistemas altos (GameManager) no dependen de sistemas bajos; ambos dependen de abstracciones via SignalBus |

### Modularidad
- **Managers**: cada uno en su propio archivo, con su propia responsabilidad
- **Enemies**: cada tipo en su propio script, todos heredan de `Area2D`
- **UI**: cada pantalla es independiente, comunicándose solo por `SignalBus`
- **Data**: niveles, enemigos y dificultad están en JSON, no hardcodeados

### Desacoplamiento
- `LevelScene` es el único punto que coordina los subsistemas durante el juego
- `SignalBus` evita dependencias circulares entre managers
- Los enemigos buscan su `OrbitSystem` ancestral mediante `_get_orbit_system()`, no por referencia directa
- El `LevelManager` no sabe cómo se renderiza un nivel; solo emite datos
- El `SaveManager` no conoce la estructura interna de los niveles

---

## Cómo se comunican los sistemas

### 1. Autoloads (singletons)
`SignalBus`, `GameConstants`, `GameManager`, `LevelManager`, `SaveManager`, `AudioManager`, `StarSystem` y `DifficultyManager` están registrados como autoloads en `project.godot`. Están disponibles globalmente sin necesidad de instanciarlos.

### 2. Señales de SignalBus
Ejemplo de flujo completo:
```
1. LevelSelect emite: SignalBus.level_selected.emit("level_05")
2. LevelScene escucha y llama: LevelManager.load_level("level_05")
3. LevelManager lee JSON y emite: LevelManager.level_loaded.emit(data)
4. LevelScene recibe data y llama: OrbitSystem.build_from_level_data(data)
5. OrbitSystem construye el nivel y listo
```

### 3. Colisiones (Area2D → SignalBus)
```
1. Asteroid colisiona con PlayerOrbiter
2. Asteroid llama: SignalBus.player_hit.emit(damage, self)
3. LevelScene escucha y ejecuta game over
```

### 4. Comunicación padre-hijo
- `OrbitSystem` es padre de `OrbitNode`, `PlayerOrbiter`, `Crystal`, etc.
- Los enemigos usan `_get_orbit_system()` para encontrar su sistema padre
- `LevelScene` contiene y coordina `OrbitSystem`, `GameHUD`, y las pantallas de fin de juego
