# UbicaSafe

<p align="center">
  <img src="assets/readme/ubicasafe-hero.png" alt="UbicaSafe - prevencion inteligente de robos en tiempo real">
</p>

UbicaSafe es una aplicacion movil de seguridad preventiva que combina mapas de riesgo, ubicacion en tiempo real, reportes ciudadanos e inteligencia artificial para ayudar a las personas a desplazarse con mayor informacion y confianza.

El proyecto esta pensado como una base adaptable para ciudades, comunidades, universidades, barrios u organizaciones que quieran transformar datos de seguridad en alertas utiles, recomendaciones y asistencia inmediata.

## Propuesta

- Visualizar zonas de riesgo en un mapa interactivo.
- Consultar la ubicacion personal en tiempo real con avatar.
- Reportar incidentes de seguridad desde la app.
- Recibir recomendaciones preventivas segun el contexto.
- Conversar con un asistente de IA para orientacion rapida.
- Integrar datos locales y servicios externos mediante API.

## Caracteristicas

| Area | Descripcion |
|---|---|
| Mapas | OpenStreetMap con `flutter_map`, zonas, radios de riesgo y marcadores. |
| Ubicacion | Seguimiento GPS, permisos de ubicacion y marcador personalizado. |
| IA | Asistente conversacional, voz/audio y flujos de orientacion. |
| Reportes | Registro de incidentes para alimentar datos de seguridad. |
| Prevencion | Recomendaciones, contenido educativo y recursos multimedia. |
| Backend | Servicios HTTP para reportes, zonas y funciones inteligentes. |

## Stack

- **Mobile**: Flutter, Dart
- **Mapas**: OpenStreetMap, `flutter_map`, `latlong2`
- **Geolocalizacion**: `geolocator`, `permission_handler`
- **Autenticacion**: Firebase Auth, Google Sign-In
- **IA y voz**: Gemini, RAG, STT/TTS, audio en vivo
- **Multimedia**: video, audio, imagenes y assets locales
- **API**: servicios propios en `lib/services` y backend FastAPI

## Estructura

```text
lib/
  core/       Tema visual y utilidades
  data/       Datos locales de zonas de riesgo
  pages/      Pantallas de la aplicacion
  services/   API, IA, voz, autenticacion
  widgets/    Componentes reutilizables

assets/
  icons/      Avatares e iconos
  img/        Imagenes de la experiencia
  readme/     Recursos visuales del repositorio
  sounds/     Alertas
  videos/     Contenido preventivo

backend/
  app/        Servicios backend
  tests/      Pruebas
```

## Instalacion

```bash
git clone https://github.com/mrlalo7/ubicasafe-vps.git
cd ubicasafe-vps
flutter pub get
flutter run
```

Para ejecutar en navegador:

```bash
flutter run -d chrome
```

## Configuracion

La app usa OpenStreetMap para mapas, por lo que no requiere una API key de Google Maps para visualizar las rutas principales.

Para una instalacion completa revisa:

- Permisos de ubicacion e internet en `android/app/src/main/AndroidManifest.xml`.
- Configuracion de Firebase si se usara autenticacion.
- Variables, endpoints o credenciales del backend.
- Servicios de IA, voz o audio segun el entorno de despliegue.

## Comandos Utiles

```bash
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter pub outdated
flutter clean && flutter pub get
```

## Nota de Produccion

OpenStreetMap es ideal para desarrollo y prototipado. Para alto trafico o despliegues publicos, se recomienda usar un proveedor de tiles con terminos adecuados o desplegar infraestructura propia de mapas.

## Licencia

Proyecto en desarrollo. Define una licencia antes de distribuirlo o reutilizarlo publicamente.

