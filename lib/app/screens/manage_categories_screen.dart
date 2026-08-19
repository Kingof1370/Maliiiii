import 'package:flutter/material.dart';
import 'package:maliiiii/maliiiii.dart';

import '../design/app_colors.dart';
import '../design/app_dimensions.dart';
import '../state/category_controller.dart';
import '../state/category_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_card.dart';

/// مدیریت دسته‌های سفارشی: افزودن/حذف دستهٔ هزینه و درآمد.
class ManageCategoriesScreen extends StatelessWidget {
  const ManageCategoriesScreen({super.key});

  Future<void> _addCategory(
    BuildContext context,
    CategoryController controller,
    CategoryKind kind,
  ) async {
    final TextEditingController text = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          kind == CategoryKind.expense
              ? 'دستهٔ هزینهٔ جدید'
              : 'دستهٔ درآمد جدید',
        ),
        content: TextField(
          key: const Key('manage-category-name'),
          controller: text,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام دسته'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            key: const Key('manage-category-save'),
            onPressed: () => Navigator.pop(dialogContext, text.text.trim()),
            child: const Text('افزودن'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await controller.add(
        id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        kind: kind,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CategoryController controller = CategoryScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('دسته‌های سفارشی')),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        children: <Widget>[
          _CategorySection(
            title: 'دسته‌های هزینه',
            items: controller.expense,
            addKey: const Key('add-cat-expense'),
            onAdd: () => _addCategory(context, controller, CategoryKind.expense),
            onDelete: (UserCategory item) => controller.delete(item.id),
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          _CategorySection(
            title: 'دسته‌های درآمد',
            items: controller.income,
            addKey: const Key('add-cat-income'),
            onAdd: () => _addCategory(context, controller, CategoryKind.income),
            onDelete: (UserCategory item) => controller.delete(item.id),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.items,
    required this.addKey,
    required this.onAdd,
    required this.onDelete,
  });

  final String title;
  final List<UserCategory> items;
  final Key addKey;
  final VoidCallback onAdd;
  final void Function(UserCategory item) onDelete;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = context.appPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const Spacer(),
            IconButton.filledTonal(
              key: addKey,
              tooltip: 'افزودن',
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 20),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spaceSm),
        if (items.isEmpty)
          PremiumCard(
            elevation: PremiumElevation.flat,
            child: Text(
              'دسته‌ای تعریف نشده است.',
              style: TextStyle(color: palette.textMuted, fontSize: 13),
            ),
          )
        else
          for (final UserCategory item in items)
            PremiumCard(
              elevation: PremiumElevation.flat,
              child: Row(
                children: <Widget>[
                  Icon(Icons.label_outline_rounded,
                      color: palette.primary, size: 20),
                  const SizedBox(width: AppDimensions.spaceSm + 4),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    key: Key('cat-delete-${item.id}'),
                    tooltip: 'حذف',
                    onPressed: () => onDelete(item),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: palette.danger, size: 20),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
