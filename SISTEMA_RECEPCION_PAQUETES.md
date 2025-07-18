# Sistema de Gestión de Paquetes - "PaqueteSeguro"

## Descripción General

El sistema **PaqueteSeguro** es una funcionalidad integral para la gestión de paquetes y correspondencia en condominios, permitiendo el registro, seguimiento y entrega controlada de paquetes a los residentes.

## Estructura de Almacenamiento en Firebase

### Colección Principal: `{condominioId}/paquetes`

```
{condominioId}/
├── paquetes/
│   ├── configuracion (documento)
│   └── registros/ (subcolección)
│       ├── {paqueteId} (documento)
│       └── ...
```

### Documento de Configuración: `paquetes/configuracion`

```json
{
  "activo": true,
  "requiereAutorizacion": true,
  "notificarRecepcion": true,
  "notificarEntrega": true,
  "tiempoMaximoRetencion": 30,
  "permitirFotos": true,
  "requiereFirmaDigital": false,
  "horariosRecepcion": {
    "lunes": {"inicio": "08:00", "fin": "18:00"},
    "martes": {"inicio": "08:00", "fin": "18:00"},
    "miercoles": {"inicio": "08:00", "fin": "18:00"},
    "jueves": {"inicio": "08:00", "fin": "18:00"},
    "viernes": {"inicio": "08:00", "fin": "18:00"},
    "sabado": {"inicio": "09:00", "fin": "14:00"},
    "domingo": {"inicio": "", "fin": ""}
  },
  "empresasTransporte": [
    "Correos de Chile",
    "Chilexpress",
    "Starken",
    "Blue Express",
    "DHL",
    "FedEx",
    "Otro"
  ]
}
```

### Documento de Registro de Paquete: `paquetes/registros/{paqueteId}`

```json
{
  "id": "paquete_001",
  "fechaRecepcion": "2024-01-15T10:30:00Z",
  "fechaEntrega": null,
  "estado": "pendiente",
  "destinatario": {
    "nombre": "Juan Pérez",
    "vivienda": "Casa 15",
    "uid": "user123",
    "telefono": "+56912345678"
  },
  "remitente": {
    "nombre": "Amazon",
    "empresa": "Amazon Chile",
    "telefono": "+56987654321"
  },
  "transporte": {
    "empresa": "Chilexpress",
    "numeroGuia": "CX123456789",
    "repartidor": "Carlos González"
  },
  "paquete": {
    "descripcion": "Caja mediana",
    "peso": "2.5 kg",
    "dimensiones": "30x20x15 cm",
    "fragil": false,
    "refrigerado": false,
    "valorDeclarado": 50000
  },
  "recepcion": {
    "recibidoPor": "admin123",
    "nombreRecibidor": "María Admin",
    "observaciones": "Paquete en buen estado",
    "fotoRecepcion": "url_foto_recepcion",
    "ubicacionAlmacenamiento": "Estante A-15"
  },
  "entrega": {
    "entregadoPor": null,
    "fechaEntrega": null,
    "firmaDigital": null,
    "fotoEntrega": null,
    "observacionesEntrega": null,
    "retiradoPor": null
  },
  "notificaciones": {
    "recepcionEnviada": true,
    "recordatoriosEnviados": 1,
    "ultimoRecordatorio": "2024-01-20T09:00:00Z"
  },
  "historial": [
    {
      "fecha": "2024-01-15T10:30:00Z",
      "accion": "recepcion",
      "usuario": "admin123",
      "detalles": "Paquete recibido y almacenado"
    }
  ]
}
```

## Modelo de Datos (Dart)

### PaqueteConfigModel

```dart
class PaqueteConfigModel {
  final bool activo;
  final bool requiereAutorizacion;
  final bool notificarRecepcion;
  final bool notificarEntrega;
  final int tiempoMaximoRetencion;
  final bool permitirFotos;
  final bool requiereFirmaDigital;
  final Map<String, Map<String, String>> horariosRecepcion;
  final List<String> empresasTransporte;

  PaqueteConfigModel({
    required this.activo,
    required this.requiereAutorizacion,
    required this.notificarRecepcion,
    required this.notificarEntrega,
    required this.tiempoMaximoRetencion,
    required this.permitirFotos,
    required this.requiereFirmaDigital,
    required this.horariosRecepcion,
    required this.empresasTransporte,
  });

  factory PaqueteConfigModel.fromFirestore(Map<String, dynamic> data) {
    return PaqueteConfigModel(
      activo: data['activo'] ?? false,
      requiereAutorizacion: data['requiereAutorizacion'] ?? true,
      notificarRecepcion: data['notificarRecepcion'] ?? true,
      notificarEntrega: data['notificarEntrega'] ?? true,
      tiempoMaximoRetencion: data['tiempoMaximoRetencion'] ?? 30,
      permitirFotos: data['permitirFotos'] ?? true,
      requiereFirmaDigital: data['requiereFirmaDigital'] ?? false,
      horariosRecepcion: Map<String, Map<String, String>>.from(
        data['horariosRecepcion'] ?? {}
      ),
      empresasTransporte: List<String>.from(data['empresasTransporte'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'activo': activo,
      'requiereAutorizacion': requiereAutorizacion,
      'notificarRecepcion': notificarRecepcion,
      'notificarEntrega': notificarEntrega,
      'tiempoMaximoRetencion': tiempoMaximoRetencion,
      'permitirFotos': permitirFotos,
      'requiereFirmaDigital': requiereFirmaDigital,
      'horariosRecepcion': horariosRecepcion,
      'empresasTransporte': empresasTransporte,
    };
  }
}
```

### PaqueteModel

```dart
class PaqueteModel {
  final String id;
  final String fechaRecepcion;
  final String? fechaEntrega;
  final String estado; // 'pendiente', 'entregado', 'vencido'
  final DestinatarioModel destinatario;
  final RemitenteModel remitente;
  final TransporteModel transporte;
  final DetallePaqueteModel paquete;
  final RecepcionModel recepcion;
  final EntregaModel? entrega;
  final NotificacionesModel notificaciones;
  final List<HistorialModel> historial;

  PaqueteModel({
    required this.id,
    required this.fechaRecepcion,
    this.fechaEntrega,
    required this.estado,
    required this.destinatario,
    required this.remitente,
    required this.transporte,
    required this.paquete,
    required this.recepcion,
    this.entrega,
    required this.notificaciones,
    required this.historial,
  });

  factory PaqueteModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    return PaqueteModel(
      id: documentId,
      fechaRecepcion: data['fechaRecepcion'] ?? '',
      fechaEntrega: data['fechaEntrega'],
      estado: data['estado'] ?? 'pendiente',
      destinatario: DestinatarioModel.fromMap(data['destinatario'] ?? {}),
      remitente: RemitenteModel.fromMap(data['remitente'] ?? {}),
      transporte: TransporteModel.fromMap(data['transporte'] ?? {}),
      paquete: DetallePaqueteModel.fromMap(data['paquete'] ?? {}),
      recepcion: RecepcionModel.fromMap(data['recepcion'] ?? {}),
      entrega: data['entrega'] != null ? EntregaModel.fromMap(data['entrega']) : null,
      notificaciones: NotificacionesModel.fromMap(data['notificaciones'] ?? {}),
      historial: (data['historial'] as List? ?? [])
          .map((item) => HistorialModel.fromMap(item))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fechaRecepcion': fechaRecepcion,
      'fechaEntrega': fechaEntrega,
      'estado': estado,
      'destinatario': destinatario.toMap(),
      'remitente': remitente.toMap(),
      'transporte': transporte.toMap(),
      'paquete': paquete.toMap(),
      'recepcion': recepcion.toMap(),
      'entrega': entrega?.toMap(),
      'notificaciones': notificaciones.toMap(),
      'historial': historial.map((item) => item.toMap()).toList(),
    };
  }
}
```

## Pantallas del Sistema

### Pantalla del Residente: "Mis Paquetes"

#### Funcionalidades:

1. **Vista Principal**
   - Lista de paquetes pendientes de retiro
   - Lista de paquetes entregados (historial)
   - Contador de paquetes pendientes
   - Filtros por estado y fecha

2. **Detalle de Paquete**
   - Información completa del paquete
   - Estado actual y historial de movimientos
   - Fotos del paquete (si están disponibles)
   - Información del remitente y transporte
   - Botón para programar retiro (si está habilitado)

3. **Notificaciones**
   - Notificación push al recibir un paquete
   - Recordatorios automáticos de paquetes pendientes
   - Alertas de paquetes próximos a vencer

4. **Configuración Personal**
   - Preferencias de notificaciones
   - Autorización de personas para retirar paquetes
   - Horarios preferidos para retiro

#### Elementos de UI:

- **AppBar**: "Mis Paquetes" con contador de pendientes
- **TabBar**: "Pendientes" | "Entregados"
- **Cards de Paquete**: Con estado, fecha, remitente y acciones
- **FloatingActionButton**: Escanear código QR (si aplica)
- **Bottom Sheet**: Filtros y ordenamiento

### Pantalla del Administrador: "Gestión de Paquetes"

#### Funcionalidades:

1. **Dashboard Principal**
   - Resumen de paquetes del día
   - Paquetes pendientes de entrega
   - Estadísticas mensuales
   - Alertas de paquetes vencidos

2. **Registro de Paquetes**
   - Formulario de registro manual
   - Escaneo de códigos de barras/QR
   - Captura de fotos del paquete
   - Selección de destinatario
   - Registro de datos del transporte

3. **Gestión de Entregas**
   - Lista de paquetes para entregar
   - Proceso de entrega con firma digital
   - Registro de quien retira el paquete
   - Captura de foto de entrega

4. **Configuración del Sistema**
   - Activar/desactivar funcionalidad
   - Configurar horarios de recepción
   - Gestionar empresas de transporte
   - Configurar notificaciones automáticas
   - Establecer tiempo máximo de retención

5. **Reportes y Estadísticas**
   - Reporte de paquetes por período
   - Estadísticas de empresas de transporte
   - Tiempo promedio de retiro
   - Paquetes no retirados

#### Elementos de UI:

- **AppBar**: "Gestión de Paquetes" con acciones rápidas
- **Dashboard Cards**: Estadísticas principales
- **FAB**: Registrar nuevo paquete
- **Bottom Navigation**: Dashboard | Paquetes | Entregas | Configuración
- **Search Bar**: Búsqueda por destinatario, número de guía, etc.

## Estados del Paquete

1. **pendiente**: Paquete recibido, esperando retiro
2. **entregado**: Paquete entregado al destinatario
3. **vencido**: Paquete no retirado en el tiempo establecido
4. **devuelto**: Paquete devuelto al remitente
5. **extraviado**: Paquete reportado como extraviado

## Notificaciones Automáticas

### Para Residentes:
- Notificación inmediata al recibir un paquete
- Recordatorio a los 3 días de no retiro
- Recordatorio a los 7 días de no retiro
- Alerta a los 25 días (próximo a vencer)
- Notificación de vencimiento

### Para Administradores:
- Resumen diario de paquetes recibidos
- Alerta de paquetes próximos a vencer
- Notificación de paquetes vencidos
- Reporte semanal de estadísticas

## Integración con Otros Módulos

### Con Sistema de Notificaciones:
- Envío automático de notificaciones push
- Registro en el historial de notificaciones
- Configuración de preferencias por usuario

### Con Sistema de Usuarios:
- Validación de residentes activos
- Verificación de viviendas asignadas
- Control de permisos de retiro

### Con Sistema de Multas (opcional):
- Generación automática de multas por no retiro
- Configuración de montos por días de retraso

## Consideraciones de Seguridad

1. **Validación de Identidad**: Verificar que quien retira sea el destinatario o persona autorizada
2. **Registro de Actividades**: Log completo de todas las acciones realizadas
3. **Backup de Fotos**: Almacenamiento seguro de evidencias fotográficas
4. **Encriptación de Datos**: Protección de información sensible
5. **Control de Acceso**: Permisos diferenciados por tipo de usuario

## Implementación Técnica

### Servicios Requeridos:
- `PaqueteService`: Gestión CRUD de paquetes
- `NotificacionPaqueteService`: Manejo de notificaciones específicas
- `ReportePaqueteService`: Generación de reportes y estadísticas

### Widgets Personalizados:
- `PaqueteCard`: Card para mostrar información del paquete
- `EstadoPaqueteChip`: Chip con el estado actual
- `FirmaDigitalWidget`: Widget para captura de firma
- `FotoPaqueteWidget`: Widget para captura y visualización de fotos

### Dependencias Adicionales:
- `image_picker`: Para captura de fotos
- `signature`: Para firma digital
- `qr_code_scanner`: Para escaneo de códigos QR
- `pdf`: Para generación de reportes

Este sistema proporciona una solución completa para la gestión de paquetes en condominios, mejorando la seguridad, trazabilidad y experiencia tanto para residentes como administradores.