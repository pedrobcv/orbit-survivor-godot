# Orbit Survivor 🚀✨

**Orbit Survivor** es un juego arcade de supervivencia orbital desarrollado en **Godot 4.x** usando **GDScript**. El jugador orbita alrededor de nodos espaciales, recolecta cristales, esquivando obstáculos y enemigos, hasta alcanzar el portal de salida.

Mecánica principal: **un toque en la pantalla** cambia de órbita o salta al nodo más cercano. Cada nivel introduce nuevos desafíos: asteroides, láseres temporizados, minas explosivas, zonas magnéticas y enemigos móviles.

---

## Stack

| Componente  | Tecnología               |
|-------------|--------------------------|
| Motor       | Godot 4.x                |
| Lenguaje    | GDScript                 |
| Datos       | JSON (niveles, enemigos, dificultad) |
| Plataforma  | Android / PC             |

---

## Cómo abrir el proyecto

1. Abre **Godot 4.x**.
2. Haz clic en **Import**.
3. Selecciona el archivo `project.godot` en la raíz del proyecto.
4. El proyecto se carga con todos los scripts y escenas configurados.

> No requiere compilación adicional — es puro GDScript.

---

## Estructura del proyecto (simplificada)

```
orbit-survivor/
├── project.godot              # Configuración del proyecto
├── default_bus_layout.tres    # Layout de audio
├── README.md                  # Este archivo
├── docs/                      # Documentación
│   ├── ARCHITECTURE.md
│   ├── HOW_TO_ADD_LEVELS.md
│   ├── HOW_TO_ADD_ENEMIES.md
│   └── ANDROID_EXPORT.md
├── scripts/
│   ├── core/                  # Autoloads globales
│   │   ├── signals.gd         # SignalBus central
│   │   ├── globals.gd         # GameConstants
│   │   └── game_manager.gd    # GameManager
│   ├── managers/              # Managers del juego
│   │   ├── level_manager.gd
│   │   ├── save_manager.gd
│   │   ├── audio_manager.gd
│   │   ├── difficulty_manager.gd
│   │   └── star_system.gd
│   ├── player/                # Sistemas del jugador
│   │   ├── orbit_system.gd
│   │   ├── orbit_node.gd
│   │   └── player_orbiter.gd
│   ├── enemies/               # Tipos de enemigos
│   │   ├── asteroid.gd
│   │   ├── laser.gd
│   │   ├── mine.gd
│   │   ├── moving_enemy.gd
│   │   └── magnetic_zone.gd
│   ├── objects/               # Objetos del juego
│   │   ├── crystal.gd
│   │   ├── portal.gd
│   │   ├── key_item.gd
│   │   └── obstacle.gd
│   ├── levels/                # Escenas y control de nivel
│   │   ├── level_scene.gd
│   │   └── camera_controller.gd
│   ├── ui/                    # Interfaz de usuario
│   │   ├── main_menu.gd
│   │   ├── level_select.gd
│   │   ├── game_hud.gd
│   │   ├── pause_menu.gd
│   │   ├── victory_screen.gd
│   │   ├── game_over_screen.gd
│   │   ├── settings_screen.gd
│   │   ├── shop_screen.gd
│   │   └── credits_screen.gd
│   └── effects/               # Efectos visuales
│       ├── explosion_particles.gd
│       ├── star_effect.gd
│       └── trail_effect.gd
└── data/
    ├── levels/                # Niveles en JSON (level_01.json … level_10.json)
    ├── enemies/
    │   └── templates.json     # Plantillas de enemigos
    └── difficulty/
        └── scale.json         # Escalado de dificultad global
```

---

## Controles

| Acción                 | Input                                      |
|------------------------|--------------------------------------------|
| Cambiar órbita         | **Un toque** en la pantalla                |
| Saltar a otro nodo     | **Un toque** (cuando se agotan las órbitas) |
| Pausar                 | Botón de pausa en HUD o tecla Escape       |

La jugabilidad es **one-touch**: un solo toque cambia a la siguiente órbita del nodo actual, y cuando se agotan, salta al nodo más cercano.

---

## Créditos

- **Desarrollado por:** Nous Research Team
- **Motor:** Godot Engine 4.x
- **Repositorio:** [github.com/pedrobcv/orbit-survivor-godot](https://github.com/pedrobcv/orbit-survivor-godot)
- **© 2026 Orbit Survivor**

---

## Capturas

*(Agregar capturas de pantalla aquí)*

```
┌─────────────────────────────────┐
│                                 │
│   ¡Próximamente!               │
│                                 │
│   Capturas del gameplay:        │
│   - Menú principal              │
│   - Level select                │
│   - Nivel en acción             │
│   - Pantalla de victoria        │
│                                 │
└─────────────────────────────────┘
```

---

## Enlaces

- [Documentación de arquitectura](docs/ARCHITECTURE.md)
- [Cómo agregar niveles](docs/HOW_TO_ADD_LEVELS.md)
- [Cómo agregar enemigos](docs/HOW_TO_ADD_ENEMIES.md)
- [Exportar a Android](docs/ANDROID_EXPORT.md)
