# Guía móvil de seguimiento

## Resumen rápido

- La app móvil puede instalarse por `USB`, pero luego puede usar el backend por `Wi‑Fi` sin cable.
- El `USB` solo se necesita para instalar o actualizar el APK desde la PC.
- Para que funcione sin USB, el celular y la PC que ejecuta el backend deben estar en la misma red.
- Si cambias de PC, no hace falta recompilar: ahora la app permite cambiar la IP del backend desde `Perfil > Conexión > Cambiar IP del backend`.

## 1. Dependencias del proyecto

```bash
flutter pub get
```

## 2. Ejecutar con la API del backend web

### Android Emulator

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5001/api
```

### Celular físico en la misma red

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:5001/api
```

Ejemplo:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.18.117:5001/api
```

## 3. Activar Pusher

Reemplaza las variables por las de tu backend:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:5001/api --dart-define=PUSHER_KEY=tu_key --dart-define=PUSHER_CLUSTER=tu_cluster --dart-define=PUSHER_CHANNEL_PREFIX=private-pedido. --dart-define=PUSHER_EVENT_NAME=pedido.estado.actualizado
```

Para pruebas rápidas desde la consola de Pusher sin autenticación de canales privados, puedes usar canal público:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:5001/api --dart-define=PUSHER_KEY=tu_key --dart-define=PUSHER_CLUSTER=tu_cluster --dart-define=PUSHER_CHANNEL_PREFIX=pedido. --dart-define=PUSHER_EVENT_NAME=pedido.estado.actualizado
```

## 4. Endpoints que consume

- POST `/api/auth/login`
- POST `/api/auth/register`
- GET `/api/usuarios/perfil`
- PUT `/api/usuarios/perfil`
- GET `/api/pedidos/mis-pedidos`
- GET `/api/pedidos/:id`
- GET `/api/productos`
- GET `/api/notificaciones/pendientes`

## 5. Qué se corrigió

- estructura con modelos y services;
- sesión persistida con `SharedPreferences`;
- seguimiento de pedido desacoplado del resto de pantallas;
- soporte de tiempo real con `pusher_channels_flutter`;
- base URL configurable para emulador, web o celular real;
- edición de perfil sincronizada con la misma base de datos del sistema web;
- opción dentro de la app para cambiar la IP o URL del backend sin recompilar.

## 6. Instalar el APK por USB

### Requisitos

- Android Studio o Android SDK instalado en la PC
- `adb` disponible
- celular con `Depuración USB` activada
- cable USB con soporte de datos

### Generar APK

```bash
flutter build apk --debug
```

El archivo queda en:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

### Instalar por USB

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 7. Usar la app sin USB

Sí funciona sin USB.

Condiciones:

- el backend debe estar encendido en la PC;
- el celular y la PC deben estar en la misma red;
- la app debe apuntar a la IP correcta de esa PC.

El cable USB no es necesario para usar la API. Solo fue necesario para instalar o actualizar la app.

## 8. Abrir la app en otra PC sin USB

Si el backend corre en otra PC, la app también puede funcionar, pero debes cambiar la IP del backend dentro del celular.

### Pasos

1. En la otra PC, enciende el backend normalmente.
2. Averigua la IP local de esa PC.
3. En el celular, abre la app.
4. Entra a `Perfil`.
5. Baja a la sección `Conexión`.
6. Toca `Cambiar IP del backend`.
7. Escribe la IP con puerto.

Ejemplos válidos:

- `192.168.1.50:5001`
- `http://192.168.1.50:5001`
- `http://192.168.1.50:5001/api`

La app agrega `/api` automáticamente si no lo escribes.

8. Guarda.
9. Vuelve a probar login, perfil, productos o pedidos.

## 9. Cómo volver al backend por defecto

Dentro del celular:

1. Abre `Perfil`
2. Ve a `Conexión`
3. Toca `Cambiar IP del backend`
4. Pulsa `Usar predeterminado`

## 10. Cómo verificar que la otra PC funciona

Antes de probar en el celular, en la otra PC verifica que el backend esté respondiendo:

```bash
http://TU_IP_LOCAL:5001/api/categorias
```

Si abre o responde correctamente, entonces la app debería poder conectarse.

## 11. Si te da error de tiempo de espera

Si aparece `La API tardó demasiado en responder`, revisa esto:

- el backend está apagado;
- la IP configurada en la app no coincide con la PC actual;
- el celular y la PC no están en la misma red;
- el firewall de Windows está bloqueando el puerto `5001`;
- la PC cambió de IP y la app sigue usando la anterior.

## 12. Resumen corto para uso diario

### Si usarás siempre la misma PC

- enciende el backend;
- abre la app;
- usa la IP ya configurada.

### Si cambias de PC

- enciende el backend en la nueva PC;
- mira la IP de esa PC;
- en el celular cambia la IP en `Perfil > Conexión`;
- guarda y prueba.

### Si quieres reinstalar la app

- conecta por USB;
- compila el APK;
- instala con `adb install -r`.

## 13. Comandos recomendados

```bash
flutter clean
flutter pub get
flutter build apk --debug
```

Para ejecutar directo desde Flutter:

```bash
flutter run --dart-define=API_BASE_URL=http://TU_IP_LOCAL:5001/api
```
