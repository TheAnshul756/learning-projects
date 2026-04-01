import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/video.dart';
import '../services/youtube_service.dart';
import '../widgets/video_card.dart';
import 'watch_screen.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final _videos = <Video>[];
  String? _nextPageToken;
  bool _searching = false;
  bool _loadingMore = false;
  String? _lastQuery;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _scrollController.addListener(_onScroll);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;
    _focusNode.unfocus();

    setState(() {
      _searching = true;
      _error = null;
      _videos.clear();
      _nextPageToken = null;
      _lastQuery = query;
    });

    try {
      final result = await context.read<YouTubeService>().search(query);
      if (mounted) {
        setState(() {
          _videos.addAll(result.videos);
          _nextPageToken = result.nextPageToken;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextPageToken == null || _lastQuery == null) return;
    setState(() => _loadingMore = true);

    try {
      final result = await context
          .read<YouTubeService>()
          .search(_lastQuery!, pageToken: _nextPageToken);
      if (mounted) {
        setState(() {
          _videos.addAll(result.videos);
          _nextPageToken = result.nextPageToken;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _openVideo(Video v) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WatchScreen(videoId: v.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(color: kTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search videos…',
              hintStyle: const TextStyle(color: kTextSecondary),
              prefixIcon: const Icon(Icons.search, color: kTextSecondary, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: kTextSecondary, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_searching && _videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _videos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: kTextSecondary, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: kTextSecondary)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _search, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_lastQuery == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, color: kTextSecondary, size: 56),
            SizedBox(height: 12),
            Text('Search for any topic', style: TextStyle(color: kTextSecondary, fontSize: 15)),
            SizedBox(height: 4),
            Text('No recommendations, no Shorts',
                style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
          ],
        ),
      );
    }

    if (_videos.isEmpty && !_searching) {
      return Center(
        child: Text(
          'No results for "$_lastQuery"',
          style: const TextStyle(color: kTextSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _gridColumns(constraints.maxWidth);
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                  mainAxisExtent: _cardHeight(constraints.maxWidth, columns),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => VideoCard(
                    video: _videos[index],
                    onTap: () => _openVideo(_videos[index]),
                  ),
                  childCount: _videos.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _loadingMore
                    ? const Center(child: CircularProgressIndicator())
                    : _nextPageToken != null
                        ? Center(
                            child: OutlinedButton(
                              onPressed: _loadMore,
                              child: const Text('Load more'),
                            ),
                          )
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
    );
  }

  int _gridColumns(double width) {
    if (width >= 1200) return 4;
    if (width >= 800) return 3;
    if (width >= 500) return 2;
    return 1;
  }

  double _cardHeight(double availableWidth, int columns) {
    final cardWidth = (availableWidth - 24 - (columns - 1) * 12) / columns;
    return cardWidth * 9 / 16 + 90;
  }
}
