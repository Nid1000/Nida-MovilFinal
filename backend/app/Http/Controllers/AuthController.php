<?php

namespace App\Http\Controllers;

use App\Services\JwtService;
use App\Services\CustomerLifecycleEmailService;
use App\Support\PasswordRules;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    private $customerLifecycleEmails;

    public function __construct(CustomerLifecycleEmailService $customerLifecycleEmails)
    {
        $this->customerLifecycleEmails = $customerLifecycleEmails;
    }

    private function passwordLooksHashed(string $hash): bool
    {
        $h = trim($hash);
        return str_starts_with($h, '$2y$') || str_starts_with($h, '$2a$') || str_starts_with($h, '$2b$');
    }

    private function verifyPassword(string $plain, string $stored): bool
    {
        $stored = (string) $stored;
        if ($stored === '') {
            return false;
        }

        // Primero intenta con el hasher de Laravel (si el hash es compatible).
        try {
            return Hash::check($plain, $stored);
        } catch (\Throwable $exception) {
            // Compatibilidad: evita 500 si el hash no coincide con el algoritmo esperado.
        }

        // Fallback: verifica hashes bcrypt legacy ($2a$, $2b$) con password_verify.
        if ($this->passwordLooksHashed($stored)) {
            return password_verify($plain, $stored);
        }

        // Último recurso (migración): si en la BD quedó texto plano, permite el acceso y luego se debería volver a generar el hash.
        return hash_equals($stored, $plain);
    }

    public function register(Request $request)
    {
        try {
            $data = $request->validate([
                'nombre' => ['required', 'string', 'min:2', 'max:191'],
                'apellido' => ['required', 'string', 'min:2', 'max:191'],
                'email' => ['required', 'email', 'max:191'],
                'password' => [
                    'required',
                    'string',
                    PasswordRules::userPassword(),
                ],
                'telefono' => ['required', 'string', 'regex:/^9\d{8}$/'],
                'direccion' => ['required', 'string', 'min:5', 'max:255'],
                'distrito' => ['required', 'string', 'min:2', 'max:120'],
                'numero_casa' => ['required', 'string', 'max:20'],
                'registration_channel' => ['required', 'string', 'in:mobile'],
                'email_verification_token' => ['required', 'string', 'max:4096'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Datos inválidos',
                'message' => 'Validación fallida',
                'details' => $e->errors(),
            ], 400);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        $data['email'] = $email;

        try {
            $verification = app(JwtService::class)->verify(
                (string) $data['email_verification_token']
            );
        } catch (\Throwable $exception) {
            return response()->json([
                'statusCode' => 422,
                'error' => 'Correo no verificado',
                'message' => 'Verifica tu correo antes de crear la cuenta',
            ], 422);
        }

        if (
            ($verification['purpose'] ?? null) !== 'registration_email_verified'
            || mb_strtolower((string) ($verification['email'] ?? '')) !== mb_strtolower($data['email'])
        ) {
            return response()->json([
                'statusCode' => 422,
                'error' => 'Correo no verificado',
                'message' => 'La verificación no corresponde al correo ingresado',
            ], 422);
        }

        $existing = DB::table('usuarios')->whereRaw('LOWER(email) = ?', [$email])->first();
        if ($existing) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Correo ya registrado',
                'message' => 'Ya existe una cuenta con este correo',
            ], 400);
        }

        $id = DB::table('usuarios')->insertGetId([
            'nombre' => $data['nombre'],
            'apellido' => $data['apellido'],
            'email' => $email,
            'password' => Hash::make($data['password']),
            'telefono' => $data['telefono'] ?? null,
            'direccion' => $data['direccion'] ?? null,
            'distrito' => $data['distrito'] ?? null,
            'numero_casa' => $data['numero_casa'] ?? null,
            'activo' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $user = DB::table('usuarios')->select([
            'id', 'nombre', 'apellido', 'email', 'telefono', 'direccion', 'distrito', 'numero_casa',
        ])->where('id', $id)->first();

        $token = app(JwtService::class)->sign([
            'id' => $id,
            'email' => $email,
            'tipo' => 'usuario',
        ]);

        try {
            $this->customerLifecycleEmails->sendWelcome($user);
        } catch (\Throwable $exception) {
            Log::warning('Welcome email could not be started.', [
                'user_id' => $id,
                'error' => $exception->getMessage(),
            ]);
        }

        return response()->json([
            'statusCode' => 201,
            'message' => 'Usuario registrado exitosamente',
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    public function sendRegistrationCode(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 422,
                'message' => 'Ingresa un correo válido',
                'details' => $e->errors(),
            ], 422);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        if (DB::table('usuarios')->whereRaw('LOWER(email) = ?', [$email])->exists()) {
            return response()->json([
                'statusCode' => 409,
                'message' => 'Ya existe una cuenta con este correo',
            ], 409);
        }

        $code = (string) random_int(100000, 999999);
        $challenge = app(JwtService::class)->sign([
            'purpose' => 'registration_email_code',
            'email' => $email,
            'code_hash' => hash('sha256', $code),
        ], 15 * 60);

        $apiKey = trim((string) config('services.resend.key'));
        $fromAddress = trim((string) config('mail.from.address'));
        $fromName = trim((string) config('mail.from.name', 'Delicias'));
        if ($apiKey === '' || $fromAddress === '') {
            return response()->json([
                'statusCode' => 503,
                'message' => 'El servicio de correo no está configurado',
            ], 503);
        }

        try {
            $response = Http::withToken($apiKey)
                ->acceptJson()
                ->timeout(15)
                ->post('https://api.resend.com/emails', [
                    'from' => $fromName . ' <' . $fromAddress . '>',
                    'to' => [$email],
                    'subject' => 'Código de verificación - Delicias',
                    'html' => '<h2>Tu código es ' . $code . '</h2><p>Vence en 15 minutos.</p>',
                ]);
            if (!$response->successful()) {
                throw new \RuntimeException('Resend rechazó el correo');
            }
        } catch (\Throwable $exception) {
            Log::error('No se pudo enviar el código de registro.', [
                'email' => $email,
                'error' => $exception->getMessage(),
            ]);
            return response()->json([
                'statusCode' => 503,
                'message' => 'No se pudo enviar el código de verificación',
            ], 503);
        }

        return response()->json([
            'statusCode' => 200,
            'message' => 'Te enviamos un código de 6 dígitos',
            'challenge' => $challenge,
        ]);
    }

    public function verifyRegistrationCode(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
                'code' => ['required', 'digits:6'],
                'challenge' => ['required', 'string', 'max:4096'],
            ]);
            $challenge = app(JwtService::class)->verify($data['challenge']);
        } catch (\Throwable $exception) {
            return response()->json([
                'statusCode' => 422,
                'message' => 'El código venció o la solicitud no es válida',
            ], 422);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        if (
            ($challenge['purpose'] ?? null) !== 'registration_email_code'
            || mb_strtolower((string) ($challenge['email'] ?? '')) !== $email
            || !hash_equals((string) ($challenge['code_hash'] ?? ''), hash('sha256', $data['code']))
        ) {
            return response()->json([
                'statusCode' => 422,
                'message' => 'El código ingresado no es correcto',
            ], 422);
        }

        return response()->json([
            'statusCode' => 200,
            'message' => 'Correo verificado correctamente',
            'verification_token' => app(JwtService::class)->sign([
                'purpose' => 'registration_email_verified',
                'email' => $email,
            ], 30 * 60),
        ]);
    }

    public function verifyGoogleRegistration(Request $request)
    {
        try {
            $data = $request->validate([
                'id_token' => ['required', 'string', 'max:4096'],
            ]);
            $profile = $this->googleProfileFromIdToken($data['id_token']);
        } catch (\RuntimeException $exception) {
            $notConfigured = $exception->getMessage() === 'Google no está configurado';
            return response()->json([
                'statusCode' => $notConfigured ? 503 : 401,
                'message' => $exception->getMessage() ?: 'No se pudo validar la cuenta de Google',
            ], $notConfigured ? 503 : 401);
        } catch (\Throwable $exception) {
            return response()->json([
                'statusCode' => 503,
                'message' => 'No se pudo conectar con Google',
            ], 503);
        }

        $email = mb_strtolower(trim((string) data_get($profile, 'email', '')));
        return response()->json([
            'statusCode' => 200,
            'message' => 'Correo validado con Google',
            'profile' => [
                'email' => $email,
                'nombre' => (string) data_get($profile, 'given_name', ''),
                'apellido' => (string) data_get($profile, 'family_name', ''),
            ],
            'verification_token' => app(JwtService::class)->sign([
                'purpose' => 'registration_email_verified',
                'email' => $email,
            ], 30 * 60),
        ]);
    }

    private function googleProfileFromIdToken(string $idToken): array
    {
        $clientId = trim((string) config('services.google.client_id'));
        if ($clientId === '') {
            throw new \RuntimeException('Google no está configurado');
        }

        $response = Http::acceptJson()
            ->connectTimeout(5)
            ->timeout(10)
            ->get('https://oauth2.googleapis.com/tokeninfo', ['id_token' => $idToken]);
        if (!$response->successful()) {
            throw new \RuntimeException('El token de Google es inválido o expiró');
        }

        $profile = $response->json();
        $email = mb_strtolower(trim((string) data_get($profile, 'email', '')));
        $verified = filter_var(data_get($profile, 'email_verified', false), FILTER_VALIDATE_BOOLEAN);
        if (
            !hash_equals($clientId, (string) data_get($profile, 'aud', ''))
            || !in_array((string) data_get($profile, 'iss', ''), ['accounts.google.com', 'https://accounts.google.com'], true)
            || !$verified
            || filter_var($email, FILTER_VALIDATE_EMAIL) === false
        ) {
            throw new \RuntimeException('La identidad de Google no pudo ser verificada');
        }

        return $profile;
    }

    public function login(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
                'password' => ['required', 'string'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Datos inválidos',
                'message' => 'Validación fallida',
                'details' => $e->errors(),
            ], 400);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        $user = DB::table('usuarios')->whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$user) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Credenciales inválidas',
                'message' => 'Correo o contraseña incorrectos',
            ], 401);
        }
        if (!(bool) $user->activo) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Cuenta inactiva',
                'message' => 'Tu cuenta ha sido desactivada',
            ], 401);
        }
        if (!$this->verifyPassword((string) $data['password'], (string) $user->password)) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Credenciales inválidas',
                'message' => 'Correo o contraseña incorrectos',
            ], 401);
        }
        try {
            if (
                !$this->passwordLooksHashed((string) $user->password)
                || Hash::needsRehash((string) $user->password)
            ) {
                DB::table('usuarios')
                    ->where('id', (int) $user->id)
                    ->update([
                        'password' => Hash::make((string) $data['password']),
                        'updated_at' => now(),
                    ]);
            }
        } catch (\Throwable $exception) {
            Log::warning('No se pudo actualizar el hash de la contraseña.', [
                'user_id' => (int) $user->id,
                'error' => $exception->getMessage(),
            ]);
        }

        $token = app(JwtService::class)->sign([
            'id' => (int) $user->id,
            'email' => (string) $user->email,
            'tipo' => 'usuario',
        ]);

        return response()->json([
            'statusCode' => 200,
            'message' => 'Inicio de sesión exitoso',
            'user' => [
                'id' => (int) $user->id,
                'nombre' => (string) $user->nombre,
                'apellido' => (string) $user->apellido,
                'email' => (string) $user->email,
                'telefono' => $user->telefono,
                'direccion' => $user->direccion,
                'distrito' => $user->distrito,
                'numero_casa' => $user->numero_casa,
            ],
            'token' => $token,
        ], 200);
    }

    public function googleLogin(Request $request)
    {
        try {
            $data = $request->validate([
                'id_token' => ['required', 'string', 'max:4096'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Datos inválidos',
                'message' => 'El token de Google es obligatorio',
                'details' => $e->errors(),
            ], 400);
        }

        try {
            $profile = $this->googleProfileFromIdToken($data['id_token']);
        } catch (\RuntimeException $exception) {
            $notConfigured = $exception->getMessage() === 'Google no está configurado';
            return response()->json([
                'statusCode' => $notConfigured ? 503 : 401,
                'error' => $notConfigured ? 'Google no configurado' : 'Token inválido',
                'message' => $exception->getMessage(),
            ], $notConfigured ? 503 : 401);
        } catch (\Throwable $exception) {
            return response()->json([
                'statusCode' => 503,
                'error' => 'Google no disponible',
                'message' => 'No se pudo validar el token con Google',
            ], 503);
        }

        $email = mb_strtolower(trim((string) data_get($profile, 'email', '')));

        $user = DB::table('usuarios')->whereRaw('LOWER(email) = ?', [$email])->first();
        if (!$user) {
            return response()->json([
                'statusCode' => 404,
                'error' => 'Cuenta no encontrada',
                'message' => 'No existe una cuenta registrada con este correo. Regístrate primero.',
            ], 404);
        }

        if (!(bool) $user->activo) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Cuenta inactiva',
                'message' => 'Tu cuenta ha sido desactivada',
            ], 401);
        }

        $token = app(JwtService::class)->sign([
            'id' => (int) $user->id,
            'email' => (string) $user->email,
            'tipo' => 'usuario',
        ]);

        return response()->json([
            'statusCode' => 200,
            'message' => 'Inicio de sesión con Google exitoso',
            'user' => [
                'id' => (int) $user->id,
                'nombre' => (string) $user->nombre,
                'apellido' => (string) $user->apellido,
                'email' => (string) $user->email,
                'telefono' => $user->telefono,
                'direccion' => $user->direccion,
                'distrito' => $user->distrito,
                'numero_casa' => $user->numero_casa,
            ],
            'token' => $token,
        ], 200);
    }

    public function forgotPassword(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Datos inválidos',
                'message' => 'Ingresa un correo válido',
                'details' => $e->errors(),
            ], 400);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        $user = DB::table('usuarios')
            ->select(['id', 'nombre', 'email', 'password', 'activo'])
            ->whereRaw('LOWER(email) = ?', [$email])
            ->first();

        $code = (string) random_int(100000, 999999);
        $challenge = app(JwtService::class)->sign([
            'purpose' => 'password_reset_code',
            'user_id' => (int) ($user->id ?? 0),
            'email' => $email,
            'code_hash' => hash('sha256', $code),
            'password_fingerprint' => hash('sha256', (string) ($user->password ?? '')),
        ], 15 * 60);

        if ($user && (bool) $user->activo) {
            $sent = $this->sendPasswordResetCodeEmail(
                (string) $user->email,
                (string) $user->nombre,
                $code
            );
            if (!$sent) {
                return response()->json([
                    'statusCode' => 503,
                    'message' => 'No se pudo enviar el código de recuperación',
                ], 503);
            }
        }

        return response()->json([
            'statusCode' => 200,
            'message' => 'Si el correo pertenece a una cuenta activa, recibirás un código de 6 dígitos.',
            'challenge' => $challenge,
        ]);
    }

    public function verifyPasswordResetCode(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
                'code' => ['required', 'digits:6'],
                'challenge' => ['required', 'string', 'max:4096'],
            ]);
            $challenge = app(JwtService::class)->verify($data['challenge']);
        } catch (\Throwable $exception) {
            return response()->json([
                'statusCode' => 422,
                'message' => 'El código venció o la solicitud no es válida',
            ], 422);
        }

        $email = mb_strtolower(trim((string) $data['email']));
        if (
            ($challenge['purpose'] ?? null) !== 'password_reset_code'
            || mb_strtolower((string) ($challenge['email'] ?? '')) !== $email
            || !hash_equals((string) ($challenge['code_hash'] ?? ''), hash('sha256', $data['code']))
        ) {
            return response()->json([
                'statusCode' => 422,
                'message' => 'El código ingresado no es correcto',
            ], 422);
        }

        return response()->json([
            'statusCode' => 200,
            'message' => 'Código verificado correctamente',
            'reset_token' => app(JwtService::class)->sign([
                'purpose' => 'password_reset',
                'user_id' => (int) ($challenge['user_id'] ?? 0),
                'password_fingerprint' => (string) ($challenge['password_fingerprint'] ?? ''),
            ], 15 * 60),
        ]);
    }

    public function resetPassword(Request $request)
    {
        try {
            $data = $request->validate([
                'token' => ['required', 'string', 'max:4096'],
                'password' => ['required', 'confirmed', PasswordRules::userPassword()],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 422,
                'error' => 'Datos inválidos',
                'message' => 'Revisa la nueva contraseña',
                'details' => $e->errors(),
            ], 422);
        }

        try {
            $payload = app(JwtService::class)->verify($data['token']);
        } catch (\Throwable $exception) {
            return $this->invalidPasswordResetToken();
        }

        if (($payload['purpose'] ?? null) !== 'password_reset') {
            return $this->invalidPasswordResetToken();
        }

        $user = DB::table('usuarios')
            ->select(['id', 'password', 'activo'])
            ->where('id', (int) ($payload['user_id'] ?? 0))
            ->first();

        $expectedFingerprint = hash('sha256', (string) ($user->password ?? ''));
        $receivedFingerprint = (string) ($payload['password_fingerprint'] ?? '');

        if (
            !$user
            || !(bool) $user->activo
            || $receivedFingerprint === ''
            || !hash_equals($expectedFingerprint, $receivedFingerprint)
        ) {
            return $this->invalidPasswordResetToken();
        }

        DB::table('usuarios')
            ->where('id', (int) $user->id)
            ->update([
                'password' => Hash::make($data['password']),
                'updated_at' => now(),
            ]);

        return response()->json([
            'statusCode' => 200,
            'message' => 'Tu contraseña fue actualizada. Ya puedes iniciar sesión.',
        ]);
    }

    public function adminLogin(Request $request)
    {
        try {
            $data = $request->validate([
                'email' => ['required', 'email', 'max:191'],
                'password' => ['required', 'string'],
            ]);
        } catch (ValidationException $e) {
            return response()->json([
                'statusCode' => 400,
                'error' => 'Datos inválidos',
                'message' => 'Validación fallida',
                'details' => $e->errors(),
            ], 400);
        }

        $admin = DB::table('administradores')->where('email', $data['email'])->first();
        if (!$admin) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Credenciales inválidas',
                'message' => 'Correo o contraseña incorrectos',
            ], 401);
        }
        if (!(bool) $admin->activo) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Cuenta inactiva',
                'message' => 'Tu cuenta de administrador ha sido desactivada',
            ], 401);
        }
        if (!$this->verifyPassword((string) $data['password'], (string) $admin->password)) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Credenciales inválidas',
                'message' => 'Correo o contraseña incorrectos',
            ], 401);
        }

        $token = app(JwtService::class)->sign([
            'id' => (int) $admin->id,
            'email' => (string) $admin->email,
            'tipo' => 'admin',
        ]);

        return response()->json([
            'statusCode' => 200,
            'message' => 'Inicio de sesión de administrador exitoso',
            'admin' => [
                'id' => (int) $admin->id,
                'nombre' => (string) $admin->nombre,
                'email' => (string) $admin->email,
                'rol' => (string) $admin->rol,
            ],
            'token' => $token,
        ], 200);
    }

    public function verify(Request $request)
    {
        $payload = $request->attributes->get('user');
        if (!is_array($payload)) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Token inválido',
                'message' => 'Token inválido o expirado',
            ], 401);
        }

        $tipo = $payload['tipo'] ?? null;
        $id = isset($payload['id']) ? (int) $payload['id'] : 0;
        if ($tipo === 'admin') {
            $admin = DB::table('administradores')
                ->select(['id', 'nombre', 'email', 'rol', 'activo'])
                ->where('id', $id)
                ->first();

            if (!$admin || !(bool) $admin->activo) {
                return response()->json([
                    'statusCode' => 401,
                    'error' => 'Token inválido',
                    'message' => 'Administrador no encontrado o inactivo',
                ], 401);
            }

            return response()->json([
                'statusCode' => 200,
                'message' => 'Token válido',
                'tipo' => 'admin',
                'admin' => [
                    'id' => (int) $admin->id,
                    'nombre' => (string) $admin->nombre,
                    'email' => (string) $admin->email,
                    'rol' => (string) $admin->rol,
                ],
            ], 200);
        }

        $user = DB::table('usuarios')
            ->select([
                'id', 'nombre', 'apellido', 'email', 'telefono', 'direccion', 'distrito', 'numero_casa', 'activo',
            ])
            ->where('id', $id)
            ->first();

        if (!$user || !(bool) $user->activo) {
            return response()->json([
                'statusCode' => 401,
                'error' => 'Token inválido',
                'message' => 'Usuario no encontrado o inactivo',
            ], 401);
        }

        return response()->json([
            'statusCode' => 200,
            'message' => 'Token válido',
            'tipo' => 'usuario',
            'user' => [
                'id' => (int) $user->id,
                'nombre' => (string) $user->nombre,
                'apellido' => (string) $user->apellido,
                'email' => (string) $user->email,
                'telefono' => $user->telefono,
                'direccion' => $user->direccion,
                'distrito' => $user->distrito,
                'numero_casa' => $user->numero_casa,
            ],
        ], 200);
    }

    private function invalidPasswordResetToken()
    {
        return response()->json([
            'statusCode' => 422,
            'error' => 'Enlace inválido',
            'message' => 'El enlace es inválido, ya fue utilizado o ha vencido.',
        ], 422);
    }

    private function sendPasswordResetCodeEmail(
        string $email,
        string $name,
        string $code
    ): bool {
        $apiKey = trim((string) config('services.resend.key'));
        $fromAddress = trim((string) config('mail.from.address'));
        $fromName = trim((string) config('mail.from.name', 'Delicias del centro'));

        if ($apiKey === '' || $fromAddress === '' || str_contains($fromAddress, 'example.com')) {
            Log::error('Password reset email is not configured.', [
                'has_resend_key' => $apiKey !== '',
                'from_address' => $fromAddress,
            ]);

            return false;
        }

        $safeName = htmlspecialchars($name !== '' ? $name : 'cliente', ENT_QUOTES, 'UTF-8');
        $safeCode = htmlspecialchars($code, ENT_QUOTES, 'UTF-8');
        $html = <<<HTML
            <div style="font-family:Arial,sans-serif;color:#292524;line-height:1.6">
                <h2>Código para restablecer tu contraseña</h2>
                <p>Hola {$safeName}, recibimos una solicitud para cambiar la contraseña de tu cuenta.</p>
                <p style="font-size:30px;font-weight:700;letter-spacing:8px">{$safeCode}</p>
                <p>Este código vence en 15 minutos y solo puede utilizarse una vez.</p>
                <p>Si no solicitaste el cambio, ignora este correo.</p>
            </div>
            HTML;

        try {
            $response = Http::withToken($apiKey)
                ->acceptJson()
                ->timeout(20)
                ->post('https://api.resend.com/emails', [
                    'from' => $fromName . ' <' . $fromAddress . '>',
                    'to' => [$email],
                    'subject' => 'Código para restablecer tu contraseña',
                    'html' => $html,
                ]);

            if (!$response->successful()) {
                Log::error('Resend rejected the password reset email.', [
                    'status' => $response->status(),
                    'response' => $response->json(),
                ]);
                return false;
            }
            return true;
        } catch (\Throwable $exception) {
            Log::error('Could not send password reset email.', [
                'error' => $exception->getMessage(),
            ]);
            return false;
        }
    }
}
