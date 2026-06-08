# Exportar Orbit Survivor a Android 📱

Guía paso a paso para generar un APK de Orbit Survivor y publicarlo en Google Play Store.

---

## Requisitos

| Componente | Versión | Notas |
|------------|---------|-------|
| Godot Engine | 4.x | Cualquier release 4.0+ |
| Java JDK | 17 | OpenJDK 17 (LTS) |
| Android SDK | 33+ | Platform tools, build tools |
| Gradle | 8.x | Incluido con Android SDK |

---

## 1. Instalar Android SDK

### Opción A: Android Studio (recomendada para principiantes)

1. Descarga e instala [Android Studio](https://developer.android.com/studio)
2. Durante la instalación, asegúrate de incluir:
   - **Android SDK Platform 33** (o la versión que uses)
   - **Android SDK Build-Tools**
   - **Android SDK Command-line Tools**

### Opción B: Solo command line tools (más ligero)

```bash
# Descargar command line tools
wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip commandlinetools-linux-*.zip -d ~/android-sdk
cd ~/android-sdk/cmdline-tools
mkdir latest && mv * latest/

# Configurar variables de entorno
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"

# Instalar platform y build tools
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
```

---

## 2. Instalar Java JDK 17

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install openjdk-17-jdk

# Verificar
java -version  # Debe mostrar OpenJDK 17.x
```

> Si usas macOS o Windows, descarga de [adoptium.net](https://adoptium.net/)

---

## 3. Configurar variables de entorno

Agrega esto a `~/.bashrc` (Linux/macOS) o variables de sistema (Windows):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
# o si usaste la instalación manual:
# export ANDROID_HOME="$HOME/android-sdk"

export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

Reemplaza las rutas según tu instalación. Recarga con `source ~/.bashrc`.

---

## 4. Configurar export presets en Godot

1. Abre **Orbit Survivor** en Godot 4.x
2. Ve a **Project → Export...**
3. Haz clic en **Add...** y selecciona **Android**
4. Configura los campos obligatorios:

| Pestaña | Campo | Valor |
|---------|-------|-------|
| **Package** | Unique Name | `com.tunombre.orbitsurvivor` |
| **Package** | Version | `1` (incrementar en cada release) |
| **Package** | Version Name | `"1.0.0"` |
| **Package** | Package Source | `"Android Library"` (default) |
| **Graphics** | Orientation | `Portrait` (coincide con `project.godot`) |
| **Graphics** | Screen | `Fullscreen` |
| **User Data Backup** | Allow Backup | ✅ marcado |
| **Keystore** | Debug Keystore | Dejarlo vacío para debug APK |
| **Keystore** | Release Keystore | Configurar solo para release (ver sección 6) |

### Custom Template (APK expansion)

Godot necesita los **Android build templates**. Para instalarlos:

1. En **Project → Export → Android**, haz clic en **Install Android Build Template**
2. O descarga manualmente desde [godotengine.org/android](https://godotengine.org/download/android/)
3. Coloca `android_source_template.zip` en:
   - **Linux:** `~/.local/share/godot/export_templates/<version>/`
   - **Windows:** `%APPDATA%\Godot\export_templates\<version>\`
   - **macOS:** `~/Library/Application Support/Godot/export_templates/<version>/`

---

## 5. Exportar APK

### Debug APK (para pruebas locales)

1. En **Project → Export → Android**, selecciona tu preset
2. Haz clic en **Export Project**
3. Elige nombre y ubicación (ej. `OrbitSurvivor-debug.apk`)
4. Godot generará el APK firmado con el debug keystore automático

### Release APK (para distribución)

> Necesitas un **keystore** propio. Si no tienes uno:

```bash
keytool -genkey -v -keystore orbit-survivor.keystore \
  -alias orbit-survivor \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

1. En **Project → Export → Android → Keystore**, configura:
   - **Keystore File**: ruta a tu `.keystore`
   - **Keystore Password**: contraseña del keystore
   - **Key Alias**: el alias que usaste
   - **Key Password**: contraseña de la clave
2. Haz clic en **Export Project** → selecciona nombre (ej. `OrbitSurvivor-release.apk`)
3. Godot generará el APK release listo para distribuir

---

## 6. Probar en dispositivo

### USB Debugging

1. Habilita **Developer options** en tu Android:
   - Ajustes → Acerca del teléfono → Toca "Número de compilación" 7 veces
2. Ve a **Developer options** → Activa **USB Debugging**
3. Conecta el teléfono por USB
4. Verifica que aparezca:
   ```bash
   adb devices
   ```
5. Instala el APK directamente:
   ```bash
   adb install OrbitSurvivor-debug.apk
   ```

### Alternativa: compartir el APK

- Sube el APK a Drive, Dropbox o similar
- Descárgalo en el teléfono y ábrelo para instalar
- **Nota:** En Android 8+, puede requerir permitir "Instalar apps de fuentes desconocidas"

---

## 7. Publicar en Play Store (resumen)

### Paso 1: Crear cuenta de desarrollador
- Ve a [play.google.com/console](https://play.google.com/console)
- Paga la tarifa única de $25 USD (verifica que aplique en tu país)
- Completa el perfil de desarrollador

### Paso 2: Preparar el release
1. **Genera un APK release firmado** (ver sección 5, Release APK)
2. **Optimiza con Android App Bundle** (opcional pero recomendado):
   - En Godot, exporta como AAB en lugar de APK
   - Google Play usa AAB para generar APKs optimizados por dispositivo

### Paso 3: Completar la ficha de Play Store
- **Título:** Orbit Survivor
- **Descripción corta:** Juego arcade de supervivencia orbital
- **Descripción completa:** Explica la mecánica one-touch, coleccionables, niveles
- **Screenshots:** Al menos 2 capturas de pantalla (720×1280 recomendado)
- **Feature Graphic:** 1024×500 px
- **Icono:** 512×512 px
- **Categoría:** Games → Arcade
- **Clasificación de contenido:** PEGI 3 / ESRB Everyone (violencia mínima)

### Paso 4: Subir el APK/AAB
1. En Play Console → **Release → Production → Create new release**
2. Sube el APK o AAB firmado
3. Completa "What's new in this release" (ej. "Versión inicial")
4. Revisa y despliega

### Paso 5: Revisión y publicación
- Google revisa la app (generalmente 24-48 horas)
- Una vez aprobada, se publica en Play Store
- Las actualizaciones futuras pasan por el mismo proceso

---

## Notas importantes

> **El proyecto está configurado para Android.** Ver `project.godot` para orientación (`portrait`) y resolución (`720×1280` con stretch mode `canvas_items` y aspect `expand`).

- **Orientación:** Portrait (retrato) — configurado en `project.godot`
- **Resolución base:** 720×1280
- **Stretch mode:** `canvas_items` — escala automáticamente a cualquier resolución manteniendo aspect ratio
- **Emulate touch from mouse:** Activado en `project.godot` — permite probar con clic del mouse en PC
- **Framebuffer allocation:** `1` (rendimiento en dispositivos móviles)
- **Compatibilidad:** Android 5.0+ (API 21+)

---

## Troubleshooting

| Problema | Solución |
|----------|----------|
| `Android SDK not found` | Verifica `ANDROID_HOME` apunta al SDK correcto |
| `No build template` | Instala Android Build Templates en Godot |
| `Keystore error` | Verifica contraseñas y ruta del keystore |
| `App crashes on startup` | Revisa `adb logcat` para error específico |
| `Orientation incorrect` | Verifica `window/handheld/orientation="portrait"` en `project.godot` |
| `Text too small` | Ajusta `window/stretch/mode` o el theme de la UI |
