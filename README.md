<img width="500" height="500" alt="icon" src="https://github.com/user-attachments/assets/81dd7981-8381-4ad1-b031-f1b255d3ab21" />



UBICASAFE

Construye con IA el futuro de Bolivia - Build with AI La Paz 2026

Aplicación móvil para la prevención de robos en la ciudad de El Alto y La Paz, utilizando inteligencia artificial y geolocalización en tiempo real.

UBICASAFE integra a Luzi y Wara, agentes de IA conversacionales multilingües (español, aymara, quechua). Este enfoque sigue el legado tecnológico de Juan David Ramos Cadena, quien desarrolló Lucy AI, la primera inteligencia artificial en hablar aymara, demostrando que la tecnología de vanguardia puede ser plenamente inclusiva con nuestras lenguas originarias.

Características Principales

Agentes Multilingües: Asistencia en tiempo real para reportes de seguridad rompiendo barreras de idioma.

Geolocalización Activa: Mapas interactivos para ubicar zonas seguras y de riesgo.

Autenticación Segura: Ingreso rápido para usuarios y gestión de perfiles.

Soporte Multimedia: Visualización de videos de prevención y alertas sonoras integradas.

Tecnologías y Dependencias Principales

El proyecto está desarrollado en Flutter (SDK ^3.9.0) e incluye los siguientes paquetes clave:

Mapas y Ubicación: google_maps_flutter, geolocator, permission_handler

Base de Datos y Auth: firebase_auth, google_sign_in, http

UI/UX y Multimedia: carousel_slider, video_player, chewie, google_fonts

Inteligencia Artificial: Ecosistema Google Cloud / Gemini API

Instalación y Despliegue Local

Sigue estos pasos para clonar y ejecutar el proyecto en tu máquina local.

Clonar el repositorio y obtener dependencias
Abre tu terminal y ejecuta:

git clone https://github.com/TU-USUARIO/ubicasafe.git
cd ubicasafe
flutter clean
flutter pub get

Configuración de API Keys (Importante)
Antes de ejecutar la app, debes configurar las claves de los servicios:

Google Maps: Agrega tu API Key en android/app/src/main/AndroidManifest.xml y en web/index.html.

Firebase: Asegúrate de ejecutar flutterfire configure para generar el archivo google-services.json y conectar la autenticación.

Ejecutar la Aplicación

Opción A: Emulador de Android (Recomendado para GPS y Mapas)

Abre Android Studio.

Ve a Tools > Device Manager e inicia un emulador (AVD).

En la terminal de tu proyecto, ejecuta:
flutter run

Opción B: Navegador Web (Chrome)
Para pruebas rápidas de interfaz de usuario sin encender el emulador, ejecuta:
flutter run -d chrome

CAPTURAS DEL DESPLIEGUE :
<img width="452" height="553" alt="image" src="https://github.com/user-attachments/assets/5239d0ec-1747-46f4-a895-b2fff6d5ed6f" />

<img width="475" height="583" alt="image" src="https://github.com/user-attachments/assets/6f61b71a-d849-4425-8b84-8d82019da648" />
<img width="477" height="670" alt="image" src="https://github.com/user-attachments/assets/b770f48d-6c57-4826-9b3b-b5b764f732bc" />
<img width="493" height="662" alt="image" src="https://github.com/user-attachments/assets/8d6b5098-5b99-4a49-92ca-a3029874fb12" />
<img width="481" height="600" alt="image" src="https://github.com/user-attachments/assets/16aa6f56-ca20-442b-bbb0-2f5a83d10366" />




