import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bargam_app/features/chat/presentation/providers/chat_provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();

    // ✅ استفاده از addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadList();
    });
  }

  Future<void> loadList() async {
    final provider = context.read<ChatProvider>();
    await provider.loadConversations(refresh: true);
  }

  Future<void> newChat() async {
    final provider = context.read<ChatProvider>();

    final conv = await provider.startNewChat();

    final convId = conv["id"];
    final title = conv["title"] ?? "مکالمه جدید";

    await provider.loadConversations(refresh: true);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: convId,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("پشتیبانی")),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: newChat,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    // ✅ نمایش بر اساس وضعیت
    if (provider.status == ChatListStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.status == ChatListStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('خطا در بارگذاری'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadList,
              child: const Text('تلاش مجدد'),
            ),
          ],
        ),
      );
    }

    if (provider.conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('هیچ چتی وجود ندارد'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadList,
      child: ListView.builder(
        itemCount: provider.conversations.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // ✅ نمایش لودینگ در انتهای لیست
          if (index == provider.conversations.length) {
            if (!provider.isLoadingMore) {
              // بارگذاری خودکار صفحه بعدی
              Future.microtask(() => provider.loadConversations());
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final c = provider.conversations[index];

          return ListTile(
            title: Text(c["title"] ?? "بدون عنوان"),
            subtitle: Text(c["last_message"]?["text"] ?? "بدون پیام"),
            trailing: c["unread_count"] != null && c["unread_count"] > 0
                ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Text(
                '${c["unread_count"]}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversationId: c["id"],
                    title: c["title"] ?? "",
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
