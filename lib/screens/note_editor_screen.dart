import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/note.dart';
import '../providers/note_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final String noteId;

  const NoteEditorScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late QuillController _quillController;
  late TextEditingController _titleController;
  late Note _note;
  late NoteProvider _noteProvider;
  
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _editorFocusNode = FocusNode();
  
  // カテゴリ・タグ編集用
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  final TextEditingController _tagController = TextEditingController();
  
  // 画像管理用
  List<String> _attachedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  // カラーパレット用
  List<String> _colorPalette = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    
    // エディターの変更を監視
    _quillController.addListener(_onContentChanged);
    _titleController.addListener(_onTitleChanged);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
    });
  }

  @override
  void dispose() {
    _quillController.removeListener(_onContentChanged);
    _titleController.removeListener(_onTitleChanged);
    _quillController.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _loadNote() {
    _noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = _noteProvider.getNoteById(widget.noteId);
    
    if (note != null) {
      setState(() {
        _note = note;
        _titleController.text = note.title;
        _selectedCategory = note.category;
        _selectedTags = List.from(note.tags);
        _attachedImages = List.from(note.attachedImages);
        _colorPalette = List.from(note.colorPalette);
        
        // コンテンツをQuillエディターに読み込み
        if (note.content.isNotEmpty) {
          try {
            final document = Document.fromJson(jsonDecode(note.content));
            _quillController = QuillController(
              document: document,
              selection: const TextSelection.collapsed(offset: 0),
            );
            _quillController.addListener(_onContentChanged);
          } catch (e) {
            // JSON解析に失敗した場合はプレーンテキストとして扱う
            _quillController.document.insert(0, note.content);
          }
        }
        
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    } else {
      // ノートが見つからない場合は戻る
      Navigator.of(context).pop();
    }
  }

  void _onTitleChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _onContentChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (!_hasUnsavedChanges) return;

    final content = jsonEncode(_quillController.document.toDelta().toJson());
    final updatedNote = _note.copyWith(
      title: _titleController.text.trim().isEmpty ? '無題のノート' : _titleController.text.trim(),
      content: content,
      category: _selectedCategory,
      tags: _selectedTags,
      attachedImages: _attachedImages,
      colorPalette: _colorPalette,
    );

    await _noteProvider.updateNote(updatedNote);
    
    setState(() {
      _note = updatedNote;
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ノートを保存しました'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('変更を保存しますか？'),
        content: const Text('保存していない変更があります。このまま戻ると変更は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('破棄'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveNote();
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('読み込み中...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasUnsavedChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // タイトル入力エリア
                _buildTitleSection(),
                
                // カテゴリ・タグ編集エリア
                _buildMetadataSection(),
                
                // 画像管理エリア
                _buildImagesSection(),
                
                // カラーパレットエリア
                _buildColorPaletteSection(),
                
                // ツールバー
                _buildToolbar(),
                
                // エディターエリア
                Expanded(
                  child: _buildEditorSection(),
                ),
                
                // 下部情報バー
                _buildBottomInfoBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_note.title.isEmpty ? '無題のノート' : _note.title),
      actions: [
        // お気に入りボタン
        IconButton(
          icon: Icon(_note.isFavorite ? Icons.favorite : Icons.favorite_border),
          onPressed: () {
            _noteProvider.toggleFavorite(_note.id);
            setState(() {
              _note = _note.copyWith(isFavorite: !_note.isFavorite);
            });
          },
        ),
        
        // ピン留めボタン
        IconButton(
          icon: Icon(_note.isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () {
            _noteProvider.togglePin(_note.id);
            setState(() {
              _note = _note.copyWith(isPinned: !_note.isPinned);
            });
          },
        ),
        
        // 保存ボタン
        IconButton(
          icon: Icon(
            Icons.save,
            color: _hasUnsavedChanges 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: _hasUnsavedChanges ? _saveNote : null,
        ),
        
        // メニューボタン
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.share, size: 18),
                  SizedBox(width: 8),
                  Text('エクスポート'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 18),
                  SizedBox(width: 8),
                  Text('複製'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('削除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: TextField(
        controller: _titleController,
        focusNode: _titleFocusNode,
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: InputDecoration(
          hintText: 'ノートのタイトル',
          hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => _editorFocusNode.requestFocus(),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: QuillSimpleToolbar(
        controller: _quillController,
        config: QuillSimpleToolbarConfig(
          multiRowsDisplay: false,
          showDividers: false,
          showFontFamily: false,
          showFontSize: false,
          showBoldButton: true,
          showItalicButton: true,
          showUnderLineButton: true,
          showStrikeThrough: true,
          showColorButton: true,
          showBackgroundColorButton: true,
          showClearFormat: true,
          showAlignmentButtons: true,
          showLeftAlignment: true,
          showCenterAlignment: true,
          showRightAlignment: true,
          showJustifyAlignment: true,
          showHeaderStyle: true,
          showListNumbers: true,
          showListBullets: true,
          showListCheck: true,
          showCodeBlock: true,
          showQuote: true,
          showIndent: true,
          showLink: true,
          showUndo: true,
          showRedo: true,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildEditorSection() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: QuillEditor.basic(
        controller: _quillController,
        focusNode: _editorFocusNode,
        config: QuillEditorConfig(
          placeholder: 'ここに入力してください...',
          padding: const EdgeInsets.all(16),
          autoFocus: false,
          expands: true,
          textSelectionThemeData: TextSelectionThemeData(
            cursorColor: Theme.of(context).colorScheme.primary,
            selectionColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            selectionHandleColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリ選択
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'カテゴリ:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 未選択チップ
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: const Text('未選択'),
                          selected: _selectedCategory.isEmpty,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = '';
                                _hasUnsavedChanges = true;
                              });
                            }
                          },
                        ),
                      ),
                      // カテゴリチップ
                      ..._noteProvider.categories.map((category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : '';
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // タグ選択
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.label_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'タグ:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 選択されたタグ
                    if (_selectedTags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedTags.map((tag) => Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                              _hasUnsavedChanges = true;
                            });
                          },
                          deleteIcon: const Icon(Icons.close, size: 18),
                        )).toList(),
                      ),
                    const SizedBox(height: 8),
                    // タグ入力フィールド
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tagController,
                            decoration: InputDecoration(
                              hintText: '新しいタグを追加',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: _addTag,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _addTag(_tagController.text),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                      ],
                    ),
                    // 既存タグの候補
                    if (_noteProvider.allTags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _noteProvider.allTags
                            .where((tag) => !_selectedTags.contains(tag))
                            .map((tag) => ActionChip(
                              label: Text(tag),
                              onPressed: () {
                                setState(() {
                                  _selectedTags.add(tag);
                                  _hasUnsavedChanges = true;
                                });
                              },
                            )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim();
    if (trimmedTag.isNotEmpty && !_selectedTags.contains(trimmedTag)) {
      setState(() {
        _selectedTags.add(trimmedTag);
        _tagController.clear();
        _hasUnsavedChanges = true;
      });
    }
  }

  Widget _buildImagesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '添付画像:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate, size: 20),
                label: const Text('画像を追加'),
              ),
            ],
          ),
          if (_attachedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _attachedImages.length,
                itemBuilder: (context, index) {
                  return _buildImageItem(_attachedImages[index], index);
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  style: BorderStyle.solid,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '画像を追加してください',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageItem(String imagePath, int index) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb 
              ? Image.network(
                  imagePath,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    );
                  },
                )
              : Image.file(
                  File(imagePath),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 40),
                      ),
                    );
                  },
                ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                onPressed: () => _removeImage(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _attachedImages.add(image.path);
          _hasUnsavedChanges = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('画像の追加に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
      _hasUnsavedChanges = true;
    });
  }

  Widget _buildColorPaletteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'カラーパレット:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showColorPicker,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('色を追加'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._colorPalette.map((colorHex) {
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                return Stack(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () => _removeColor(colorHex),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
              if (_colorPalette.isEmpty)
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'カラーパレットが空です',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorPicker() {
    Color pickerColor = Theme.of(context).colorScheme.primary;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選択'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (Color color) {
              pickerColor = color;
            },
            labelTypes: const [],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final hexColor = '#${pickerColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              if (!_colorPalette.contains(hexColor)) {
                setState(() {
                  _colorPalette.add(hexColor);
                  _hasUnsavedChanges = true;
                });
              }
              Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _removeColor(String colorHex) {
    setState(() {
      _colorPalette.remove(colorHex);
      _hasUnsavedChanges = true;
    });
  }

  Widget _buildBottomInfoBar() {
    final wordCount = _quillController.document.toPlainText().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    final charCount = _quillController.document.toPlainText().length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasUnsavedChanges ? Icons.edit : Icons.check_circle,
            size: 16,
            color: _hasUnsavedChanges 
                ? Theme.of(context).colorScheme.primary
                : Colors.green,
          ),
          const SizedBox(width: 8),
          Text(
            _hasUnsavedChanges ? '編集中' : '保存済み',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            '$wordCount語 • $charCount文字',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _showExportDialog();
        break;
      case 'duplicate':
        _duplicateNote();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エクスポート'),
        content: const Text('この機能は今後実装予定です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _duplicateNote() async {
    final content = jsonEncode(_quillController.document.toDelta().toJson());
    await _noteProvider.createNote(
      title: '${_titleController.text.trim()} のコピー',
      content: content,
      category: _note.category,
      tags: _note.tags,
      colorPalette: _note.colorPalette,
      attachedImages: _note.attachedImages,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ノートを複製しました'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ノートを削除'),
        content: const Text('このノートを削除しますか？この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _noteProvider.deleteNote(_note.id);
              if (mounted) {
                Navigator.of(context)
                  ..pop() // ダイアログを閉じる
                  ..pop(); // エディター画面を閉じる
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
} 