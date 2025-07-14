import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../models/note.dart';
import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';

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
  FocusNode _titleFocusNode = FocusNode();
  FocusNode _editorFocusNode = FocusNode();

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
    super.dispose();
  }

  void _loadNote() {
    _noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final note = _noteProvider.getNoteById(widget.noteId);
    
    if (note != null) {
      setState(() {
        _note = note;
        _titleController.text = note.title;
        
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
        body: Column(
          children: [
            // タイトル入力エリア
            _buildTitleSection(),
            
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