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

  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    debugPrint("🔵 [ChatPage] initState - Conversation: ${widget.conversationId}");

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      debugPrint("🔵 [ChatPage] PostFrameCallback started");

      _chatProvider = context.read<ChatProvider>();
      final authProvider = context.read<AuthProvider>();

      debugPrint("🔵 [ChatPage] Auth userId: ${authProvider.userId}");
      debugPrint("🔵 [ChatPage] Setting userId in ChatProvider...");

      _chatProvider.setUserId(authProvider.userId);

      debugPrint("🔵 [ChatPage] Loading messages...");
      await _chatProvider.loadMessages(widget.conversationId);

      debugPrint("🔵 [ChatPage] Connecting WebSocket...");
      _chatProvider.connectWebSocket(widget.conversationId);

      debugPrint("✅ [ChatPage] Initialization complete");

      Future.delayed(const Duration(milliseconds: 200), _scrollToBottom);
    });
  }

  @override
  void dispose() {
    debugPrint("🔴 [ChatPage] dispose called");
    _chatProvider.disconnectWebSocket();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      debugPrint("⚠️ [_scrollToBottom] ScrollController has no clients");
      return;
    }
    debugPrint("📜 [_scrollToBottom] Scrolling to bottom");
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    debugPrint("📤 [_sendMessage] Button pressed. Text: '$text'");

    if (text.isEmpty) {
      debugPrint("⚠️ [_sendMessage] Empty message, ignoring");
      return;
    }

    debugPrint("📤 [_sendMessage] Calling provider.sendMessage()");
    _chatProvider.sendMessage(text);

    _controller.clear();
    debugPrint("✅ [_sendMessage] Message sent, input cleared");

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

                debugPrint("🔄 [build] Rendering ${messages.length} messages");

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (provider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length && provider.isTyping) {
                      return const Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "پشتیبان در حال تایپ است...",
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(width: 8),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final msg = messages[index];
                    final isMe = msg["sender_type"] == "user";

                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg["text"] ?? "",
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatTime(msg["created_at"]),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                if (isMe && msg["is_seen"] == true) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.done_all,
                                    size: 14,
                                    color: Colors.white70,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "پیام خود را بنویسید...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    onChanged: (text) {
                      _chatProvider.sendTyping(text.isNotEmpty);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return "";
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }
}
