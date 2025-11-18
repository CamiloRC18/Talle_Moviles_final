# To-Do List App - Flutter Offline-First

Una aplicación Flutter de lista de tareas con soporte offline-first, sincronización con backend y gestión de estado con Riverpod.

## 🚀 Características

- ✅ Crear, editar, marcar como completadas y eliminar tareas
- 🔄 Sincronización automática con backend
- 📱 Soporte offline-first con SQLite
- 🔌 Cola de operaciones para sincronización diferida
- 🎯 Filtros: Todas, Pendientes, Completadas
- ⚡ Gestión de estado con Riverpod
- 🛡️ Manejo robusto de errores

## 📋 Requisitos Previos

- Flutter 3.x
- Node.js (para json-server)
- Dart SDK

## 🛠️ Instalación

### 1. Clonar el proyecto y instalar dependencias

```bash
flutter pub get
```

### 2. Generar código (para json_serializable)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurar json-server (Mock API)

Instalar json-server globalmente:

```bash
npm install -g json-server
```

Crear el archivo `db.json` en la raíz del proyecto (ya proporcionado).

Iniciar el servidor:

```bash
json-server --watch db.json --port 3000
```

El servidor estará disponible en `http://localhost:3000`

### 4. Configurar la URL del API

Si usas un dispositivo físico o necesitas cambiar la URL, edita `lib/data/remote/task_api.dart`:

```dart
static const String baseUrl = 'http://TU_IP:3000'; // Ejemplo: http://192.168.1.100:3000
```

Para Android Emulator usa: `http://10.0.2.2:3000`

Para iOS Simulator usa: `http://localhost:3000`

### 5. Ejecutar la aplicación

```bash
flutter run
```

## 📁 Estructura del Proyecto

```
lib/
├── data/
│   ├── local/
│   │   └── database_helper.dart      # SQLite helper
│   ├── remote/
│   │   └── task_api.dart             # Cliente HTTP
│   └── repositories/
│       └── task_repository.dart      # Lógica offline-first
├── models/
│   └── task.dart                     # Modelos de datos
├── providers/
│   └── task_providers.dart           # Riverpod providers
├── views/
│   └── home_view.dart                # Vista principal
├── widgets/
│   ├── task_list_item.dart          # Item de tarea
│   ├── add_task_dialog.dart         # Diálogo crear
│   └── edit_task_dialog.dart        # Diálogo editar
└── main.dart                         # Punto de entrada
```

## 🔄 Estrategia Offline-First

### Lectura de datos
1. La app muestra primero datos de SQLite (instantáneo)
2. Si hay conexión, sincroniza en segundo plano
3. Aplica Last-Write-Wins para resolver conflictos

### Escritura de datos
1. Guarda cambios en SQLite inmediatamente
2. Encola la operación en `queue_operations`
3. Intenta sincronizar con el servidor si hay conexión
4. Reintenta con backoff exponencial en caso de fallo

### Sincronización
- Automática al abrir la app
- Manual con el botón de sincronización
- Indicador visual de operaciones pendientes

## 🧪 Endpoints API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /tasks | Obtener todas las tareas |
| POST | /tasks | Crear nueva tarea |
| GET | /tasks/:id | Obtener tarea por ID |
| PUT | /tasks/:id | Actualizar tarea |
| DELETE | /tasks/:id | Eliminar tarea |

### Formato de respuesta

```json
{
  "id": "uuid",
  "title": "Título de la tarea",
  "completed": false,
  "updated_at": "2025-11-16T10:30:00Z"
}
```

## 🎨 Características de la UI

- **Material Design 3**: Interfaz moderna y limpia
- **Swipe to delete**: Desliza para eliminar tareas
- **Filtros rápidos**: Segmented buttons para cambiar vistas
- **Pull to refresh**: Desliza hacia abajo para actualizar
- **Indicador de sincronización**: Badge mostrando operaciones pendientes
- **Validación de formularios**: Retroalimentación instantánea

## ⚙️ Tecnologías Utilizadas

- **Flutter 3.x**: Framework UI
- **Riverpod**: Gestión de estado
- **SQLite (sqflite)**: Base de datos local
- **http**: Cliente HTTP
- **connectivity_plus**: Detección de conectividad
- **json_serializable**: Serialización JSON
- **uuid**: Generación de IDs únicos

## 🐛 Manejo de Errores

La aplicación maneja:
- ❌ Timeouts de red
- ❌ Errores 4xx (cliente)
- ❌ Errores 5xx (servidor)
- ❌ Sin conexión a internet
- ❌ Respuestas inválidas del servidor

Todos los errores muestran mensajes claros al usuario mediante SnackBars.

## 🔒 Consideraciones de Seguridad

- Uso de `Idempotency-Key` para evitar duplicaciones
- Validación de entrada en formularios
- Sanitización de datos antes de guardar

## 📝 Mejoras Futuras

- [ ] Autenticación de usuarios
- [ ] Categorías de tareas
- [ ] Recordatorios y notificaciones
- [ ] Búsqueda de tareas
- [ ] Modo oscuro
- [ ] Exportar/Importar tareas
- [ ] Métricas de productividad

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir los cambios que te gustaría hacer.

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.