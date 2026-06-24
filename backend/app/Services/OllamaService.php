<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Http\Client\PendingRequest;

class OllamaService
{
    public function enabled(): bool
    {
        return (bool) config('services.ollama.enabled', false);
    }

    public function baseUrl(): string
    {
        return rtrim((string) config('services.ollama.base_url', ''), '/');
    }

    public function model(): string
    {
        $m = trim((string) config('services.ollama.model', 'llama3.1'));
        return $m !== '' ? $m : 'llama3.1';
    }

    private function client(): PendingRequest
    {
        $client = Http::acceptJson();
        $apiKey = trim((string) config('services.ollama.api_key', ''));

        return $apiKey !== '' ? $client->withToken($apiKey) : $client;
    }

    public function timeoutSeconds(): int
    {
        $t = (int) config('services.ollama.timeout_seconds', 60);
        return $t > 0 ? $t : 60;
    }

    public function temperature(): float
    {
        $temperature = (float) config('services.ollama.temperature', 0.2);
        return max(0.0, min($temperature, 1.0));
    }

    public function available(): bool
    {
        if (!$this->enabled() || $this->baseUrl() === '') {
            return false;
        }

        try {
            return $this->client()
                ->connectTimeout(3)
                ->timeout(5)
                ->get($this->baseUrl() . '/api/tags')
                ->ok();
        } catch (\Throwable) {
            return false;
        }
    }

    public function generate(string $prompt): ?string
    {
        if (!$this->enabled()) {
            return null;
        }
        $base = $this->baseUrl();
        if ($base === '') {
            return null;
        }

        try {
            $resp = $this->client()
                ->connectTimeout(10)
                ->timeout($this->timeoutSeconds())
                ->post($base.'/api/generate', [
                    'model' => $this->model(),
                    'prompt' => $prompt,
                    'stream' => false,
                    'options' => [
                        'temperature' => $this->temperature(),
                        'top_p' => 0.85,
                        'repeat_penalty' => 1.08,
                    ],
                ]);
        } catch (\Throwable) {
            return null;
        }

        if (!$resp->ok()) {
            return null;
        }

        $json = $resp->json();
        $text = is_array($json) ? (string) ($json['response'] ?? '') : '';
        $text = trim($text);
        return $text !== '' ? $text : null;
    }
}
