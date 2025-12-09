import 'package:bargam_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:bargam_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final int conversationId;
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late ChatProvider _chatProvider; // ✅ نگه‌داری رفرنس امن Provider

  @override
  void initState() {
    super.initState();

    // گرفتن رفرنس Provider به صورت امن
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();

      // تنظیم userId و اتصال WebSocket
      _chatProvider.setUserId(authProvider.userId);
      await _chatProvider.loadMessages(widget.conversationId);
      _chatProvider.connectWebSocket(widget.conversationId);

      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    });
  }

  @override
  void dispose() {
    // ✅ بدون استفاده از context
    _chatProvider.disconnectWebSocket();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _chatProvider.sendMessage(text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final messages = provider.messages;

                if (provider.loadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (provider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (provider.isTyping && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 14),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text("پشتیبانی در حال نوشتن..."),
                        ),
                      );
                    }

                    final m = messages[index];
                    final senderType = m["sender_type"] ?? m["sender"];
                    final isUser = senderType == "user";

                    return Align(
                      alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m["text"] ?? "",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (v) {
                      _chatProvider.sendTyping(v.isNotEmpty);
                    },
                    decoration: const InputDecoration(
                      hintText: "پیام خود را بنویسید...",
                      border: OutlineInputBorder(),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.green,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
