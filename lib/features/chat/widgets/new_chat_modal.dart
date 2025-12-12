import 'package:bargam_app/features/chat/presentation/models/department.dart';
import 'package:flutter/material.dart';

class NewChatModal extends StatefulWidget {
  final List<Department> departments;
  final Function(String title, int departmentId) onCreateChat;

  const NewChatModal({
    Key? key,
    required this.departments,
    required this.onCreateChat,
  }) : super(key: key);

  @override
  State<NewChatModal> createState() => _NewChatModalState();
}

class _NewChatModalState extends State<NewChatModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  int? _selectedDepartmentId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.departments.isNotEmpty) {
      _selectedDepartmentId = widget.departments.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedDepartmentId == null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ✅ فقط callback رو صدا بزن، مدیریت Navigator توی parent هست
      await widget.onCreateChat(
        _titleController.text.trim(),
        _selectedDepartmentId!,
      );

      // ⚠️ دیگه اینجا pop نمیکنیم! چون parent خودش مدیریت میکنه

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ایجاد گفتگو: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'شروع گفتگوی جدید',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'عنوان گفتگو',
                  hintText: 'مثال: مشکل در ورود به حساب کاربری',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLength: 100,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'لطفاً عنوان گفتگو را وارد کنید';
                  }
                  if (value.trim().length < 3) {
                    return 'عنوان باید حداقل ۳ کاراکتر باشد';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'دپارتمان مورد نظر:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: widget.departments.isEmpty
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('دپارتمانی یافت نشد'),
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.departments.length,
                  separatorBuilder: (context, index) =>
                  const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final dept = widget.departments[index];
                    return RadioListTile<int>(
                      value: dept.id,
                      groupValue: _selectedDepartmentId,
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                        });
                      },
                      title: Text(
                        dept.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      secondary: Icon(
                        _getDepartmentIcon(dept.name),
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('انصراف'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleSubmit,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isLoading ? 'در حال ایجاد...' : 'شروع گفتگو'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDepartmentIcon(String name) {
    switch (name.toLowerCase()) {
      case 'فنی':
        return Icons.build;
      case 'فروش':
        return Icons.shopping_cart;
      case 'مالی':
        return Icons.account_balance_wallet;
      case 'عمومی':
        return Icons.help_outline;
      default:
        return Icons.folder_outlined;
    }
  }
}
