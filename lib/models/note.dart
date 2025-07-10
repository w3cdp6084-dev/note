import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/material.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  final String id;
  final String title;
  final String content; // リッチテキストのJSON形式
  final String category;
  final List<String> tags;
  final List<String> colorPalette; // HEX色コードのリスト
  final List<String> attachedImages; // 画像ファイルのパス
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isPinned;

  const Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = '',
    this.tags = const [],
    this.colorPalette = const [],
    this.attachedImages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isPinned = false,
  });

  // JSON変換用のファクトリメソッド
  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);

  // copyWithメソッド
  Note copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    List<String>? colorPalette,
    List<String>? attachedImages,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      colorPalette: colorPalette ?? this.colorPalette,
      attachedImages: attachedImages ?? this.attachedImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  // カラーパレットをColorオブジェクトに変換
  List<Color> get colors {
    return colorPalette
        .map((hex) => Color(int.parse(hex.replaceFirst('#', '0xFF'))))
        .toList();
  }

  // プレビューテキストを取得（最初の100文字）
  String get preview {
    // リッチテキストからプレーンテキストを抽出（簡易版）
    final plainText = content
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTMLタグを除去
        .replaceAll(RegExp(r'\s+'), ' ') // 余分な空白を除去
        .trim();
    
    return plainText.length > 100 
        ? '${plainText.substring(0, 100)}...' 
        : plainText;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Note{id: $id, title: $title, category: $category, createdAt: $createdAt}';
  }
} 