# Delicias API

API Laravel usada exclusivamente por la aplicación móvil Flutter ubicada en la
raíz del repositorio.

## Endpoint Google

```text
POST /api/auth/google
```

Body:

```json
{
  "id_token": "token-emitido-por-google"
}
```

El endpoint valida el token con Google, comprueba el `GOOGLE_CLIENT_ID` y solo
inicia sesión si el correo verificado pertenece a un usuario activo existente.

El backend se despliega en `api.saborcentral.com`.
