import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/video.dart';
import '../models/comment.dart';
import '../services/youtube_service.dart';
import '../widgets/comment_card.dart';
import 'search_screen.dart';

class WatchScreen extends StatefulWidget {
  final String videoId;
  const WatchScreen({super.key, required this.videoId});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  late final YoutubePlayerController _playerController;

  Video? _video;
  Map<String, dynamic>? _channel;
  bool _loadingVideo = true;
  String? _videoError;

  final _comments = <Comment>[];
  String? _nextCommentToken;
  bool _loadingComments = false;
  bool _commentsDisabled = false;
  bool _commentsLoaded = false;

  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _playerController = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        playsInline: true,
        privacyEnhancedMode: true, // uses youtube-nocookie.com
        rel: false,                // limit related videos to same channel
        showVideoAnnotations: false,
        mute: false,
      ),
    );
    _playerController.loadVideoById(videoId: widget.videoId);
    _loadVideo();
  }

  @override
  void dispose() {
    _playerController.close();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    try {
      final yt = context.read<YouTubeService>();
      final video = await yt.getVideoDetails(widget.videoId);
      final channel = await yt.getChannel(video.channelId);
      if (mounted) {
        setState(() {
          _video = video;
          _channel = channel;
          _loadingVideo = false;
        });
        _loadComments();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = 'Could not load video details.';
          _loadingVideo = false;
        });
      }
    }
  }

  Future<void> _loadComments({bool more = false}) async {
    if (_loadingComments) return;
    setState(() => _loadingComments = true);

    try {
      final yt = context.read<YouTubeService>();
      final result = await yt.getComments(
        widget.videoId,
        pageToken: more ? _nextCommentToken : null,
      );
      if (mounted) {
        setState(() {
          if (!more) _comments.clear();
          _comments.addAll(result.comments);
          _nextCommentToken = result.nextPageToken;
          _commentsDisabled = result.disabled;
          _commentsLoaded = true;
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return YoutubePlayerScaffold(
      controller: _playerController,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('FocusTube'),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: _openSearch),
              const SizedBox(width: 4),
            ],
          ),
          body: isWide
              ? _WideLayout(
                  player: player,
                  video: _video,
                  channel: _channel,
                  loading: _loadingVideo,
                  error: _videoError,
                  comments: _comments,
                  commentsDisabled: _commentsDisabled,
                  commentsLoaded: _commentsLoaded,
                  loadingComments: _loadingComments,
                  nextCommentToken: _nextCommentToken,
                  descriptionExpanded: _descriptionExpanded,
                  onToggleDescription: () =>
                      setState(() => _descriptionExpanded = !_descriptionExpanded),
                  onLoadMoreComments: () => _loadComments(more: true),
                )
              : _NarrowLayout(
                  player: player,
                  video: _video,
                  channel: _channel,
                  loading: _loadingVideo,
                  error: _videoError,
                  comments: _comments,
                  commentsDisabled: _commentsDisabled,
                  commentsLoaded: _commentsLoaded,
                  loadingComments: _loadingComments,
                  nextCommentToken: _nextCommentToken,
                  descriptionExpanded: _descriptionExpanded,
                  onToggleDescription: () =>
                      setState(() => _descriptionExpanded = !_descriptionExpanded),
                  onLoadMoreComments: () => _loadComments(more: true),
                ),
        );
      },
    );
  }
}

// ─── Narrow (phone) layout: player + content stacked vertically ───────────────

class _NarrowLayout extends StatelessWidget {
  final Widget player;
  final Video? video;
  final Map<String, dynamic>? channel;
  final bool loading;
  final String? error;
  final List<Comment> comments;
  final bool commentsDisabled;
  final bool commentsLoaded;
  final bool loadingComments;
  final String? nextCommentToken;
  final bool descriptionExpanded;
  final VoidCallback onToggleDescription;
  final VoidCallback onLoadMoreComments;

  const _NarrowLayout({
    required this.player,
    required this.video,
    required this.channel,
    required this.loading,
    required this.error,
    required this.comments,
    required this.commentsDisabled,
    required this.commentsLoaded,
    required this.loadingComments,
    required this.nextCommentToken,
    required this.descriptionExpanded,
    required this.onToggleDescription,
    required this.onLoadMoreComments,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        player,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _VideoContent(
              video: video,
              channel: channel,
              loading: loading,
              error: error,
              comments: comments,
              commentsDisabled: commentsDisabled,
              commentsLoaded: commentsLoaded,
              loadingComments: loadingComments,
              nextCommentToken: nextCommentToken,
              descriptionExpanded: descriptionExpanded,
              onToggleDescription: onToggleDescription,
              onLoadMoreComments: onLoadMoreComments,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wide (tablet / web) layout: player left, content right ─────────────────

class _WideLayout extends StatelessWidget {
  final Widget player;
  final Video? video;
  final Map<String, dynamic>? channel;
  final bool loading;
  final String? error;
  final List<Comment> comments;
  final bool commentsDisabled;
  final bool commentsLoaded;
  final bool loadingComments;
  final String? nextCommentToken;
  final bool descriptionExpanded;
  final VoidCallback onToggleDescription;
  final VoidCallback onLoadMoreComments;

  const _WideLayout({
    required this.player,
    required this.video,
    required this.channel,
    required this.loading,
    required this.error,
    required this.comments,
    required this.commentsDisabled,
    required this.commentsLoaded,
    required this.loadingComments,
    required this.nextCommentToken,
    required this.descriptionExpanded,
    required this.onToggleDescription,
    required this.onLoadMoreComments,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player + content column (takes ~70% of width)
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,
                const SizedBox(height: 16),
                _VideoContent(
                  video: video,
                  channel: channel,
                  loading: loading,
                  error: error,
                  comments: comments,
                  commentsDisabled: commentsDisabled,
                  commentsLoaded: commentsLoaded,
                  loadingComments: loadingComments,
                  nextCommentToken: nextCommentToken,
                  descriptionExpanded: descriptionExpanded,
                  onToggleDescription: onToggleDescription,
                  onLoadMoreComments: onLoadMoreComments,
                ),
              ],
            ),
          ),
        ),
        // No recommendations sidebar — intentionally empty to eliminate distraction
        const SizedBox(width: 12),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.28,
          child: const Padding(
            padding: EdgeInsets.only(top: 16, right: 16),
            child: _NoRecommendationsBanner(),
          ),
        ),
      ],
    );
  }
}

class _NoRecommendationsBanner extends StatelessWidget {
  const _NoRecommendationsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.block, color: kAccent, size: 32),
          SizedBox(height: 12),
          Text(
            'No recommendations',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'FocusTube keeps this space empty so you stay focused on what you chose to watch.',
            style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Video metadata + description + comments ─────────────────────────────────

class _VideoContent extends StatelessWidget {
  final Video? video;
  final Map<String, dynamic>? channel;
  final bool loading;
  final String? error;
  final List<Comment> comments;
  final bool commentsDisabled;
  final bool commentsLoaded;
  final bool loadingComments;
  final String? nextCommentToken;
  final bool descriptionExpanded;
  final VoidCallback onToggleDescription;
  final VoidCallback onLoadMoreComments;

  const _VideoContent({
    required this.video,
    required this.channel,
    required this.loading,
    required this.error,
    required this.comments,
    required this.commentsDisabled,
    required this.commentsLoaded,
    required this.loadingComments,
    required this.nextCommentToken,
    required this.descriptionExpanded,
    required this.onToggleDescription,
    required this.onLoadMoreComments,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Text(error!, style: const TextStyle(color: kTextSecondary)),
      );
    }
    if (video == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VideoTitle(video: video!),
        const SizedBox(height: 12),
        _VideoStats(video: video!),
        const Divider(height: 24),
        _ChannelRow(video: video!, channel: channel),
        const Divider(height: 24),
        _Description(
          text: video!.description ?? '',
          expanded: descriptionExpanded,
          onToggle: onToggleDescription,
        ),
        const Divider(height: 32),
        _CommentsSection(
          comments: comments,
          disabled: commentsDisabled,
          loaded: commentsLoaded,
          loading: loadingComments,
          nextPageToken: nextCommentToken,
          onLoadMore: onLoadMoreComments,
        ),
      ],
    );
  }
}

class _VideoTitle extends StatelessWidget {
  final Video video;
  const _VideoTitle({required this.video});

  @override
  Widget build(BuildContext context) {
    return Text(
      video.title,
      style: const TextStyle(
        color: kTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class _VideoStats extends StatelessWidget {
  final Video video;
  const _VideoStats({required this.video});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (video.viewCount != null)
          _StatChip(
            icon: Icons.visibility_outlined,
            label: '${formatCount(video.viewCount)} views',
          ),
        if (video.likeCount != null)
          _StatChip(
            icon: Icons.thumb_up_outlined,
            label: formatCount(video.likeCount),
          ),
        _StatChip(
          icon: Icons.calendar_today_outlined,
          label: formatDate(video.publishedAt),
        ),
        if (video.formattedDuration.isNotEmpty)
          _StatChip(
            icon: Icons.timer_outlined,
            label: video.formattedDuration,
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: kTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final Video video;
  final Map<String, dynamic>? channel;
  const _ChannelRow({required this.video, this.channel});

  @override
  Widget build(BuildContext context) {
    final snippet = channel?['snippet'] as Map?;
    final stats = channel?['statistics'] as Map?;
    final avatarUrl = (snippet?['thumbnails'] as Map?)?['default']?['url'] as String?;
    final subs = stats?['subscriberCount'];

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: kSurface,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(video.channelTitle.isNotEmpty ? video.channelTitle[0] : '?',
                  style: const TextStyle(color: kTextPrimary))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(video.channelTitle,
                  style: const TextStyle(
                      color: kTextPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
              if (subs != null)
                Text(
                  '${formatCount(int.tryParse(subs.toString()))} subscribers',
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  const _Description({required this.text, required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final lines = text.split('\n');
    final preview = lines.take(4).join('\n');
    final hasMore = lines.length > 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          expanded ? text : preview,
          style: const TextStyle(color: kTextPrimary, fontSize: 13, height: 1.6),
        ),
        if (hasMore)
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                expanded ? 'Show less' : 'Show more',
                style: const TextStyle(
                  color: Color(0xFF3EA6FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CommentsSection extends StatelessWidget {
  final List<Comment> comments;
  final bool disabled;
  final bool loaded;
  final bool loading;
  final String? nextPageToken;
  final VoidCallback onLoadMore;

  const _CommentsSection({
    required this.comments,
    required this.disabled,
    required this.loaded,
    required this.loading,
    required this.nextPageToken,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (!loaded && !disabled)
          const Center(child: CircularProgressIndicator()),
        if (disabled)
          const Text('Comments are disabled for this video.',
              style: TextStyle(color: kTextSecondary)),
        if (loaded && !disabled && comments.isEmpty)
          const Text('No comments yet.', style: TextStyle(color: kTextSecondary)),
        ...comments.map((c) => CommentCard(comment: c)),
        if (nextPageToken != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: OutlinedButton(
                      onPressed: onLoadMore,
                      child: const Text('Load more comments'),
                    ),
                  ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}
