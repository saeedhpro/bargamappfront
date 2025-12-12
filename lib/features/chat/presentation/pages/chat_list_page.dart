import 'package:bargam_app/features/chat/widgets/new_chat_modal.dart';
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadList();
      // بارگذاری دپارتمان‌ها
      context.read<ChatProvider>().loadDepartments();
    });
  }

  Future<void> loadList() async {
    final provider = context.read<ChatProvider>();
    await provider.loadConversations(refresh: true);
  }

  /// نمایش مودال ایجاد چت جدید
  /// نمایش مودال ایجاد چت جدید
  Future<void> showNewChatDialog() async {
    final provider = context.read<ChatProvider>();

    // بررسی اینکه دپارتمان‌ها لود شده‌اند یا خیر
    if (provider.departments.isEmpty && !provider.departmentsLoading) {
      await provider.loadDepartments();
    }

    if (!mounted) return;

    // نمایش مودال
    await showDialog(
      context: context,
      barrierDismissible: false, // ✅ جلوگیری از بسته شدن با کلیک بیرون
      builder: (dialogContext) => NewChatModal(
        departments: provider.departments,
        onCreateChat: (title, departmentId) async {
          try {
            debugPrint("🔵 Creating new chat...");

            // ایجاد چت جدید
            final conv = await provider.startNewChat(
              title: title,
              departmentId: departmentId,
            );

            final convId = conv["id"];
            final convTitle = conv["title"] ?? "مکالمه جدید";

            debugPrint("✅ Chat created: $convId");

            // ✅ اول مودال رو ببند (از dialogContext استفاده کن)
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }

            // ✅ رفرش لیست
            await provider.loadConversations(refresh: true);

            // ✅ بعد بره صفحه چت (از context اصلی استفاده کن)
            if (mounted) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversationId: convId,
                    title: convTitle,
                  ),
                ),
              );
            }
          } catch (e) {
            debugPrint("❌ Error creating chat: $e");

            // نمایش پیام خطا
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(content: Text('خطا در ایجاد چت: $e')),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("پشتیبانی"),
        elevation: 1,
      ),
      body: _buildBody(provider),
      floatingActionButton: FloatingActionButton(
        onPressed: showNewChatDialog,
        child: const Icon(Icons.add_comment),
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
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
          if (index == provider.conversations.length) {
            if (!provider.isLoadingMore) {
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
          final department = c["department"];

          return ListTile(
            title: Text(c["title"] ?? "بدون عنوان"),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (department != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "📁 ${department['name']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Text(c["last_message"]?["text"] ?? "بدون پیام"),
              ],
            ),
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
