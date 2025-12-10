import 'dart:async';
import 'dart:convert';
import 'package:bargam_app/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ChatListStatus { initial, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  final HttpClient httpClient;
  String? _currentUserId;

  ChatProvider({required this.httpClient});

  // ========================
  // لیست مکالمات
  // ========================
  ChatListStatus _status = ChatListStatus.initial;
  List<Map<String, dynamic>> _conversations = [];
  String? _errorMessage;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String _searchQuery = '';

  ChatListStatus get status => _status;
  List<Map<String, dynamic>> get conversations => _conversations;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  Future<void> loadConversations({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _conversations.clear();
      _hasMore = true;
      _status = ChatListStatus.loading;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final data = await httpClient.get(
        "/chat/conversations?page=$_page&search=$_searchQuery",
      );

      final newItems = List<Map<String, dynamic>>.from(data["conversations"]);

      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        _conversations.addAll(newItems);
        _page++;
        if (newItems.length < 20) _hasMore = false;
      }

      _status = ChatListStatus.loaded;
    } catch (e) {
      _status = ChatListStatus.error;
      _errorMessage = e.toString();
      print("❌ Error loading conversations: $e");
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchConversations(String q) async {
    _searchQuery = q;
    await loadConversations(refresh: true);
  }

  // ========================
  // پیام‌ها
  // ========================
  List<Map<String, dynamic>> _messages = [];
  bool _loadingMessages = false;
  int? _currentConversationId;

  List<Map<String, dynamic>> get messages => _messages;
  bool get loadingMessages => _loadingMessages;
  int? get currentConversationId => _currentConversationId;

  Future<void> loadMessages(int id) async {
    print("🔵 [loadMessages] Loading messages for conversation: $id");
    _loadingMessages = true;
    _currentConversationId = id;
    notifyListeners();

    try {
      final data = await httpClient.get("/chat/messages/$id");
      _messages = List<Map<String, dynamic>>.from(data["messages"]);
      print("✅ [loadMessages] Loaded ${_messages.length} messages");
    } catch (e) {
      _messages = [];
      _errorMessage = e.toString();
      print("❌ [loadMessages] Error: $e");
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  // ========================
  // WebSocket
  // ========================
  WebSocketChannel? _channel;
  bool _supportTyping = false;

  bool get isTyping => _supportTyping;

  void setUserId(String? userId) {
    print("🔵 [setUserId] Setting user ID: $userId");
    _currentUserId = userId;
  }

  void connectWebSocket(int conversationId) async {
    print("🔵 [connectWebSocket] Starting connection for conversation: $conversationId");

    disconnectWebSocket();

    if (_currentUserId == null) {
      print("❌ [connectWebSocket] User ID is NULL! Cannot connect.");
      return;
    }

    print("✅ [connectWebSocket] User ID verified: $_currentUserId");

    final base = httpClient.baseUrl;
    final wsUrl = "${base.replaceFirst("http", "ws")}/ws/chat/$conversationId?user_id=$_currentUserId";

    print("🔗 [connectWebSocket] WebSocket URL: $wsUrl");

    try {
      print("⏳ [connectWebSocket] Attempting to connect...");
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      print("✅ [connectWebSocket] WebSocket channel created");

      _channel!.stream.listen(
            (event) {
          print("📩 [WebSocket] RAW data received: $event");

          try {
            final data = jsonDecode(event);
            print("📩 [WebSocket] Parsed data: $data");

            final type = data["type"];
            print("📩 [WebSocket] Message type: $type");

            if (type == "message") {
              final msg = data["message"];
              if (msg != null) {
                print("💬 [WebSocket] New message received: ${msg['id']} - ${msg['text']}");
                final exists = _messages.any((m) => m["id"] == msg["id"]);
                if (!exists) {
                  _messages.add(msg);
                  _messages.sort((a, b) => a["id"].compareTo(b["id"]));
                  print("✅ [WebSocket] Message added to list. Total: ${_messages.length}");
                  notifyListeners();
                } else {
                  print("⚠️ [WebSocket] Message already exists, skipping");
                }
              }
            } else if (type == "typing") {
              print("⌨️ [WebSocket] Typing event: ${data['from']} - ${data['is_typing']}");
              if (data["from"] == "support" || data["from"] == "admin") {
                _supportTyping = data["is_typing"] ?? false;
                notifyListeners();
              }
            } else if (type == "seen") {
              print("👁️ [WebSocket] Seen event: last_id=${data['last_id']}");
              final lastId = data["last_id"];
              if (lastId != null) {
                for (var msg in _messages) {
                  if (msg["id"] <= lastId) {
                    msg["is_seen"] = true;
                  }
                }
                notifyListeners();
              }
            }
          } catch (e) {
            print("❌ [WebSocket] Error parsing message: $e");
          }
        },
        onError: (error) {
          print("❌ [WebSocket] Connection error: $error");
          _supportTyping = false;
          notifyListeners();
        },
        onDone: () {
          print("🔴 [WebSocket] Connection closed");
          _supportTyping = false;
          notifyListeners();
        },
      );

      print("✅ [connectWebSocket] WebSocket listener attached successfully");
    } catch (e) {
      print("❌ [connectWebSocket] Failed to connect: $e");
      print("❌ [connectWebSocket] Error type: ${e.runtimeType}");
    }
  }

  void disconnectWebSocket() {
    if (_channel != null) {
      print("🔴 [disconnectWebSocket] Closing WebSocket connection");
      _channel?.sink.close();
      _channel = null;
      _supportTyping = false;
      print("✅ [disconnectWebSocket] WebSocket closed");
    } else {
      print("⚠️ [disconnectWebSocket] No active WebSocket to close");
    }
  }

  void sendMessage(String text) {
    print("📤 [sendMessage] Attempting to send message: '$text'");

    if (_channel == null) {
      print("❌ [sendMessage] WebSocket is NULL! Cannot send message.");
      return;
    }

    if (_currentConversationId == null) {
      print("❌ [sendMessage] Conversation ID is NULL!");
      return;
    }

    final message = jsonEncode({
      "action": "send_message",
      "text": text,
      "type": "text",
    });

    print("📤 [sendMessage] JSON payload: $message");
    print("📤 [sendMessage] Conversation ID: $_currentConversationId");
    print("📤 [sendMessage] User ID: $_currentUserId");

    try {
      _channel!.sink.add(message);
      print("✅ [sendMessage] Message sent successfully");
    } catch (e) {
      print("❌ [sendMessage] Error sending message: $e");
    }
  }

  void sendTyping(bool isTyping) {
    if (_channel == null) {
      print("⚠️ [sendTyping] WebSocket not connected, skipping typing event");
      return;
    }

    final payload = jsonEncode({
      "action": "typing",
      "from": "user",
      "is_typing": isTyping,
    });

    print("⌨️ [sendTyping] Sending typing status: $isTyping");
    _channel!.sink.add(payload);
  }

  void markAsSeen(int lastMessageId) {
    if (_channel == null) return;

    final payload = jsonEncode({
      "action": "seen",
      "last_message_id": lastMessageId,
    });

    print("👁️ [markAsSeen] Marking message as seen: $lastMessageId");
    _channel!.sink.add(payload);
  }

  Future<Map<String, dynamic>> startNewChat({String title = "سوال جدید"}) async {
    print("🔵 [startNewChat] Creating new chat with title: $title");
    try {
      final data = await httpClient.post(
        "/chat/conversations",
        body: {"title": title},
      );

      print("✅ [startNewChat] Chat created: ${data['conversation']}");
      return data["conversation"];
    } catch (e) {
      print("❌ [startNewChat] Error: $e");
      rethrow;
    }
  }

  void clearMessages() {
    print("🔵 [clearMessages] Clearing all messages");
    _messages.clear();
    _currentConversationId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    print("🔴 [dispose] ChatProvider disposing");
    disconnectWebSocket();
    super.dispose();
  }
}
