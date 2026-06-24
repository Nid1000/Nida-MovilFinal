from __future__ import annotations

import os
import re
from contextlib import contextmanager
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any, Iterator

import pymysql
from dotenv import load_dotenv
from fastmcp import FastMCP
from pymysql.cursors import DictCursor

ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")

mcp = FastMCP("Delicias Database")

READ_ONLY_SQL = re.compile(r"^\s*(select|show|describe|desc|explain)\b", re.IGNORECASE)
TABLE_NAME = re.compile(r"^[A-Za-z0-9_]+$")


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _db_config() -> dict[str, Any]:
    return {
        "host": os.getenv("DELICIAS_DB_HOST", "localhost"),
        "port": _env_int("DELICIAS_DB_PORT", 3306),
        "user": os.getenv("DELICIAS_DB_USER", ""),
        "password": os.getenv("DELICIAS_DB_PASSWORD", ""),
        "database": os.getenv("DELICIAS_DB_NAME", "bcdroovr_deliciasbd"),
        "charset": "utf8mb4",
        "cursorclass": DictCursor,
        "connect_timeout": 10,
        "read_timeout": 20,
        "write_timeout": 20,
        "autocommit": True,
    }


def _max_rows() -> int:
    return max(1, min(_env_int("DELICIAS_DB_MAX_ROWS", 50), 200))


def _allowed_tables() -> set[str]:
    raw = os.getenv("DELICIAS_DB_ALLOWED_TABLES", "")
    return {item.strip() for item in raw.split(",") if item.strip()}


def _validate_table_name(table: str) -> str:
    table = table.strip()
    if not TABLE_NAME.match(table):
        raise ValueError("Invalid table name. Use only letters, numbers and underscores.")

    allowed = _allowed_tables()
    if allowed and table not in allowed:
        raise ValueError(f"Table '{table}' is not allowed for this MCP server.")
    return table


def _json_safe(value: Any) -> Any:
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _rows_safe(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [{key: _json_safe(value) for key, value in row.items()} for row in rows]


@contextmanager
def _connection() -> Iterator[pymysql.connections.Connection]:
    config = _db_config()
    if not config["user"]:
        raise RuntimeError("Missing DELICIAS_DB_USER. Create mcp_server/.env first.")
    if not config["password"]:
        raise RuntimeError("Missing DELICIAS_DB_PASSWORD. Create mcp_server/.env first.")

    connection = pymysql.connect(**config)
    try:
        yield connection
    finally:
        connection.close()


def _query(sql: str, params: tuple[Any, ...] = ()) -> list[dict[str, Any]]:
    with _connection() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql, params)
            rows = cursor.fetchall()
            return _rows_safe(list(rows))


@mcp.tool
def database_health() -> dict[str, Any]:
    """Check the MySQL connection and return the active database."""
    rows = _query("SELECT DATABASE() AS database_name, VERSION() AS mysql_version")
    return {
        "ok": True,
        "database": rows[0]["database_name"] if rows else None,
        "mysql_version": rows[0]["mysql_version"] if rows else None,
    }


@mcp.tool
def list_tables() -> list[str]:
    """List available tables in the Delicias database."""
    rows = _query("SHOW TABLES")
    allowed = _allowed_tables()
    tables = [next(iter(row.values())) for row in rows]
    if allowed:
        tables = [table for table in tables if table in allowed]
    return sorted(tables)


@mcp.tool
def describe_table(table: str) -> list[dict[str, Any]]:
    """Describe columns for a table."""
    table = _validate_table_name(table)
    return _query(f"DESCRIBE `{table}`")


@mcp.tool
def sample_rows(table: str, limit: int = 10) -> list[dict[str, Any]]:
    """Return sample rows from a table, read-only and limited."""
    table = _validate_table_name(table)
    limit = max(1, min(limit, _max_rows()))
    return _query(f"SELECT * FROM `{table}` LIMIT %s", (limit,))


@mcp.tool
def run_readonly_query(sql: str, limit: int = 50) -> list[dict[str, Any]]:
    """Run a read-only SQL query. Only SELECT, SHOW, DESCRIBE, DESC or EXPLAIN are allowed."""
    statement = sql.strip()
    if not READ_ONLY_SQL.match(statement):
        raise ValueError("Only read-only SQL is allowed: SELECT, SHOW, DESCRIBE, DESC or EXPLAIN.")
    if ";" in statement.rstrip(";"):
        raise ValueError("Multiple SQL statements are not allowed.")

    limit = max(1, min(limit, _max_rows()))
    if statement.lower().startswith("select") and " limit " not in statement.lower():
        statement = f"{statement.rstrip(';')} LIMIT {limit}"

    return _query(statement)


@mcp.tool
def find_products(text: str = "", limit: int = 10) -> list[dict[str, Any]]:
    """Search products by common product columns if a productos table exists."""
    limit = max(1, min(limit, _max_rows()))
    tables = set(list_tables())
    if "productos" not in tables:
        return []

    columns = describe_table("productos")
    column_names = {str(row.get("Field", "")) for row in columns}
    searchable = [name for name in ("nombre", "name", "descripcion", "description", "categoria") if name in column_names]

    if not text.strip() or not searchable:
        return sample_rows("productos", limit)

    where = " OR ".join(f"`{column}` LIKE %s" for column in searchable)
    params = tuple(f"%{text.strip()}%" for _ in searchable) + (limit,)
    return _query(f"SELECT * FROM `productos` WHERE {where} LIMIT %s", params)


if __name__ == "__main__":
    mcp.run()