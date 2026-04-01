import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/video.dart';
import '../services/auth_service.dart';
import '../services/youtube_service.dart';
import '../widgets/video_card.dart';
import 'search_screen.dart';
import 'watch_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _videos = <Video>[];
  String? _nextSubPageToken;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      if (refresh) {
        _videos.clear();
        _nextSubPageToken = null;
      }
    });

    try {
      final yt = context.read<YouTubeService>();
      final result = await yt.getFeed(subPageToken: refresh ? null : null);
      if (mounted) {
        setState(() {
          _videos.addAll(result.videos);
          _nextSubPageToken = result.nextSubPageToken;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextSubPageToken == null) return;
    setState(() => _loadingMore = true);

    try {
      final yt = context.read<YouTubeService>();
      final result = await yt.getFeed(subPageToken: _nextSubPageToken);
      if (mounted) {
        setState(() {
          _videos.addAll(result.videos);
          _nextSubPageToken = result.nextSubPageToken;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('auth_expired') || msg.contains('401')) {
      return 'Session expired. Please sign out and sign in again.';
    }
    return 'Could not load feed. Check your connection.';
  }

  void _openVideo(Video v) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WatchScreen(videoId: v.id)),
    );
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'FocusTube',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: _openSearch,
          ),
          _ProfileMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadFeed(refresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _videos.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: kTextSecondary, size: 48),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: kTextSecondary)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadFeed, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_videos.isEmpty && !_loading) {
      return const Center(
        child: Text('No videos found. Try subscribing to some channels.',
            style: TextStyle(color: kTextSecondary)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _gridColumns(constraints.maxWidth);
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                  childAspectRatio: _cardAspectRatio(crossAxisCount),
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
                    : _nextSubPageToken != null
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

  double _cardAspectRatio(int columns) {
    // thumbnail (16:9) + ~80px info text
    // ratio = width / height; wider cards need different ratio
    if (columns == 1) return 16 / 11.5;
    return 16 / 12.5;
  }
}

class _ProfileMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final user = auth.user;

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: kSurface,
          backgroundImage: user?.photoUrl != null
              ? NetworkImage(user!.photoUrl!)
              : null,
          child: user?.photoUrl == null
              ? Text(
                  (user?.displayName ?? '?')[0].toUpperCase(),
                  style: const TextStyle(fontSize: 14, color: kTextPrimary),
                )
              : null,
        ),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'name',
          enabled: false,
          child: Text(user?.displayName ?? '', style: const TextStyle(color: kTextSecondary)),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'signout', child: Text('Sign out')),
      ],
      onSelected: (value) {
        if (value == 'signout') auth.signOut();
      },
    );
  }
}
