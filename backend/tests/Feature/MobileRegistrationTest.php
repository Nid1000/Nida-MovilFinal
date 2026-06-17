<?php

namespace Tests\Feature;

use App\Services\JwtService;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Tests\TestCase;

class MobileRegistrationTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set([
            'services.jwt.secret' => 'test-jwt-secret-with-enough-random-characters',
            'services.customer_lifecycle.welcome_enabled' => false,
        ]);

        Schema::create('usuarios', function (Blueprint $table): void {
            $table->id();
            $table->string('nombre');
            $table->string('apellido');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('telefono');
            $table->text('direccion');
            $table->string('distrito');
            $table->string('numero_casa');
            $table->boolean('activo')->default(true);
            $table->timestamps();
        });
    }

    protected function tearDown(): void
    {
        Schema::dropIfExists('usuarios');
        parent::tearDown();
    }

    public function test_verified_mobile_user_can_register_and_login_case_insensitively(): void
    {
        $verificationToken = app(JwtService::class)->sign([
            'purpose' => 'registration_email_verified',
            'email' => 'cliente@example.com',
        ], 1800);

        $this->postJson('/api/auth/register', [
            'nombre' => 'Cliente',
            'apellido' => 'Prueba',
            'email' => 'CLIENTE@example.com',
            'password' => 'ClaveSegura1',
            'telefono' => '936600100',
            'direccion' => 'Jr. Lima 350',
            'distrito' => 'El Tambo',
            'numero_casa' => '350',
            'registration_channel' => 'mobile',
            'email_verification_token' => $verificationToken,
        ])
            ->assertCreated()
            ->assertJsonPath('user.email', 'cliente@example.com')
            ->assertJsonStructure(['token']);

        $storedPassword = DB::table('usuarios')->value('password');
        $this->assertTrue(Hash::check('ClaveSegura1', $storedPassword));

        $this->postJson('/api/auth/login', [
            'email' => 'CLIENTE@EXAMPLE.COM',
            'password' => 'ClaveSegura1',
        ])
            ->assertOk()
            ->assertJsonPath('user.email', 'cliente@example.com')
            ->assertJsonStructure(['token']);
    }

    public function test_registration_rejects_an_unverified_email(): void
    {
        $this->postJson('/api/auth/register', [
            'nombre' => 'Cliente',
            'apellido' => 'Prueba',
            'email' => 'cliente@example.com',
            'password' => 'ClaveSegura1',
            'telefono' => '936600100',
            'direccion' => 'Jr. Lima 350',
            'distrito' => 'El Tambo',
            'numero_casa' => '350',
            'registration_channel' => 'mobile',
            'email_verification_token' => 'token-invalido',
        ])
            ->assertStatus(422)
            ->assertJsonPath('error', 'Correo no verificado');
    }
}
