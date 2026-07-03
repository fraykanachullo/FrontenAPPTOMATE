# 🍅 Tomate Detection App - Frontend

![Flutter](https://img.shields.io/badge/Flutter-3.35.7-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)
![License](https://img.shields.io/badge/License-UPEU-green.svg)

Aplicación móvil para la detección de enfermedades y plagas en cultivos de tomate, desarrollada como tesis para la **Universidad Peruana Unión (UPEU)**.

---

## 📱 **Descripción**

Esta aplicación permite a los agricultores y técnicos de campo diagnosticar enfermedades en plantas de tomate utilizando inteligencia artificial. El sistema funciona tanto en modo **online** (con conexión al backend) como **offline** (con modelo local TFLite).

### 🎯 **Características Principales**

- ✅ **Detección de enfermedades** con IA (YOLOv8)
- ✅ **Cámara integrada** para capturar imágenes
- ✅ **Galería** para seleccionar imágenes existentes
- ✅ **Historial** de diagnósticos guardados localmente
- ✅ **Estadísticas y análisis** de incidencia
- ✅ **Perfil de usuario** con registro y login
- ✅ **Modo offline** (próximamente)
- ✅ **Geolocalización** de diagnósticos (próximamente)

---

## 🏗️ **Arquitectura del Proyecto**
lib/
├── core/ # Capa COMPARTIDA
│ ├── constants/ # Constantes globales
│ │ ├── api_config.dart # ✅ Configuración de IP del backend
│ │ └── app_constants.dart # Colores, temas, etc.
│ ├── services/ # Servicios principales
│ │ ├── api_service.dart # Conexión con backend
│ │ ├── database_service.dart # SQLite local
│ │ └── tflite_service.dart # Inferencia local (TFLite)
│ └── theme/ # Temas y estilos
│ └── app_theme.dart
│
├── features/ # Características por MÓDULO
│ ├── authentication/ # Login, registro, perfil
│ ├── diagnosis/ # Cámara + detección
│ ├── history/ # Historial de diagnósticos
│ └── plots/ # Análisis y estadísticas
│
├── models/ # Modelos de datos
└── injection/ # Inyección de dependencias



---

## 🔧 **Requisitos Previos**

| Software | Versión |
|----------|---------|
| **Flutter** | 3.35.7 o superior |
| **Dart** | 3.9.2 o superior |
| **Android Studio** | 2024.1 o superior |
| **Java** | 17 o superior |
| **Python** | 3.11 o superior (para backend) |

---

## 📦 **Instalación y Configuración**

### **1. Clonar el repositorio**

```bash
git clone https://github.com/fraykanachullo/FrontenAPPTOMATE.git
cd FrontenAPPTOMATE


Instalar dependencias


flutter clean
flutter pub get



3. Configurar la IP del Backend
Edita el archivo lib/core/constants/api_config.dart:

dart
class ApiConfig {
  // ⚠️ CAMBIA ESTA IP SEGÚN TU RED
  static const String baseUrl = 'http://192.168.1.39:8000';
  
  static const String detectEndpoint = '$baseUrl/detect';
  static const String healthEndpoint = '$baseUrl/health';
}
Para obtener tu IP local:

bash
# En Windows
ipconfig

# En macOS/Linux
ifconfig
4. Ejecutar la aplicación
bash
# En dispositivo físico (USB)
flutter run

# En emulador
flutter run -d emulator-5554

# En Chrome (web)
flutter run -d chrome
📁 Estructura de Carpetas
text
assets/
├── images/                        # Imágenes de la app
└── models/                        # Modelos TFLite
    ├── best_int8.tflite          # Modelo entrenado
    └── labels.txt                # Etiquetas de clases

android/                           # Configuración Android
ios/                               # Configuración iOS
lib/                               # Código fuente
test/                              # Pruebas unitarias
pubspec.yaml                       # Dependencias del proyecto

🚀 Comandos Útiles
Comando	Descripción
flutter run	Ejecutar la app
flutter clean	Limpiar cachés
flutter pub get	Instalar dependencias
flutter build apk	Generar APK de release
flutter analyze	Analizar código
r (durante ejecución)	Hot Reload
R (durante ejecución)	Hot Restart
q (durante ejecución)	Salir



🔗 Conexión con el Backend
La aplicación se conecta a un backend FastAPI para la inferencia de enfermedades.

Repositorio del Backend: BackendAPPTOMATE

Documentación de la API: Ver documentación

Endpoints principales
Método	Endpoint	Descripción
POST	/detect	Enviar imagen para diagnóstico
GET	/health	Verificar estado del servidor
GET	/classes	Obtener clases del modelo
📊 Clases Detectables
Clase	Nombre Científico	Tipo
mildiu	Phytophthora infestans	Enfermedad
mosca_blanca	Bemisia tabaci	Plaga
oidio	Leveillula taurica	Enfermedad
polilla	Tuta absoluta	Plaga
sana	-	Saludable





🛠️ Tecnologías Utilizadas
Tecnología	Uso
Flutter	Framework de UI
Dart	Lenguaje de programación
SQLite	Base de datos local
TFLite	Inferencia en dispositivo
FastAPI	Backend (Python)
YOLOv8	Modelo de detección
Google Fonts	Tipografía personalizada