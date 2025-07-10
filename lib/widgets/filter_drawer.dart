import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/note_provider.dart';

class FilterDrawer extends StatelessWidget {
  const FilterDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          return Column(
            children: [
              // ドロワーヘッダー
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'フィルター',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ノートを条件で絞り込み',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // 検索セクション
                    _buildSearchSection(context, noteProvider),
                    
                    const Divider(height: 32),
                    
                    // お気に入りセクション
                    _buildFavoriteSection(context, noteProvider),
                    
                    const Divider(height: 32),
                    
                    // カテゴリセクション
                    _buildCategorySection(context, noteProvider),
                    
                    const Divider(height: 32),
                    
                    // タグセクション
                    _buildTagSection(context, noteProvider),
                    
                    const Divider(height: 32),
                    
                    // 統計セクション
                    _buildStatsSection(context, noteProvider),
                  ],
                ),
              ),
              
              // フィルタークリアボタン
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: noteProvider.searchQuery.isNotEmpty ||
                            noteProvider.selectedCategory.isNotEmpty ||
                            noteProvider.selectedTags.isNotEmpty ||
                            noteProvider.showFavoritesOnly
                        ? () {
                            noteProvider.clearFilters();
                            Navigator.of(context).pop();
                          }
                        : null,
                    icon: const Icon(Icons.clear_all),
                    label: const Text('フィルターをクリア'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchSection(BuildContext context, NoteProvider noteProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '検索',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'ノートを検索...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: noteProvider.setSearchQuery,
            controller: TextEditingController(text: noteProvider.searchQuery),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteSection(BuildContext context, NoteProvider noteProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'お気に入り',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SwitchListTile(
            title: const Text('お気に入りのみ表示'),
            subtitle: Text(
              noteProvider.showFavoritesOnly
                  ? '${noteProvider.favoriteNotes.length}件のお気に入り'
                  : 'すべてのノートを表示',
            ),
            value: noteProvider.showFavoritesOnly,
            onChanged: (value) => noteProvider.toggleShowFavoritesOnly(),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, NoteProvider noteProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'カテゴリ',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showAddCategoryDialog(context, noteProvider),
                child: const Text('追加'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 全てカテゴリ
              FilterChip(
                label: const Text('すべて'),
                selected: noteProvider.selectedCategory.isEmpty,
                onSelected: (selected) {
                  if (selected) {
                    noteProvider.setSelectedCategory('');
                  }
                },
              ),
              // 各カテゴリ
              ...noteProvider.categories.map((category) {
                final notesInCategory = noteProvider.allNotes
                    .where((note) => note.category == category)
                    .length;
                
                return FilterChip(
                  label: Text('$category ($notesInCategory)'),
                  selected: noteProvider.selectedCategory == category,
                  onSelected: (selected) {
                    noteProvider.setSelectedCategory(selected ? category : '');
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection(BuildContext context, NoteProvider noteProvider) {
    final allTags = noteProvider.allTags;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'タグ',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (allTags.isEmpty)
            Text(
              'タグが設定されたノートがありません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allTags.map((tag) {
                final isSelected = noteProvider.selectedTags.contains(tag);
                final notesWithTag = noteProvider.allNotes
                    .where((note) => note.tags.contains(tag))
                    .length;
                
                return FilterChip(
                  label: Text('$tag ($notesWithTag)'),
                  selected: isSelected,
                  onSelected: (selected) {
                    final newTags = List<String>.from(noteProvider.selectedTags);
                    if (selected) {
                      newTags.add(tag);
                    } else {
                      newTags.remove(tag);
                    }
                    noteProvider.setSelectedTags(newTags);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, NoteProvider noteProvider) {
    final totalNotes = noteProvider.allNotes.length;
    final favoriteNotes = noteProvider.favoriteNotes.length;
    final pinnedNotes = noteProvider.pinnedNotes.length;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '統計',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildStatRow(context, Icons.note_alt, '総ノート数', '$totalNotes件'),
                  const Divider(height: 16),
                  _buildStatRow(context, Icons.favorite, 'お気に入り', '$favoriteNotes件'),
                  const Divider(height: 16),
                  _buildStatRow(context, Icons.push_pin, 'ピン留め', '$pinnedNotes件'),
                  const Divider(height: 16),
                  _buildStatRow(context, Icons.category, 'カテゴリ', '${noteProvider.categories.length}個'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _showAddCategoryDialog(BuildContext context, NoteProvider noteProvider) {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新しいカテゴリを追加'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'カテゴリ名',
            hintText: 'カテゴリ名を入力してください',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final categoryName = controller.text.trim();
              if (categoryName.isNotEmpty) {
                noteProvider.addCategory(categoryName);
                Navigator.of(context).pop();
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
} 