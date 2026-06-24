# Despliegue del chatbot en api.saborcentral.com

Produccion todavia puede responder con `source: ollama` para preguntas criticas
si estos cambios no se suben al backend real.

## Archivos que deben subirse

Copia estos archivos del repo local al hosting, respetando las mismas rutas:

```text
backend/app/Http/Controllers/ChatbotController.php
backend/app/Services/OllamaService.php
backend/config/services.php
```

En el servidor normalmente las rutas equivalentes seran:

```text
app/Http/Controllers/ChatbotController.php
app/Services/OllamaService.php
config/services.php
```

## Variable opcional

En el `.env` del hosting puedes agregar:

```env
OLLAMA_TEMPERATURE=0.2
```

Si no la agregas, el codigo usa `0.2` por defecto.

## Limpiar cache Laravel

Despues de subir los archivos, ejecuta en el backend:

```bash
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```

Si el hosting usa cache de OPcache/PHP-FPM, reinicia PHP desde cPanel o espera a
que el cache expire.

## Verificacion

Prueba:

```bash
curl -X POST https://api.saborcentral.com/api/chatbot/ask \
  -H "Content-Type: application/json" \
  -d "{\"message\":\"Cual es el horario?\",\"history\":[]}"
```

La respuesta correcta debe incluir:

```json
{
  "source": "faq"
}
```

Tambien prueba preguntas de Yape, ubicacion, telefono, delivery, boleta y
factura. Todas esas deben salir por `faq`, no por `ollama`.

## Datos en vivo

El chatbot ahora tambien puede responder desde la base de datos:

- Productos, precios, stock, categorias y promociones activas: datos publicos.
- Pedidos del cliente: solo si la app envia el token `Authorization: Bearer`.

Si el usuario no inicio sesion y pregunta por sus pedidos, el chatbot debe pedir
que inicie sesion en la app. No debe inventar estados ni pedidos.
