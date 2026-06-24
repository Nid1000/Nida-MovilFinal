# Backend hosting: Google + Resend para web y movil

Aplica esto en `api.saborcentral.com`, no en la app Flutter. El error `Server Error`
al enviar codigo ocurre porque `routes/api.php` apunta a metodos que el
`AuthController` del hosting no tiene implementados.

## 1. Rutas requeridas

En `routes/api.php` deben existir estas rutas:

```php
Route::post('/auth/register/email/send-code', [AuthController::class, 'sendRegistrationCode'])->middleware('throttle:5,1');
Route::post('/auth/register/email/verify-code', [AuthController::class, 'verifyRegistrationCode'])->middleware('throttle:10,1');
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/google', [AuthController::class, 'googleLogin']);
Route::post('/auth/password/forgot', [AuthController::class, 'forgotPassword'])->middleware('throttle:5,1');
```

## 2. Imports que faltan en `AuthController.php`

Arriba, junto a los otros `use`, agrega:

```php
use Illuminate\Support\Facades\Cache;
```

## 3. Metodos para pegar dentro de `AuthController`

Pega estos metodos dentro de la clase `AuthController`, por ejemplo antes de
`forgotPassword`.

```php
public function sendRegistrationCode(Request $request)
{
    try {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:191'],
        ]);
    } catch (ValidationException $e) {
        return response()->json([
            'statusCode' => 400,
            'error' => 'Datos invalidos',
            'message' => 'Ingresa un correo valido',
            'details' => $e->errors(),
        ], 400);
    }

    $email = mb_strtolower(trim((string) $data['email']));
    $existing = DB::table('usuarios')->whereRaw('LOWER(email) = ?', [$email])->first();
    if ($existing) {
        return response()->json([
            'statusCode' => 400,
            'error' => 'Email ya registrado',
            'message' => 'Ya existe una cuenta con este correo. Inicia sesion.',
        ], 400);
    }

    $apiKey = trim((string) config('services.resend.key'));
    $fromAddress = trim((string) config('mail.from.address'));
    $fromName = trim((string) config('mail.from.name', 'Delicias'));

    if ($apiKey === '' || $fromAddress === '' || str_contains($fromAddress, 'example.com')) {
        return response()->json([
            'statusCode' => 503,
            'error' => 'Correo no configurado',
            'message' => 'Resend no esta configurado en el servidor.',
        ], 503);
    }

    $code = (string) random_int(100000, 999999);
    $ttlMinutes = 15;
    $cacheKey = 'mobile_registration_code:' . hash('sha256', $email);

    Cache::put($cacheKey, [
        'email' => $email,
        'code_hash' => hash('sha256', $code),
        'attempts' => 0,
    ], now()->addMinutes($ttlMinutes));

    $safeCode = htmlspecialchars($code, ENT_QUOTES, 'UTF-8');
    $html = <<<HTML
        <div style="font-family:Arial,sans-serif;color:#292524;line-height:1.6">
            <h2>Verifica tu correo</h2>
            <p>Usa este codigo para crear tu cuenta en Delicias:</p>
            <p style="font-size:28px;font-weight:800;letter-spacing:6px">{$safeCode}</p>
            <p>Este codigo vence en {$ttlMinutes} minutos.</p>
        </div>
        HTML;

    try {
        $response = Http::withToken($apiKey)
            ->acceptJson()
            ->timeout(20)
            ->post('https://api.resend.com/emails', [
                'from' => $fromName . ' <' . $fromAddress . '>',
                'to' => [$email],
                'subject' => 'Codigo de verificacion Delicias',
                'html' => $html,
            ]);

        if (!$response->successful()) {
            Log::error('Resend rejected registration code email.', [
                'status' => $response->status(),
                'response' => $response->json(),
            ]);

            return response()->json([
                'statusCode' => 503,
                'error' => 'Correo no enviado',
                'message' => 'No se pudo enviar el codigo de verificacion.',
            ], 503);
        }
    } catch (\Throwable $exception) {
        Log::error('Could not send registration code email.', [
            'email' => $email,
            'error' => $exception->getMessage(),
        ]);

        return response()->json([
            'statusCode' => 503,
            'error' => 'Correo no enviado',
            'message' => 'No se pudo enviar el codigo de verificacion.',
        ], 503);
    }

    return response()->json([
        'statusCode' => 200,
        'message' => 'Te enviamos un codigo de verificacion a tu correo.',
    ]);
}

public function verifyRegistrationCode(Request $request)
{
    try {
        $data = $request->validate([
            'email' => ['required', 'email', 'max:191'],
            'verification_code' => ['required_without:code', 'digits:6'],
            'code' => ['required_without:verification_code', 'digits:6'],
        ]);
    } catch (ValidationException $e) {
        return response()->json([
            'statusCode' => 400,
            'error' => 'Datos invalidos',
            'message' => 'Ingresa el codigo de 6 digitos',
            'details' => $e->errors(),
        ], 400);
    }

    $email = mb_strtolower(trim((string) $data['email']));
    $code = (string) ($data['verification_code'] ?? $data['code'] ?? '');
    $cacheKey = 'mobile_registration_code:' . hash('sha256', $email);
    $verification = Cache::get($cacheKey);

    if (!is_array($verification)) {
        return response()->json([
            'statusCode' => 422,
            'error' => 'Codigo vencido',
            'message' => 'El codigo vencio. Solicita uno nuevo.',
        ], 422);
    }

    $attempts = (int) ($verification['attempts'] ?? 0);
    if ($attempts >= 5) {
        Cache::forget($cacheKey);
        return response()->json([
            'statusCode' => 429,
            'error' => 'Muchos intentos',
            'message' => 'Solicita un nuevo codigo.',
        ], 429);
    }

    if (!hash_equals((string) ($verification['code_hash'] ?? ''), hash('sha256', $code))) {
        $verification['attempts'] = $attempts + 1;
        Cache::put($cacheKey, $verification, now()->addMinutes(15));

        return response()->json([
            'statusCode' => 422,
            'error' => 'Codigo incorrecto',
            'message' => 'El codigo ingresado no es correcto.',
        ], 422);
    }

    Cache::forget($cacheKey);

    $token = app(JwtService::class)->sign([
        'purpose' => 'registration_email_verification',
        'email' => $email,
    ], 15 * 60);

    return response()->json([
        'statusCode' => 200,
        'message' => 'Correo verificado correctamente.',
        'verification_token' => $token,
    ]);
}
```

## 4. Validar token en `register`

Dentro de `register(Request $request)`, agrega `email_verification_token` a la
validacion:

```php
'email_verification_token' => ['nullable', 'string', 'max:4096'],
```

Luego, despues de validar `$data` y antes de crear el usuario, agrega:

```php
$verificationToken = (string) ($data['email_verification_token'] ?? '');
if ($verificationToken !== '' && $verificationToken !== 'google') {
    try {
        $payload = app(JwtService::class)->verify($verificationToken);
    } catch (\Throwable) {
        return response()->json([
            'statusCode' => 422,
            'error' => 'Correo no verificado',
            'message' => 'Verifica tu correo antes de crear la cuenta.',
        ], 422);
    }

    $verifiedEmail = mb_strtolower(trim((string) ($payload['email'] ?? '')));
    if (($payload['purpose'] ?? null) !== 'registration_email_verification'
        || !hash_equals($verifiedEmail, mb_strtolower(trim((string) $data['email'])))) {
        return response()->json([
            'statusCode' => 422,
            'error' => 'Correo no verificado',
            'message' => 'El codigo no corresponde a este correo.',
        ], 422);
    }
}
```

## 5. Variables `.env` requeridas

```env
GOOGLE_CLIENT_ID=TU_CLIENT_ID_WEB_DE_GOOGLE
MAIL_MAILER=resend
RESEND_API_KEY=re_xxxxxxxxx
MAIL_FROM_ADDRESS=no-reply@delicias.saborcentral.com
MAIL_FROM_NAME="Delicias"
FRONTEND_URL=https://delicias.saborcentral.com
```

Con tu `.env` actual, cambia minimo esto:

```env
MAIL_MAILER=resend
MAIL_FROM_ADDRESS=no-reply@saborcentral.com
RESEND_API_KEY=tu_clave_resend
GOOGLE_CLIENT_ID=766716089536-agkfc5doku43tcf8m9d13hrai813cgv0.apps.googleusercontent.com
FRONTEND_URL=https://delicias.saborcentral.com
```

`GOOGLE_CLIENT_SECRET` no es necesario para `/api/auth/google`, porque la API
valida el `id_token` con `tokeninfo`. Solo lo necesita la web si usa el flujo
OAuth con redirect/callback.

Para el cliente Android de Google Cloud:

```text
Package name: com.saborcentral.delicias
SHA-1: el SHA-1 del keystore con el que compilas el APK
```

Despues de editar en hosting:

```bash
php artisan config:clear
php artisan route:clear
php artisan cache:clear
```
