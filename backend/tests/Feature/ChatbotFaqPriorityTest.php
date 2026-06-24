<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ChatbotFaqPriorityTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        config()->set([
            'services.ollama.enabled' => true,
            'services.ollama.base_url' => 'http://ollama.test',
            'services.ollama.model' => 'gpt-oss:120b',
        ]);
    }

    public function test_business_faq_answers_before_ollama_for_critical_questions(): void
    {
        Http::fake([
            'http://ollama.test/*' => Http::response([
                'response' => 'Horario inventado por el modelo.',
            ], 200),
        ]);

        $this->postJson('/api/chatbot/ask', [
            'message' => 'Cual es el horario?',
            'history' => [],
        ])
            ->assertOk()
            ->assertJsonPath('source', 'faq')
            ->assertJsonFragment([
                'answer' => 'Atendemos de lunes a viernes de 9:00 AM a 6:00 PM y los sábados de 8:00 AM a 2:00 PM. Los domingos permanecemos cerrados.',
            ]);

        Http::assertNothingSent();
    }
}
