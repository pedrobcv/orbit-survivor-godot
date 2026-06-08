# Cómo agregar niveles en Orbit Survivor 🎮

Los niveles se definen completamente en **archivos JSON** dentro de `data/levels/`. No necesitas abrir Godot para crear un nivel — solo editar un JSON.

---

## Formato del JSON de nivel

Cada archivo de nivel (ej. `level_01.json`) tiene esta estructura:

```json
{
  "id": "level_XX",
  "name": "Nombre del Nivel",
  "description": "Descripción corta",
  "order": 1,
  "unlock_requirement": "none",
  "requires_key": false,
  "time_target": 30.0,
  "orbital_speed": 1.0,
  "obstacle_speed_mult": 1.0,
  "nodes": [ ... ],
  "obstacles": [ ... ],
  "crystals": [ ... ],
  "portal": { ... },
  "key": null,
  "enemies": [ ... ],
  "magnetic_zones": [ ... ],
  "lasers": [ ... ],
  "mines": [ ... ],
  "stars_threshold": { ... }
}
```

### Campos explicados

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | string | Identificador único del nivel. Formato: `"level_XX"` (ej. `"level_11"`). El nombre del archivo debe coincidir: `level_11.json` |
| `name` | string | Nombre visible en el level select |
| `description` | string | Texto descriptivo corto |
| `order` | int | Orden de aparición en el grid (1-based). Determina también el orden de desbloqueo |
| `unlock_requirement` | string | `"none"` para siempre disponible, o `"level_XX"` para requerir el nivel anterior completado |
| `requires_key` | bool | Si es `true`, el portal estará bloqueado hasta recolectar la llave |
| `time_target` | float | Tiempo objetivo en segundos para obtener 3 estrellas (par time) |
| `orbital_speed` | float | Multiplicador de velocidad orbital base del nivel (1.0 = normal) |
| `obstacle_speed_mult` | float | Multiplicador de velocidad de obstáculos enemigos |
| `nodes` | array | Array de nodos orbitales (ver abajo) |
| `obstacles` | array | Array de obstáculos estáticos |
| `crystals` | array | Array de cristales recolectables |
| `portal` | object | Portal de salida del nivel |
| `key` | object/null | Llave para desbloquear el portal (si `requires_key: true`) |
| `enemies` | array | Array de enemigos (asteroides, drones) |
| `magnetic_zones` | array | Array de zonas magnéticas |
| `lasers` | array | Array de láseres temporizados |
| `mines` | array | Array de minas explosivas |
| `stars_threshold` | object | Thresholds para estrellas (actualmente no se usa — las estrellas se calculan en `StarSystem`) |

---

## Arrays detallados

### nodes
```json
{
  "id": "node_1",
  "position": {"x": 360, "y": 640},
  "orbits": [
    {"radius": 100, "speed": 1.0, "direction": "clockwise"}
  ],
  "start_node": true
}
```
- `id`: Identificador único del nodo (referenciado por otros objetos)
- `position`: Coordenadas en píxeles del centro del nodo
- `orbits`: Array de órbitas concéntricas. Cada órbita tiene:
  - `radius`: Radio en píxeles
  - `speed`: Velocidad de rotación orbital
  - `direction`: `"clockwise"` o `"counterclockwise"`
- `start_node`: `true` para el nodo donde aparece el jugador

### obstacles
```json
{"id": "obs_01", "node_id": "node_1", "orbit_index": 0, "angle": 45, "size": 16, "type": "static"}
```
- `id`: Identificador único
- `node_id`: Nodo al que pertenece
- `orbit_index`: Índice de la órbita (0 = primera órbita)
- `angle`: Ángulo en grados (0 = derecha, 90 = arriba, etc.)
- `size`: Radio del obstáculo en píxeles
- `type`: Siempre `"static"`

### crystals
```json
{"id": "crystal_1", "node_id": "node_1", "orbit_index": 0, "angle": 90}
```
- `id`: Identificador único
- `node_id`: Nodo al que pertenece
- `orbit_index`: Índice de la órbita
- `angle`: Ángulo en grados donde aparece

### portal
```json
{"node_id": "node_1", "orbit_index": 0, "angle": 270}
```
- `node_id`: Nodo donde está el portal
- `orbit_index`: Órbita donde está
- `angle`: Ángulo en grados

### key (solo si `requires_key: true`)
```json
{"node_id": "node_1", "orbit_index": 0, "angle": 90, "id": "key_level_05"}
```
- `node_id`: Nodo donde aparece la llave
- `orbit_index`: Órbita
- `angle`: Ángulo
- `id`: Identificador único de la llave

### enemies, lasers, mines, magnetic_zones
Ver [HOW_TO_ADD_ENEMIES.md](HOW_TO_ADD_ENEMIES.md) para la documentación completa de cada tipo.

---

## Paso a paso: agregar un nuevo nivel

### 1. Copia un nivel existente
```bash
cp data/levels/level_10.json data/levels/level_11.json
```

### 2. Modifica el JSON
Edita `level_11.json` y cambia al menos:
- `id`: `"level_11"`
- `name`: Un nombre único
- `description`: Breve descripción
- `order`: `11`
- `unlock_requirement`: `"level_10"`

### 3. Agrega nodos, obstáculos, cristales y portal
Diseña el nivel con los arrays correspondientes.

### 4. Verifica el JSON
Asegúrate de que el JSON sea válido. Puedes usar:
```bash
python3 -m json.tool data/levels/level_11.json
```

### 5. Abre el juego
- El nivel **debe aparecer automáticamente** en el level select
- Si `order: 11` y tienes al menos 1 estrella en level_10, el nivel estará desbloqueado
- Los niveles se cargan dinámicamente escaneando `res://data/levels/`

> **Importante:** No necesitas registrar el nivel en ningún lado. El `LevelSelect` escanea todos los archivos `level_XX.json` en `data/levels/` y los muestra automáticamente.

---

## Cómo ajustar la dificultad

### time_target
```json
"time_target": 60.0
```
Tiempo en segundos para obtener 3 estrellas. Valores recomendados:
- Fácil: 30-45s
- Normal: 45-60s
- Difícil: 60-90s
- Experto: 90-120s+

### orbital_speed
```json
"orbital_speed": 1.5
```
Multiplicador de velocidad orbital. Valores:
- 1.0 = normal
- 1.2-1.5 = más rápido (más difícil de controlar)
- 1.8+ = muy rápido (solo para niveles extremos)

### obstacle_speed_mult
```json
"obstacle_speed_mult": 1.3
```
Multiplicador de velocidad para enemigos en este nivel. Se combina con el multiplicador global de `data/difficulty/scale.json`.

---

## Ejemplo completo: level_11.json

```json
{
  "id": "level_11",
  "name": "El Vacío Magnético",
  "description": "Navega campos magnéticos y esquiva láseres",
  "order": 11,
  "unlock_requirement": "level_10",
  "requires_key": false,
  "time_target": 75.0,
  "orbital_speed": 1.6,
  "obstacle_speed_mult": 1.4,
  "nodes": [
    {
      "id": "node_1",
      "position": {"x": 200, "y": 500},
      "orbits": [
        {"radius": 70, "speed": 1.2, "direction": "clockwise"},
        {"radius": 130, "speed": 1.0, "direction": "counterclockwise"}
      ],
      "start_node": true
    },
    {
      "id": "node_2",
      "position": {"x": 520, "y": 600},
      "orbits": [
        {"radius": 80, "speed": 1.3, "direction": "counterclockwise"}
      ],
      "start_node": false
    },
    {
      "id": "node_3",
      "position": {"x": 360, "y": 900},
      "orbits": [
        {"radius": 90, "speed": 1.1, "direction": "clockwise"}
      ],
      "start_node": false
    }
  ],
  "obstacles": [
    {"id": "obs_01", "node_id": "node_1", "orbit_index": 0, "angle": 90, "size": 16, "type": "static"},
    {"id": "obs_02", "node_id": "node_1", "orbit_index": 0, "angle": 270, "size": 16, "type": "static"},
    {"id": "obs_03", "node_id": "node_2", "orbit_index": 0, "angle": 45, "size": 18, "type": "static"},
    {"id": "obs_04", "node_id": "node_2", "orbit_index": 0, "angle": 180, "size": 18, "type": "static"},
    {"id": "obs_05", "node_id": "node_3", "orbit_index": 0, "angle": 0, "size": 20, "type": "static"},
    {"id": "obs_06", "node_id": "node_3", "orbit_index": 0, "angle": 135, "size": 20, "type": "static"}
  ],
  "crystals": [
    {"id": "crystal_1", "node_id": "node_1", "orbit_index": 0, "angle": 45},
    {"id": "crystal_2", "node_id": "node_1", "orbit_index": 1, "angle": 180},
    {"id": "crystal_3", "node_id": "node_2", "orbit_index": 0, "angle": 270},
    {"id": "crystal_4", "node_id": "node_3", "orbit_index": 0, "angle": 90}
  ],
  "portal": {"node_id": "node_3", "orbit_index": 0, "angle": 270},
  "key": null,
  "enemies": [
    {"id": "enemy_01", "type": "asteroid", "node_origin": "node_1", "orbit_index": 1, "angle": 0, "speed": 0.5, "direction": "clockwise", "size": 22},
    {"id": "enemy_02", "type": "asteroid", "node_origin": "node_2", "orbit_index": 0, "angle": 135, "speed": 0.6, "direction": "counterclockwise", "size": 25}
  ],
  "magnetic_zones": [
    {"id": "mag_01", "node_id": "node_1", "position": {"x": 160, "y": 460}, "radius": 55, "strength": 1.5, "polarity": "repel", "color": "#FF4444"},
    {"id": "mag_02", "node_id": "node_2", "position": {"x": 560, "y": 640}, "radius": 50, "strength": 1.2, "polarity": "attract", "color": "#44AAFF"}
  ],
  "lasers": [
    {"id": "laser_01", "node_id": "node_3", "angle": 90, "length": 90, "width": 6, "phase": 0.0, "duration": 1.5, "interval": 3.0, "color": "#FF4444"}
  ],
  "mines": [
    {"id": "mine_01", "node_id": "node_1", "orbit_index": 1, "angle": 315, "radius": 12, "trigger_radius": 28, "damage": 2, "respawn_delay": 4.0}
  ],
  "stars_threshold": {"one_star": 0, "two_stars": 0, "three_stars": 0}
}
```

---

## Verificación

1. Guarda el archivo `data/levels/level_11.json`
2. Abre Godot y ejecuta el proyecto (F5)
3. Ve al **Level Select**
4. El nivel **debe aparecer** como "Nivel 11" en el grid
5. Si tienes al menos 1 estrella en el nivel 10, estará desbloqueado
6. Haz clic y juega

> Si no aparece, verifica: la extensión es `.json`, `id` coincide con el nombre del archivo, y el JSON es válido.
