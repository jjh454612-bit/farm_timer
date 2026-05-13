import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();

    return Scaffold(
      backgroundColor: provider.themeColor,
      appBar: AppBar(title: const Text("⚙️ 설정")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── 테마 색상 ──
          _sectionTitle("🎨 배경 색상"),
          const SizedBox(height: 12),
          _ThemeColorPicker(current: provider.themeColor),
          const SizedBox(height: 28),

          // ── 카테고리 관리 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle("📚 카테고리"),
              TextButton.icon(
                onPressed: () => _showAddCategoryDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("추가"),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.categories.map((cat) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cat.color, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: cat.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (provider.categories.length <= 1)
                    Text("최소 1개",
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[400]))
                  else
                    GestureDetector(
                      onTap: () => _confirmDelete(context, provider, cat),
                      child: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 22),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3D5C28)),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final provider = context.read<GameProvider>();
    final nameCtrl = TextEditingController();
    Color selectedColor = GameProvider.palette[3]; // 기본: 로즈

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("카테고리 추가"),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "이름",
                  border: OutlineInputBorder(),
                ),
                maxLength: 10,
              ),
              const SizedBox(height: 12),
              const Text("색상 선택",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GameProvider.palette.map((color) {
                  final isSelected = color.toARGB32() == selectedColor.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = color),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF3D5C28)
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 18, color: Color(0xFF3D5C28))
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소"),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                provider.addCategory(name, selectedColor);
                Navigator.pop(context);
              },
              child: const Text("추가"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, GameProvider provider, StudyCategory cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("카테고리 삭제"),
        content: Text("'${cat.name}' 카테고리를 삭제할까요?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () {
              provider.removeCategory(cat.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("삭제",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── 테마 색상 피커 ──
class _ThemeColorPicker extends StatelessWidget {
  final Color current;
  const _ThemeColorPicker({required this.current});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GameProvider>();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: GameProvider.palette.map((color) {
        final isSelected = color.toARGB32() == current.toARGB32();
        return GestureDetector(
          onTap: () => provider.setThemeColor(color),
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3D5C28)
                    : Colors.grey[300]!,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check,
                    size: 20, color: Color(0xFF3D5C28))
                : null,
          ),
        );
      }).toList(),
    );
  }
}