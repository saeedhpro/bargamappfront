import 'dart:async';
import 'dart:convert';
import 'package:bargam_app/core/network/http_client.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ChatListStatus { initial, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  final HttpClient httpClient;
  String? _currentUserId; // ✅ ذخیره userId

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
    _loadingMessages = true;
    _currentConversationId = id;
    notifyListeners();

    try {
      final data = await httpClient.get("/chat/messages/$id");
      _messages = List<Map<String, dynamic>>.from(data["messages"]);
    } catch (e) {
      _messages = [];
      _errorMessage = e.toString();
      print("❌ Error loading messages: $e");
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

  // ✅ متد جدید: دریافت userId از بیرون
  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  void connectWebSocket(int conversationId) async {
    disconnectWebSocket();

    if (_currentUserId == null) {
      print("❌ User ID not set. Call setUserId() first.");
      return;
    }

    final base = httpClient.baseUrl;

    // ✅ ارسال user_id به جای token
    final wsUrl = "${base.replaceFirst("http", "ws")}/ws/chat/$conversationId?user_id=$_currentUserId";

    print("🔗 Connecting to WebSocket: $wsUrl");

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
            (event) {
          try {
            final data = jsonDecode(event);
            print("📩 WebSocket received: $data");

            final type = data["type"];

            if (type == "message") {
              final msg = data["message"];
              if (msg != null) {
                final exists = _messages.any((m) => m["id"] == msg["id"]);
                if (!exists) {
                  _messages.add(msg);
                  _messages.sort((a, b) => a["id"].compareTo(b["id"]));
                  notifyListeners();
                }
              }
            } else if (type == "typing") {
              if (data["from"] == "support" || data["from"] == "admin") {
                _supportTyping = data["is_typing"] ?? false;
                notifyListeners();
              }
            } else if (type == "seen") {
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
            print("❌ Error parsing WebSocket: $e");
          }
        },
        onError: (error) {
          print("❌ WebSocket error: $error");
          _supportTyping = false;
          notifyListeners();
        },
        onDone: () {
          print("✅ WebSocket closed");
          _supportTyping = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print("❌ Failed to connect WebSocket: $e");
    }
  }

  void disconnectWebSocket() {
    _channel?.sink.close();
    _channel = null;
    _supportTyping = false;
  }

  void sendMessage(String text) {
    if (_channel == null) {
      print("❌ WebSocket not connected");
      return;
    }

    final message = jsonEncode({
      "action": "send_message",
      "text": text,
      "type": "text",
    });

    print("📤 Sending: $message");
    _channel!.sink.add(message);
  }

  void sendTyping(bool isTyping) {
    if (_channel == null) return;

    _channel!.sink.add(jsonEncode({
      "action": "typing",
      "from": "user",
      "is_typing": isTyping,
    }));
  }

  void markAsSeen(int lastMessageId) {
    if (_channel == null) return;

    _channel!.sink.add(jsonEncode({
      "action": "seen",
      "last_message_id": lastMessageId,
    }));
  }

  Future<Map<String, dynamic>> startNewChat({String title = "سوال جدید"}) async {
    try {
      final data = await httpClient.post(
        "/chat/conversations",
        body: {"title": title},
      );

      return data["conversation"];
    } catch (e) {
      print("❌ Error creating chat: $e");
      rethrow;
    }
  }

  void clearMessages() {
    _messages.clear();
    _currentConversationId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectWebSocket();
    super.dispose();
  }
}
