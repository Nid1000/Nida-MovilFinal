<?php

namespace Tests\Feature;

use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set([
            'services.jwt.secret' => 'test-jwt-secret-with-enough-random-characters',
            'services.resend.key' => 're_test_key',
            'mail.from.address' => 'cuentas@saborcentral.com',
            'mail.from.name' => 'Delicias del centro',
        ]);

        Schema::create('usuarios', function (Blueprint $table): void {
            $table->id();
            $table->string('nombre');
            $table->string('apellido');
            $table->string('email')->unique();
            $table->string('password');
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });

        DB::table('usuarios')->insert([
            'nombre' => 'María',
            'apellido' => 'Pérez',
            'email' => 'maria@example.com',
            'password' => Hash::make('Anterior1'),
            'activo' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('usuarios');
        parent::tearDown();
    }

    public function test_active_user_receives_a_password_reset_code(): void
    {
        Http::fake([
            'https://api.resend.com/emails' => Http::response(['id' => 'email-id'], 200),
        ]);

        $response = $this->postJson('/api/auth/password/forgot', [
            'email' => 'MARIA@example.com',
        ])->assertOk()->assertJsonStructure(['challenge']);

        $this->assertNotEmpty($response->json('challenge'));
        Http::assertSent(function ($request): bool {
            return $request->url() === 'https://api.resend.com/emails'
                && in_array('maria@example.com', $request['to'], true)
                && preg_match('/\b\d{6}\b/', (string) $request['html']) === 1;
        });
    }

    public function test_unknown_email_returns_the_same_generic_shape_without_sending_mail(): void
    {
        Http::fake();

        $this->postJson('/api/auth/password/forgot', [
            'email' => 'unknown@example.com',
        ])
            ->assertOk()
            ->assertJsonStructure(['message', 'challenge']);

        Http::assertNothingSent();
    }

    public function test_valid_code_changes_password_and_token_cannot_be_reused(): void
    {
        Http::fake([
            'https://api.resend.com/emails' => Http::response(['id' => 'email-id'], 200),
        ]);

        $code = null;
        $response = $this->postJson('/api/auth/password/forgot', [
            'email' => 'maria@example.com',
        ])->assertOk();

        Http::assertSent(function ($request) use (&$code): bool {
            preg_match('/\b(\d{6})\b/', (string) $request['html'], $matches);
            $code = $matches[1] ?? null;
            return is_string($code);
        });

        $resetToken = $this->postJson('/api/auth/password/verify-code', [
            'email' => 'maria@example.com',
            'code' => $code,
            'challenge' => $response->json('challenge'),
        ])
            ->assertOk()
            ->json('reset_token');

        $payload = [
            'token' => $resetToken,
            'password' => 'NuevaClave1',
            'password_confirmation' => 'NuevaClave1',
        ];

        $this->postJson('/api/auth/password/reset', $payload)
            ->assertOk()
            ->assertJsonPath(
                'message',
                'Tu contraseña fue actualizada. Ya puedes iniciar sesión.'
            );

        $stored = DB::table('usuarios')
            ->where('email', 'maria@example.com')
            ->value('password');
        $this->assertTrue(Hash::check('NuevaClave1', $stored));

        $this->postJson('/api/auth/password/reset', $payload)
            ->assertStatus(422)
            ->assertJsonPath('error', 'Enlace inválido');
    }
}
