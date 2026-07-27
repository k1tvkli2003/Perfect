import 'package:flutter/material.dart';
import 'package:perfect/app/personal_item.dart';
import 'package:perfect/app/personal_items_controller.dart';
import 'package:perfect/app/sync_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkspacePage extends StatelessWidget {
  const WorkspacePage({super.key, required this.controller});

  final PersonalItemsController controller;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final items = controller.items;
          return Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showAddItem(context),
              icon: const Icon(Icons.add),
              label: const Text('مورد جدید'),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: RefreshIndicator(
                    onRefresh: controller.syncNow,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 108),
                      children: [
                        _Header(controller: controller),
                        const SizedBox(height: 28),
                        if (items.isEmpty)
                          const _EmptyWorkspace()
                        else
                          ...items.map(
                            (item) => _ItemTile(
                              item: item,
                              onToggle: () => controller.toggle(item),
                              onDelete: () => controller.delete(item),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Future<void> _showAddItem(BuildContext context) async {
    final text = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('مورد جدید', textDirection: TextDirection.rtl),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLength: 160,
          textDirection: TextDirection.rtl,
          onSubmitted: (_) => Navigator.pop(dialogContext, true),
          decoration: const InputDecoration(hintText: 'چه کاری مهم است؟'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('افزودن')),
        ],
      ),
    );
    if (submitted == true) await controller.add(text.text);
    text.dispose();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final PersonalItemsController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.syncState;
    final (icon, label, color) = switch (state) {
      SyncState.syncing => (Icons.sync, 'در حال همگام‌سازی', Theme.of(context).colorScheme.primary),
      SyncState.offlineError => (Icons.cloud_off, 'ذخیره شد؛ اتصال را بررسی کن', Theme.of(context).colorScheme.error),
      SyncState.idle => (Icons.cloud_done_outlined, 'میان دستگاه‌ها همگام است', Theme.of(context).colorScheme.primary),
    };
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Perfect', style: Theme.of(context).textTheme.displaySmall)),
              IconButton(
                tooltip: 'خروج',
                onPressed: () => Supabase.instance.client.auth.signOut(),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${controller.completedCount} از ${controller.items.length} مورد انجام شده'),
          const SizedBox(height: 14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: controller.syncNow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 7),
                  Text(label, style: TextStyle(color: color)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onToggle, required this.onDelete});

  final PersonalItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Checkbox(value: item.isDone, onChanged: (_) => onToggle()),
          title: Text(
            item.title,
            textDirection: TextDirection.rtl,
            style: item.isDone ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
          ),
          trailing: IconButton(
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
          onTap: onToggle,
        ),
      );
}

class _EmptyWorkspace extends StatelessWidget {
  const _EmptyWorkspace();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 88),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 68, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('از اینجا شروع کن.', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('هر تغییری با همان حساب روی دستگاه‌های دیگر هم می‌نشیند.'),
            ],
          ),
        ),
      );
}
