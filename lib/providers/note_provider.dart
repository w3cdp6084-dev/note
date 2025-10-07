import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

import '../models/note.dart';

class NoteProvider extends ChangeNotifier {
  static const String _notesKey = 'notes';
  static const String _categoriesKey = 'categories';
  
  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();
  
  List<Note> _notes = [];
  List<String> _categories = ['デザイン', 'アイデア', 'プロジェクト', 'インスピレーション'];
  String _searchQuery = '';
  String _selectedCategory = '';
  List<String> _selectedTags = [];
  bool _showFavoritesOnly = false;

  NoteProvider(this._prefs) {
    _loadData();
  }

  // Getters
  List<Note> get notes => _filteredNotes();
  List<Note> get allNotes => _notes;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  List<String> get selectedTags => _selectedTags;
  bool get showFavoritesOnly => _showFavoritesOnly;

  // 全てのタグを取得
  List<String> get allTags {
    final tags = <String>{};
    for (final note in _notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  // ピン留めされたノート
  List<Note> get pinnedNotes => _notes.where((note) => note.isPinned).toList();

  // お気に入りのノート
  List<Note> get favoriteNotes => _notes.where((note) => note.isFavorite).toList();

  void _loadData() {
    _loadNotes();
    _loadCategories();
  }

  void _loadNotes() {
    final notesJson = _prefs.getStringList(_notesKey) ?? [];
    _notes = notesJson
        .map((json) => Note.fromJson(jsonDecode(json)))
        .toList();
    
    // 作成日順（新しい順）でソート
    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _loadCategories() {
    final savedCategories = _prefs.getStringList(_categoriesKey);
    if (savedCategories != null) {
      _categories = savedCategories;
    }
  }

  Future<void> _saveNotes() async {
    final notesJson = _notes.map((note) => jsonEncode(note.toJson())).toList();
    await _prefs.setStringList(_notesKey, notesJson);
  }

  Future<void> _saveCategories() async {
    await _prefs.setStringList(_categoriesKey, _categories);
  }

  // ノートの作成
  Future<Note> createNote({
    String title = '新しいノート',
    String content = '',
    String category = '',
    List<String> tags = const [],
    List<String> colorPalette = const [],
    List<String> attachedImages = const [],
  }) async {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: title,
      content: content,
      category: category,
      tags: tags,
      colorPalette: colorPalette,
      attachedImages: attachedImages,
      createdAt: now,
      updatedAt: now,
    );

    _notes.insert(0, note); // 先頭に追加
    await _saveNotes();
    notifyListeners();
    return note;
  }

  // ノートの更新
  Future<void> updateNote(Note updatedNote) async {
    final index = _notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      _notes[index] = updatedNote.copyWith(updatedAt: DateTime.now());
      await _saveNotes();
      notifyListeners();
    }
  }

  // ノートの削除
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    await _saveNotes();
    notifyListeners();
  }

  // お気に入りの切り替え
  Future<void> toggleFavorite(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        isFavorite: !_notes[index].isFavorite,
        updatedAt: DateTime.now(),
      );
      await _saveNotes();
      notifyListeners();
    }
  }

  // ピン留めの切り替え
  Future<void> togglePin(String noteId) async {
    final index = _notes.indexWhere((note) => note.id == noteId);
    if (index != -1) {
      _notes[index] = _notes[index].copyWith(
        isPinned: !_notes[index].isPinned,
        updatedAt: DateTime.now(),
      );
      await _saveNotes();
      notifyListeners();
    }
  }

  // カテゴリの追加
  Future<void> addCategory(String category) async {
    if (!_categories.contains(category)) {
      _categories.add(category);
      await _saveCategories();
      notifyListeners();
    }
  }

  // カテゴリの削除
  Future<void> removeCategory(String category) async {
    _categories.remove(category);
    // このカテゴリを使用しているノートのカテゴリをクリア
    for (int i = 0; i < _notes.length; i++) {
      if (_notes[i].category == category) {
        _notes[i] = _notes[i].copyWith(category: '');
      }
    }
    await _saveCategories();
    await _saveNotes();
    notifyListeners();
  }

  // 検索・フィルタリング
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedTags(List<String> tags) {
    _selectedTags = tags;
    notifyListeners();
  }

  void toggleShowFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedTags = [];
    _showFavoritesOnly = false;
    notifyListeners();
  }

  // フィルタリングされたノートを取得
  List<Note> _filteredNotes() {
    var filtered = List<Note>.from(_notes);

    // お気に入りフィルタ
    if (_showFavoritesOnly) {
      filtered = filtered.where((note) => note.isFavorite).toList();
    }

    // カテゴリフィルタ
    if (_selectedCategory.isNotEmpty) {
      filtered = filtered.where((note) => note.category == _selectedCategory).toList();
    }

    // タグフィルタ
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((note) {
        return _selectedTags.every((tag) => note.tags.contains(tag));
      }).toList();
    }

    // 検索クエリフィルタ
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((note) {
        final query = _searchQuery.toLowerCase();
        return note.title.toLowerCase().contains(query) ||
               note.preview.toLowerCase().contains(query) ||
               note.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  // ノートをIDで取得
  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((note) => note.id == id);
    } catch (e) {
      return null;
    }
  }
} 