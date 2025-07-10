// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Note _$NoteFromJson(Map<String, dynamic> json) => Note(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  category: json['category'] as String? ?? '',
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  colorPalette:
      (json['colorPalette'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  attachedImages:
      (json['attachedImages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  isFavorite: json['isFavorite'] as bool? ?? false,
  isPinned: json['isPinned'] as bool? ?? false,
);

Map<String, dynamic> _$NoteToJson(Note instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'category': instance.category,
  'tags': instance.tags,
  'colorPalette': instance.colorPalette,
  'attachedImages': instance.attachedImages,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'isFavorite': instance.isFavorite,
  'isPinned': instance.isPinned,
};
