# Cómo agregar enemigos en Orbit Survivor 👾

Los enemigos se definen en dos lugares:
1. **Plantillas globales** en `data/enemies/templates.json` — definiciones base reutilizables
2. **Array de enemigos en cada nivel** — instancias específicas en cada `level_XX.json`

---

## Plantillas (`data/enemies/templates.json`)

Contiene plantillas base con valores por defecto para cada tipo de enemigo. Puedes usarlas como guía de propiedades, pero cada nivel define sus propios enemigos inline.

```json
{
  "templates": [
    {
      "id": "asteroid_basic",
      "name": "Asteroide Básico",
      "type": "asteroid",
      "size": 25,
      "speed_range": {"min": 0.2, "max": 0.6},
      "health": 1,
      "damage": 1,
      "color": "#AA8844",
      "collision_behavior": "destroy_on_hit",
      "tags": ["basic", "destructible", "slow"]
    },
    ...
  ]
}
```

---

## Tipos de enemigos

### 1. Asteroide (`asteroid`)

Asteroide que orbita un nodo o se mueve linealmente entre dos nodos. Daña al jugador al contacto.

**Propiedades del JSON del nivel:**

```json
{
  "id": "enemy_01",
  "type": "asteroid",
  "node_origin": "node_1",
  "orbit_index": 0,
  "angle": 0,
  "speed": 0.4,
  "direction": "clockwise",
  "size": 25
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único del enemigo |
| `type` | string | Siempre `"asteroid"` |
| `node_origin` | string | Nodo al que pertenece |
| `orbit_index` | int | Índice de la órbita donde orbita |
| `angle` | float | Ángulo inicial en grados |
| `speed` | float | Velocidad de movimiento orbital (0.1 = lento, 1.0 = rápido) |
| `direction` | string | `"clockwise"` o `"counterclockwise"` |
| `size` | float | Radio visual en píxeles (18-40 típicamente) |

**Comportamiento:**
- Se mueve a lo largo de la órbita especificada
- Si tiene `start_node_id` y `end_node_id`, se mueve linealmente entre dos nodos (ping-pong)
- Al colisionar con el jugador, emite `SignalBus.player_hit`
- Visual: círculo marrón rojizo con textura de cráteres

**Agregar a un nivel:**

```json
"enemies": [
  {"id": "astro_1", "type": "asteroid", "node_origin": "node_1", "orbit_index": 0, "angle": 180, "speed": 0.3, "direction": "clockwise", "size": 28}
]
```

---

### 2. Láser temporizado (`laser`)

Torreta fija que dispara un rayo láser visible durante un tiempo, luego se apaga en cooldown.

**Propiedades del JSON del nivel (en array `lasers`):**

```json
{
  "id": "laser_01",
  "node_id": "node_2",
  "angle": 180,
  "length": 80,
  "width": 6,
  "phase": 0.0,
  "duration": 2.0,
  "interval": 3.5,
  "color": "#FF4444"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único |
| `node_id` | string | Nodo al que pertenece |
| `angle` | float | Ángulo de orientación del láser en grados |
| `length` | float | Longitud del rayo en píxeles |
| `width` | float | Ancho del rayo en píxeles |
| `phase` | float | Fase inicial (offset de tiempo en segundos) |
| `duration` | float | Duración activa del láser en segundos |
| `interval` | float | Tiempo entre disparos (cooldown) en segundos |
| `color` | string | Color del láser en hex (opcional, default rojo) |

**Comportamiento:**
- Cicla entre estado `active` (daña) y `cooldown` (seguro)
- El láser visible tiene pulso de brillo
- Gira con la órbita del nodo
- Al colisionar con el jugador durante `active`, emite `SignalBus.player_hit`

**Agregar a un nivel:**

```json
"lasers": [
  {"id": "laser_01", "node_id": "node_2", "angle": 90, "length": 100, "width": 6, "phase": 0.0, "duration": 2.0, "interval": 3.0, "color": "#FF4444"}
]
```

---

### 3. Mina explosiva (`mine`)

Mina estática que orbita un nodo y explota cuando el jugador se acerca demasiado.

**Propiedades del JSON del nivel (en array `mines`):**

```json
{
  "id": "mine_01",
  "node_id": "node_1",
  "orbit_index": 0,
  "angle": 270,
  "radius": 12,
  "trigger_radius": 28,
  "damage": 2,
  "respawn_delay": 4.0
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único |
| `node_id` | string | Nodo al que pertenece |
| `orbit_index` | int | Índice de la órbita |
| `angle` | float | Ángulo inicial en grados |
| `radius` | float | Tamaño visual de la mina en píxeles |
| `trigger_radius` | float | Distancia de detonación (el jugador debe estar a menos de esta distancia) |
| `damage` | int | Daño infligido al explotar (2-3 típicamente) |
| `respawn_delay` | float | Segundos antes de reaparecer (actualmente la mina se destruye, no reaparece) |

**Comportamiento:**
- Detecta al jugador por distancia en espacio global
- Cuando el jugador entra en `trigger_radius`, explota:
  - Crea partículas de explosión via `ExplosionParticles`
  - Se oculta y se destruye tras 0.5s
  - Emite `SignalBus.player_hit` con el daño
- Visual: esfera roja neón pulsante con púas alrededor

**Agregar a un nivel:**

```json
"mines": [
  {"id": "mine_01", "node_id": "node_1", "orbit_index": 0, "angle": 180, "radius": 14, "trigger_radius": 30, "damage": 2, "respawn_delay": 5.0}
]
```

---

### 4. Zona magnética (`magnetic_zone`)

Zona de efecto que atrae o repele la velocidad orbital del jugador. No es un enemigo directo, pero afecta el movimiento.

**Propiedades del JSON del nivel (en array `magnetic_zones`):**

```json
{
  "id": "mag_01",
  "node_id": "node_2",
  "position": {"x": 320, "y": 420},
  "radius": 55,
  "strength": 1.3,
  "polarity": "attract",
  "color": "#44AAFF"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único |
| `node_id` | string | Nodo al que pertenece (la zona orbita este nodo) |
| `position` | object | Posición relativa `{"x": ..., "y": ...}` |
| `radius` | float | Radio de efecto en píxeles |
| `strength` | float | Potencia del efecto (1.0 = normal, más = más fuerte) |
| `polarity` | string | `"attract"` (azul) acelera al jugador, `"repel"` (rojo) lo frena |
| `color` | string | Color visual en hex |

**Comportamiento:**
- Orbita alrededor del `node_id` especificado
- Solo afecta al jugador si está en el mismo nodo y misma órbita
- La intensidad disminuye con la distancia desde el centro de la zona
- **Attract:** aumenta `speed_mult` del jugador (se mueve más rápido)
- **Repel:** disminuye `speed_mult` del jugador (se mueve más lento)
- Visual: círculo azul (attract) o rojo (repel) semi-transparente con ondas

**Agregar a un nivel:**

```json
"magnetic_zones": [
  {"id": "mag_01", "node_id": "node_1", "position": {"x": 300, "y": 600}, "radius": 60, "strength": 1.5, "polarity": "attract", "color": "#44AAFF"}
]
```

---

### 5. Enemigo móvil / dron (`drone`)

Enemigo que patrulla una ruta de nodos (transit) o permanece orbitando un nodo. Se representa visualmente como un rombo púrpura.

**Propiedades del JSON del nivel (en array `enemies` con type `drone`):**

```json
{
  "id": "enemy_04",
  "type": "drone",
  "node_origin": "node_3",
  "orbit_index": 0,
  "angle": 315,
  "speed": 0.7,
  "direction": "counterclockwise",
  "size": 18,
  "health": 4,
  "damage": 1
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único |
| `type` | string | `"drone"` para enemigos móviles |
| `node_origin` | string | Nodo de origen o primer nodo de la ruta |
| `orbit_index` | int | Órbita donde orbita |
| `angle` | float | Ángulo inicial en grados |
| `speed` | float | Velocidad de movimiento |
| `direction` | string | Dirección de movimiento orbital |
| `size` | float | Tamaño visual en píxeles |
| `health` | int | Puntos de vida |
| `damage` | int | Daño al colisionar con el jugador |

> **Nota:** El dron usa `path_nodes` internamente para rutas. Si solo tiene 1 nodo, orbita como un asteroide. Si tiene 2+ en `path_nodes`, viaja entre ellos. Actualmente la inicialización usa `node_origin` como el primer nodo.

**Comportamiento:**
- Modo TRANSIT: viaja linealmente entre nodos en su ruta, rebotando (ping-pong)
- Modo ORBITAL: orbita alrededor de un solo nodo
- Visual: rombo/diamante púrpura con brillo
- Al colisionar con el jugador, emite `SignalBus.player_hit`

**Agregar a un nivel:**

```json
"enemies": [
  {"id": "drone_01", "type": "drone", "node_origin": "node_1", "orbit_index": 0, "angle": 180, "speed": 0.6, "direction": "clockwise", "size": 20, "health": 3, "damage": 1}
]
```

---

## Ejemplo de nivel con todos los tipos de enemigos

```json
{
  "id": "level_demo_all_enemies",
  "name": "Demostración de Enemigos",
  "description": "Un nivel con cada tipo de enemigo",
  "order": 99,
  "unlock_requirement": "none",
  "requires_key": false,
  "time_target": 60.0,
  "orbital_speed": 1.2,
  "obstacle_speed_mult": 1.0,
  "nodes": [
    {
      "id": "node_1",
      "position": {"x": 200, "y": 500},
      "orbits": [
        {"radius": 80, "speed": 1.0, "direction": "clockwise"},
        {"radius": 150, "speed": 0.8, "direction": "counterclockwise"}
      ],
      "start_node": true
    },
    {
      "id": "node_2",
      "position": {"x": 500, "y": 700},
      "orbits": [
        {"radius": 90, "speed": 1.1, "direction": "counterclockwise"}
      ],
      "start_node": false
    }
  ],
  "obstacles": [
    {"id": "obs_01", "node_id": "node_1", "orbit_index": 0, "angle": 90, "size": 16, "type": "static"},
    {"id": "obs_02", "node_id": "node_2", "orbit_index": 0, "angle": 180, "size": 18, "type": "static"}
  ],
  "crystals": [
    {"id": "crystal_1", "node_id": "node_1", "orbit_index": 0, "angle": 45},
    {"id": "crystal_2", "node_id": "node_2", "orbit_index": 0, "angle": 270}
  ],
  "portal": {"node_id": "node_2", "orbit_index": 0, "angle": 0},
  "key": null,
  "enemies": [
    {"id": "ene_01", "type": "asteroid", "node_origin": "node_1", "orbit_index": 0, "angle": 0, "speed": 0.4, "direction": "clockwise", "size": 25},
    {"id": "ene_02", "type": "asteroid", "node_origin": "node_1", "orbit_index": 1, "angle": 180, "speed": 0.3, "direction": "counterclockwise", "size": 30},
    {"id": "ene_03", "type": "drone", "node_origin": "node_2", "orbit_index": 0, "angle": 90, "speed": 0.5, "direction": "counterclockwise", "size": 18, "health": 3, "damage": 1}
  ],
  "magnetic_zones": [
    {"id": "mag_01", "node_id": "node_1", "position": {"x": 160, "y": 460}, "radius": 50, "strength": 1.3, "polarity": "attract", "color": "#44AAFF"}
  ],
  "lasers": [
    {"id": "las_01", "node_id": "node_2", "angle": 135, "length": 80, "width": 6, "phase": 0.0, "duration": 2.0, "interval": 3.5, "color": "#FF4444"}
  ],
  "mines": [
    {"id": "min_01", "node_id": "node_1", "orbit_index": 0, "angle": 270, "radius": 12, "trigger_radius": 28, "damage": 2, "respawn_delay": 4.0}
  ],
  "stars_threshold": {"one_star": 0, "two_stars": 0, "three_stars": 0}
}
```

---

## Resumen rápido

| Tipo | Array en JSON | Script | Daño | Comportamiento clave |
|------|---------------|--------|------|---------------------|
| Asteroide | `enemies` (type: `"asteroid"`) | `asteroid.gd` | 1-2 | Orbita un nodo o viaja entre dos |
| Láser | `lasers` | `laser.gd` | 1 | Cicla activo/cooldown, visible |
| Mina | `mines` | `mine.gd` | 2-3 | Explota al acercarse |
| Zona magnética | `magnetic_zones` | `magnetic_zone.gd` | — | Atrae o repele al jugador |
| Dron | `enemies` (type: `"drone"`) | `moving_enemy.gd` | 1 | Patrulla nodos o un solo nodo |

> **Consejo:** Si un enemigo no aparece, verifica que `node_id` o `node_origin` exista en el array `nodes` y que `orbit_index` no supere la cantidad de órbitas de ese nodo.
