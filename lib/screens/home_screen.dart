import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/note_provider.dart';
import '../providers/theme_provider.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import '../widgets/filter_drawer.dart';
import '../screens/note_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Consumer2<NoteProvider, ThemeProvider>(
      builder: (context, noteProvider, themeProvider, child) {
        final notes = noteProvider.notes;
        final pinnedNotes = noteProvider.pinnedNotes;
        
        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'Designer Notes',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            actions: [
              // 検索ボタン
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: NoteSearchDelegate(noteProvider),
                  );
                },
              ),
              // テーマ切り替えボタン
              IconButton(
                icon: Icon(themeProvider.currentThemeIcon),
                tooltip: themeProvider.currentThemeLabel,
                onPressed: themeProvider.toggleTheme,
              ),
              // フィルターボタン
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          endDrawer: FilterDrawer(),
          body: notes.isEmpty ? _buildEmptyState() : _buildNotesList(notes, pinnedNotes),
          floatingActionButton: Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _createNewNote(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('新規ノート'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.design_services_outlined,
            size: 120,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'まだノートがありません',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'デザインのアイデアやインスピレーションを\n記録してみましょう',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => _createNewNote(context),
            icon: const Icon(Icons.add),
            label: const Text('最初のノートを作成'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<Note> notes, List<Note> pinnedNotes) {
    return CustomScrollView(
      slivers: [
        // ピン留めされたノート
        if (pinnedNotes.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.push_pin,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ピン留め',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: _getGridDelegate(context),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return NoteCard(
                    note: pinnedNotes[index],
                    onTap: () => _openNoteEditor(context, pinnedNotes[index]),
                  );
                },
                childCount: pinnedNotes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Divider(height: 32),
          ),
        ],
        
        // 通常のノート
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'すべてのノート',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                Text(
                  '${notes.length}件',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverGrid(
            gridDelegate: _getGridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return NoteCard(
                  note: notes[index],
                  onTap: () => _openNoteEditor(context, notes[index]),
                );
              },
              childCount: notes.length,
            ),
          ),
        ),
        
        // 下部の余白
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  SliverGridDelegate _getGridDelegate(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    
    if (screenWidth > 1200) {
      crossAxisCount = 4;
    } else if (screenWidth > 800) {
      crossAxisCount = 3;
    } else if (screenWidth > 600) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 1;
    }
    
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 0.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
    );
  }

  Future<void> _createNewNote(BuildContext context) async {
    final noteProvider = Provider.of<NoteProvider>(context, listen: false);
    final newNote = await noteProvider.createNote();
    
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoteEditorScreen(noteId: newNote.id),
        ),
      );
    }
  }

  void _openNoteEditor(BuildContext context, Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(noteId: note.id),
      ),
    );
  }
}

// 検索デリゲート
class NoteSearchDelegate extends SearchDelegate<Note?> {
  final NoteProvider noteProvider;

  NoteSearchDelegate(this.noteProvider);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final searchResults = noteProvider.allNotes.where((note) {
      final searchQuery = query.toLowerCase();
      return note.title.toLowerCase().contains(searchQuery) ||
             note.preview.toLowerCase().contains(searchQuery) ||
             note.tags.any((tag) => tag.toLowerCase().contains(searchQuery));
    }).toList();

    if (searchResults.isEmpty) {
      return const Center(
        child: Text('該当するノートが見つかりません'),
      );
    }

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final note = searchResults[index];
        return ListTile(
          title: Text(note.title),
          subtitle: Text(
            note.preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          leading: note.colorPalette.isNotEmpty
              ? CircleAvatar(
                  backgroundColor: note.colors.first,
                  child: const Icon(Icons.note_alt, color: Colors.white),
                )
              : const CircleAvatar(
                  child: Icon(Icons.note_alt),
                ),
          onTap: () {
            close(context, note);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(noteId: note.id),
              ),
            );
          },
        );
      },
    );
  }
} 