import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分（タイトルとアクションボタン）
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? '無題のノート' : note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onSelected: (value) => _handleMenuAction(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Row(
                          children: [
                            Icon(
                              note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isPinned ? 'ピン留めを外す' : 'ピン留め'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              note.isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(note.isFavorite ? 'お気に入りを外す' : 'お気に入りに追加'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('削除', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // プレビューテキスト
              Expanded(
                child: Text(
                  note.preview.isEmpty ? 'コンテンツなし' : note.preview,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // カラーパレット
              if (note.colorPalette.isNotEmpty) ...[
                SizedBox(
                  height: 20,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: note.colorPalette.take(5).length,
                    separatorBuilder: (context, index) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final color = note.colors[index];
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.3),
                            width: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // 下部情報（カテゴリ、日付、アイコン）
              Row(
                children: [
                  // カテゴリ
                  if (note.category.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  // タグ数
                  if (note.tags.isNotEmpty) ...[
                    Icon(
                      Icons.local_offer_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${note.tags.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  
                  const Spacer(),
                  
                  // アイコン
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.attachedImages.isNotEmpty) ...[
                        Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (note.isFavorite) ...[
                        Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (note.isPinned) ...[
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 更新日時
              Text(
                '更新: ${_formatDate(note.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    
    switch (action) {
      case 'pin':
        noteProvider.togglePin(note.id);
        break;
      case 'favorite':
        noteProvider.toggleFavorite(note.id);
        break;
      case 'delete':
        _showDeleteDialog(context, noteProvider);
        break;
    }
  }

  void _showDeleteDialog(BuildContext context, NoteProvider noteProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ノートを削除'),
        content: Text('「${note.title.isEmpty ? '無題のノート' : note.title}」を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              noteProvider.deleteNote(note.id);
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      return '昨日';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return DateFormat('MM/dd').format(date);
    }
  }
} 