import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';
import '../theme/app_colors.dart';
import '../theme/responsive.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _chatbot = ChatbotService();
  bool _sending = false;
  ChatbotStatus? _status;

  final List<_Msg> _messages = [
    _Msg.bot(
      'Hola, soy Deli, asistente de Delicias del Centro.\n'
      'Puedo ayudarte con productos, promociones, pedidos, delivery, pagos, horarios, ubicación y comprobantes.',
    ),
  ];

  static const _quickQuestions = [
    'Necesito soporte',
    'Quiero trabajar con ustedes',
    '¿Cuál es el horario?',
    '¿Hacen delivery?',
    '¿Cómo pago con Yape?',
    '¿Dónde están ubicados?',
    '¿Cómo pido factura?',
  ];

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await _chatbot.health();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _sendText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_Msg.user(text));
      _sending = true;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .take(_messages.length - 1)
          .skip(_messages.length > 13 ? _messages.length - 13 : 0)
          .map(
            (message) => {
              'role': message.isUser ? 'user' : 'assistant',
              'content': message.text,
            },
          )
          .toList();
      final reply = await _chatbot.ask(message: text, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg.bot(reply.answer));
        if (reply.comesFromOllama && _status != null) {
          _status = ChatbotStatus(
            available: true,
            ollamaEnabled: true,
            model: _status!.model,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _Msg.bot(error.toString().replaceFirst('Exception: ', '')),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _send() => _sendText(_controller.text);

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    final messageCount = _messages.length + (_sending ? 1 : 0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Chatbot'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveContent(
          maxWidth: 720,
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            4,
            compact ? 14 : 24,
            compact ? 10 : 16,
          ),
          child: Column(
            children: [
              _ConnectionBanner(status: _status),
              const SizedBox(height: 10),
              Flexible(
                fit: messageCount <= 2 ? FlexFit.loose : FlexFit.tight,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: compact ? 210 : 240,
                    maxHeight: messageCount <= 2
                        ? (compact ? 330 : 380)
                        : double.infinity,
                  ),
                  child: ListView.builder(
                    controller: _scroll,
                    shrinkWrap: messageCount <= 2,
                    padding: EdgeInsets.fromLTRB(0, 4, 0, compact ? 8 : 14),
                    itemCount: messageCount + (_messages.length == 1 ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _sending) {
                        return const _TypingBubble();
                      }
                      if (i == _messages.length && _messages.length == 1) {
                        return _QuickQuestions(
                          questions: _quickQuestions,
                          sending: _sending,
                          onTap: _sendText,
                        );
                      }
                      return _Bubble(m: _messages[i]);
                    },
                  ),
                ),
              ),
              _Composer(
                controller: _controller,
                sending: _sending,
                onSend: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  final ChatbotStatus? status;

  const _ConnectionBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final loading = status == null;
    final connected = status?.available == true;
    final ollama = status?.ollamaEnabled == true;
    final color = loading
        ? AppColors.info
        : connected && ollama
            ? AppColors.success
            : AppColors.warning;
    final label = loading
        ? 'Conectando a Deli...'
        : connected && ollama
            ? 'Deli conectada con Ollama${status!.model.isEmpty ? '' : ' · ${status!.model}'}'
            : connected
                ? 'Deli conectada · Respuestas rápidas'
                : 'Chatbot sin conexión';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            connected ? Icons.support_agent_outlined : Icons.cloud_off_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickQuestions extends StatelessWidget {
  final List<String> questions;
  final bool sending;
  final ValueChanged<String> onTap;

  const _QuickQuestions({
    required this.questions,
    required this.sending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preguntas rápidas',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final question in questions)
                ActionChip(
                  label: Text(question),
                  onPressed: sending ? null : () => onTap(question),
                  side: const BorderSide(color: AppColors.line),
                  backgroundColor: AppColors.bgSoft,
                  labelStyle: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 54,
              height: 54,
              child: ElevatedButton(
                onPressed: sending ? null : onSend,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _Msg {
  final String text;
  final bool isUser;

  const _Msg._(this.text, this.isUser);

  factory _Msg.user(String t) => _Msg._(t, true);

  factory _Msg.bot(String t) => _Msg._(t, false);
}

class _Bubble extends StatelessWidget {
  final _Msg m;

  const _Bubble({required this.m});

  @override
  Widget build(BuildContext context) {
    final align = m.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = m.isUser ? AppColors.accent : AppColors.card;
    final txt = m.isUser ? Colors.white : AppColors.text;
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxWidth.clamp(260, 520)),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          m.text,
          style: TextStyle(
            color: txt,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
