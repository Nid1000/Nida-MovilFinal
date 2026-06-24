# Delicias FastMCP Server

Servidor MCP en Python para dar acceso de solo lectura a la base MySQL `bcdroovr_deliciasbd`.

## Que expone

- `database_health`: prueba conexion y version de MySQL.
- `list_tables`: lista tablas disponibles.
- `describe_table`: muestra columnas de una tabla.
- `sample_rows`: devuelve filas de ejemplo con limite.
- `run_readonly_query`: ejecuta solo `SELECT`, `SHOW`, `DESCRIBE`, `DESC` o `EXPLAIN`.
- `find_products`: busca productos si existe la tabla `productos`.

## Configuracion

1. Crea entorno Python:

```powershell
cd mcp_server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .
```

2. Copia variables:

```powershell
Copy-Item .env.example .env
```

3. Edita `.env`:

```env
DELICIAS_DB_HOST=tu_host_mysql
DELICIAS_DB_PORT=3306
DELICIAS_DB_NAME=bcdroovr_deliciasbd
DELICIAS_DB_USER=tu_usuario
DELICIAS_DB_PASSWORD=tu_password
DELICIAS_DB_MAX_ROWS=50
```

Opcionalmente limita tablas:

```env
DELICIAS_DB_ALLOWED_TABLES=productos,categorias,pedidos
```

## Ejecutar

```powershell
python server.py
```

## Configurar en un cliente MCP

Ejemplo generico:

```json
{
  "mcpServers": {
    "delicias-db": {
      "command": "D:/APP DORADO 2.0/APPNI-main/mcp_server/.venv/Scripts/python.exe",
      "args": ["D:/APP DORADO 2.0/APPNI-main/mcp_server/server.py"]
    }
  }
}
```

## Seguridad

Este servidor no guarda credenciales reales en Git. Usa `.env`, que debe quedarse local. Las herramientas estan pensadas como solo lectura y bloquean sentencias SQL de escritura.