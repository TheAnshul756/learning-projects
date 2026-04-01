import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/comment.dart';
import 'auth_service.dart';

class YouTubeService {
  static const _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const _maxFeedChannels = 15; // channels to fetch per page load
  static const _videosPerChannel = 5; // recent videos per channel

  final AuthService _auth;

  // Simple in-memory cache: key → {data, expiry}
  final _cache = <String, ({Object data, DateTime expiry})>{};

  YouTubeService(this._auth);

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Future<Map<String, String>> _headers() async {
    final h = await _auth.getAuthHeaders();
    if (h == null) throw Exception('Not authenticated');
    return h;
  }

  Future<Map<String, dynamic>> _get(String endpoint, Map<String, String> params) async {
    final uri = Uri.parse('$_baseUrl/$endpoint').replace(queryParameters: params);
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 401) throw Exception('auth_expired');
    if (response.statusCode != 200) {
      debugPrint('YouTube API error ${response.statusCode}: ${response.body}');
      throw Exception('API error ${response.statusCode}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  T? _fromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void _toCache(String key, Object data, {Duration ttl = const Duration(minutes: 30)}) {
    _cache[key] = (data: data, expiry: DateTime.now().add(ttl));
  }

  // ─── Subscription feed ────────────────────────────────────────────────────

  /// Fetch subscription feed videos filtered for no shorts.
  /// [subPageToken] paginates through the user's subscriptions.
  Future<({List<Video> videos, String? nextSubPageToken})> getFeed({
    String? subPageToken,
  }) async {
    final cacheKey = 'feed_${subPageToken ?? 'first'}';
    final cached = _fromCache<({List<Video> videos, String? nextSubPageToken})>(cacheKey);
    if (cached != null) return cached;

    // 1. Fetch subscriptions page
    final subData = await _get('subscriptions', {
      'part': 'snippet',
      'mine': 'true',
      'maxResults': '50',
      'order': 'alphabetical',
      if (subPageToken != null) 'pageToken': subPageToken,
    });

    final subscriptions = (subData['items'] as List?) ?? [];
    final nextSubPageToken = subData['nextPageToken'] as String?;
    final channelIds = subscriptions
        .map((s) => (s['snippet']?['resourceId']?['channelId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .take(_maxFeedChannels)
        .toList();

    if (channelIds.isEmpty) {
      return (videos: <Video>[], nextSubPageToken: nextSubPageToken);
    }

    // 2. Get upload playlist IDs for channels
    final channelData = await _get('channels', {
      'part': 'contentDetails',
      'id': channelIds.join(','),
      'maxResults': '50',
    });

    final uploadPlaylistIds = ((channelData['items'] as List?) ?? [])
        .map((c) => c['contentDetails']?['relatedPlaylists']?['uploads'] as String?)
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    // 3. Get recent videos from each uploads playlist
    final allPlaylistItems = <Map<String, dynamic>>[];
    await Future.wait(uploadPlaylistIds.map((playlistId) async {
      try {
        final data = await _get('playlistItems', {
          'part': 'snippet',
          'playlistId': playlistId,
          'maxResults': '$_videosPerChannel',
        });
        allPlaylistItems.addAll(((data['items'] as List?) ?? []).cast());
      } catch (_) {}
    }));

    if (allPlaylistItems.isEmpty) {
      return (videos: <Video>[], nextSubPageToken: nextSubPageToken);
    }

    // 4. Batch-fetch video details to filter shorts and get stats
    final videoIds = allPlaylistItems
        .map((i) => (i['snippet']?['resourceId']?['videoId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final detailsMap = await _batchVideoDetails(videoIds);

    // 5. Build Video objects and filter out shorts
    final videos = allPlaylistItems
        .map((item) {
          final id = (item['snippet']?['resourceId']?['videoId'] as String?) ?? '';
          return Video.fromPlaylistItem(item, detailsMap[id]);
        })
        .where((v) => v.id.isNotEmpty && !v.isShort)
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    final result = (videos: videos, nextSubPageToken: nextSubPageToken);
    _toCache(cacheKey, result);
    return result;
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<({List<Video> videos, String? nextPageToken})> search(
    String query, {
    String? pageToken,
  }) async {
    final cacheKey = 'search_${query}_${pageToken ?? 'first'}';
    final cached = _fromCache<({List<Video> videos, String? nextPageToken})>(cacheKey);
    if (cached != null) return cached;

    final searchData = await _get('search', {
      'part': 'snippet',
      'q': query,
      'type': 'video',
      'maxResults': '24',
      if (pageToken != null) 'pageToken': pageToken,
    });

    final items = (searchData['items'] as List?) ?? [];
    final nextPageToken = searchData['nextPageToken'] as String?;

    final videoIds = items
        .map((i) => (i['id']?['videoId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final detailsMap = await _batchVideoDetails(videoIds);

    final videos = items
        .map((item) {
          final id = (item['id']?['videoId'] as String?) ?? '';
          return Video.fromSearchItem(item as Map<String, dynamic>, detailsMap[id]);
        })
        .where((v) => v.id.isNotEmpty && !v.isShort)
        .toList();

    final result = (videos: videos, nextPageToken: nextPageToken);
    _toCache(cacheKey, result, ttl: const Duration(minutes: 10));
    return result;
  }

  // ─── Video details ────────────────────────────────────────────────────────

  Future<Video> getVideoDetails(String videoId) async {
    final cacheKey = 'video_$videoId';
    final cached = _fromCache<Video>(cacheKey);
    if (cached != null) return cached;

    final data = await _get('videos', {
      'part': 'snippet,contentDetails,statistics',
      'id': videoId,
    });

    final items = (data['items'] as List?) ?? [];
    if (items.isEmpty) throw Exception('Video not found');

    final video = Video.fromVideoItem(items.first as Map<String, dynamic>);
    _toCache(cacheKey, video, ttl: const Duration(hours: 1));
    return video;
  }

  // ─── Channel info (for watch screen) ─────────────────────────────────────

  Future<Map<String, dynamic>?> getChannel(String channelId) async {
    final cacheKey = 'channel_$channelId';
    final cached = _fromCache<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final data = await _get('channels', {
      'part': 'snippet,statistics',
      'id': channelId,
    });

    final items = (data['items'] as List?) ?? [];
    if (items.isEmpty) return null;

    final channel = items.first as Map<String, dynamic>;
    _toCache(cacheKey, channel, ttl: const Duration(hours: 6));
    return channel;
  }

  // ─── Comments ─────────────────────────────────────────────────────────────

  Future<({List<Comment> comments, String? nextPageToken, bool disabled})> getComments(
    String videoId, {
    String? pageToken,
  }) async {
    final cacheKey = 'comments_${videoId}_${pageToken ?? 'first'}';
    final cached =
        _fromCache<({List<Comment> comments, String? nextPageToken, bool disabled})>(cacheKey);
    if (cached != null) return cached;

    try {
      final data = await _get('commentThreads', {
        'part': 'snippet',
        'videoId': videoId,
        'maxResults': '20',
        'order': 'relevance',
        if (pageToken != null) 'pageToken': pageToken,
      });

      final comments = ((data['items'] as List?) ?? [])
          .map((item) => Comment.fromJson(item as Map<String, dynamic>))
          .toList();

      final result = (
        comments: comments,
        nextPageToken: data['nextPageToken'] as String?,
        disabled: false,
      );
      _toCache(cacheKey, result, ttl: const Duration(minutes: 15));
      return result;
    } catch (e) {
      // Comments may be disabled for the video
      return (comments: <Comment>[], nextPageToken: null, disabled: true);
    }
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Fetch contentDetails + statistics for up to 50 video IDs at once.
  Future<Map<String, Map<String, dynamic>>> _batchVideoDetails(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _get('videos', {
      'part': 'contentDetails,statistics',
      'id': ids.take(50).join(','),
      'maxResults': '50',
    });
    final result = <String, Map<String, dynamic>>{};
    for (final item in (data['items'] as List?) ?? []) {
      final m = item as Map<String, dynamic>;
      result[m['id'] as String] = m;
    }
    return result;
  }
}
