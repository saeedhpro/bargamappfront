import 'dart:async';
import 'dart:convert';
import 'package:bargam_app/core/network/http_client.dart';
import 'package:bargam_app/features/chat/presentation/models/department.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ChatListStatus { initial, loading, loaded, error }

class ChatProvider extends ChangeNotifier {
  final HttpClient httpClient;
  String? _currentUserId;
  bool _isDisposed = false;  // ✅ اضافه شد

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

  // ========================
  // دپارتمان‌ها
  // ========================
  List<Department> _departments = [];
  List<Department> get departments => _departments;
  bool _departmentsLoading = false;
  bool get departmentsLoading => _departmentsLoading;

  /// بارگذاری لیست دپارتمان‌ها
  Future<void> loadDepartments() async {
    if (_departmentsLoading) return;

    _departmentsLoading = true;
    notifyListeners();

    try {
      final data = await httpClient.get('/departments');

      if (data is List) {
        _departments = data.map((json) => Department.fromJson(json)).toList();
      } else if (data is Map && data.containsKey('departments')) {
        _departments = (data['departments'] as List)
            .map((json) => Department.fromJson(json))
            .toList();
      } else {
        debugPrint('⚠️ Unexpected departments response format');
        _departments = [];
      }

      debugPrint('✅ Loaded ${_departments.length} departments');
    } catch (e) {
      debugPrint('❌ Error loading departments: $e');
      _departments = [];
      rethrow;
    } finally {
      _departmentsLoading = false;
      notifyListeners();
    }
  }

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
      debugPrint("❌ Error loading conversations: $e");
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
  Map<String, dynamic>? _currentConversation;

  List<Map<String, dynamic>> get messages => _messages;
  bool get loadingMessages => _loadingMessages;
  int? get currentConversationId => _currentConversationId;
  Map<String, dynamic>? get currentConversation => _currentConversation;
  String? get userId => _currentUserId;

  Future<void> loadMessages(int id) async {
    debugPrint("🔵 [loadMessages] Loading messages for conversation: $id");
    _loadingMessages = true;
    _currentConversationId = id;
    notifyListeners();

    try {
      final data = await httpClient.get("/chat/messages/$id");

      debugPrint("📦 [loadMessages] Raw response: $data");

      if (data is Map && data.containsKey("messages")) {
        final messagesData = data["messages"];

        if (messagesData is Map) {
          _currentConversation = messagesData["conversation"];

          if (messagesData.containsKey("messages") && messagesData["messages"] is List) {
            _messages = List<Map<String, dynamic>>.from(messagesData["messages"]);
          } else {
            _messages = [];
          }

          debugPrint("✅ [loadMessages] Conversation: ${_currentConversation?['title']}");
          debugPrint("✅ [loadMessages] Department: ${_currentConversation?['department']?['name']}");
          debugPrint("✅ [loadMessages] Messages count: ${_messages.length}");
        } else {
          debugPrint("⚠️ [loadMessages] messagesData is not a Map");
          _messages = [];
          _currentConversation = null;
        }
      } else {
        debugPrint("⚠️ [loadMessages] Unexpected response format");
        _messages = [];
        _currentConversation = null;
      }

    } catch (e) {
      _messages = [];
      _currentConversation = null;
      _errorMessage = e.toString();
      debugPrint("❌ [loadMessages] Error: $e");
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
    debugPrint("🔵 [setUserId] Setting user ID: $userId");
    _currentUserId = userId;
  }

  void connectWebSocket(int conversationId) async {
    debugPrint("🔵 [connectWebSocket] Starting connection for conversation: $conversationId");

    disconnectWebSocket();

    if (_currentUserId == null) {
      debugPrint("❌ [connectWebSocket] User ID is NULL! Cannot connect.");
      return;
    }

    debugPrint("✅ [connectWebSocket] User ID verified: $_currentUserId");

    final base = httpClient.baseUrl;
    final wsUrl = "${base.replaceFirst("http", "ws")}/ws/chat/$conversationId?user_id=$_currentUserId";

    debugPrint("🔗 [connectWebSocket] WebSocket URL: $wsUrl");

    try {
      debugPrint("⏳ [connectWebSocket] Attempting to connect...");
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      debugPrint("✅ [connectWebSocket] WebSocket channel created");

      _channel!.stream.listen(
            (event) {
          if (_isDisposed) return;  // ✅ چک dispose

          debugPrint("📩 [WebSocket] RAW data received: $event");

          try {
            final data = jsonDecode(event);
            debugPrint("📩 [WebSocket] Parsed data: $data");

            final type = data["type"];
            debugPrint("📩 [WebSocket] Message type: $type");

            if (type == "message") {
              final msg = data["message"];
              if (msg != null) {
                debugPrint("💬 [WebSocket] New message received: ${msg['id']} - ${msg['text']}");
                final exists = _messages.any((m) => m["id"] == msg["id"]);
                if (!exists) {
                  _messages.add(msg);
                  _messages.sort((a, b) => a["id"].compareTo(b["id"]));
                  debugPrint("✅ [WebSocket] Message added to list. Total: ${_messages.length}");
                  notifyListeners();
                } else {
                  debugPrint("⚠️ [WebSocket] Message already exists, skipping");
                }
              }
            } else if (type == "typing") {
              debugPrint("⌨️ [WebSocket] Typing event: ${data['from']} - ${data['is_typing']}");
              if (data["from"] == "support" || data["from"] == "admin") {
                _supportTyping = data["is_typing"] ?? false;
                notifyListeners();
              }
            } else if (type == "seen") {
              debugPrint("👁️ [WebSocket] Seen event: last_id=${data['last_id']}");
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
            debugPrint("❌ [WebSocket] Error parsing message: $e");
          }
        },
        onError: (error) {
          if (_isDisposed) return;  // ✅ چک dispose
          debugPrint("❌ [WebSocket] Connection error: $error");
          _supportTyping = false;
          notifyListeners();
        },
        onDone: () {
          if (_isDisposed) return;  // ✅ چک dispose
          debugPrint("🔴 [WebSocket] Connection closed");
          _supportTyping = false;
          notifyListeners();
        },
      );

      debugPrint("✅ [connectWebSocket] WebSocket listener attached successfully");
    } catch (e) {
      debugPrint("❌ [connectWebSocket] Failed to connect: $e");
      debugPrint("❌ [connectWebSocket] Error type: ${e.runtimeType}");
    }
  }

  void disconnectWebSocket() {
    if (_channel != null) {
      debugPrint("🔴 [disconnectWebSocket] Closing WebSocket connection");
      _channel?.sink.close();
      _channel = null;
      _supportTyping = false;
      debugPrint("✅ [disconnectWebSocket] WebSocket closed");

      // ✅ فقط در صورتی notifyListeners صدا بزن که dispose نشده باشیم
      if (!_isDisposed) {
        notifyListeners();
      }
    } else {
      debugPrint("⚠️ [disconnectWebSocket] No active WebSocket to close");
    }
  }

  void sendMessage(String text) {
    debugPrint("📤 [sendMessage] Attempting to send message: '$text'");

    if (_channel == null) {
      debugPrint("❌ [sendMessage] WebSocket is NULL! Cannot send message.");
      return;
    }

    if (_currentConversationId == null) {
      debugPrint("❌ [sendMessage] Conversation ID is NULL!");
      return;
    }

    final message = jsonEncode({
      "action": "send_message",
      "text": text,
      "type": "text",
    });

    debugPrint("📤 [sendMessage] JSON payload: $message");

    try {
      _channel!.sink.add(message);
      debugPrint("✅ [sendMessage] Message sent successfully");
    } catch (e) {
      debugPrint("❌ [sendMessage] Error sending message: $e");
    }
  }

  void sendTyping(bool isTyping) {
    if (_channel == null) return;

    final payload = jsonEncode({
      "action": "typing",
      "from": "user",
      "is_typing": isTyping,
    });

    _channel!.sink.add(payload);
  }

  void markAsSeen(int lastMessageId) {
    if (_channel == null) return;

    final payload = jsonEncode({
      "action": "seen",
      "last_message_id": lastMessageId,
    });

    debugPrint("👁️ [markAsSeen] Marking message as seen: $lastMessageId");
    _channel!.sink.add(payload);
  }

  Future<Map<String, dynamic>> startNewChat({
    String title = "سوال جدید",
    required int departmentId,
  }) async {
    debugPrint("🔵 [startNewChat] Creating chat: title=$title, dept=$departmentId");

    try {
      final data = await httpClient.post(
        "/chat/conversations",
        body: {
          "title": title,
          "department_id": departmentId,
        },
      );

      debugPrint("✅ [startNewChat] Chat created: ${data['conversation']}");
      return data["conversation"];
    } catch (e) {
      debugPrint("❌ [startNewChat] Error: $e");
      rethrow;
    }
  }

  void clearMessages() {
    debugPrint("🔵 [clearMessages] Clearing all messages");
    _messages.clear();
    _currentConversationId = null;
    _currentConversation = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint("🔴 [dispose] ChatProvider disposing");
    _isDisposed = true;  // ✅ علامت‌گذاری به عنوان disposed
    disconnectWebSocket();
    super.dispose();
  }
}
