class Video {
  final String id;
  final String title;
  final String channelTitle;
  final String channelId;
  final String? thumbnailUrl;
  final String? duration; // ISO 8601, e.g. PT4M30S
  final int? viewCount;
  final int? likeCount;
  final String? description;
  final DateTime publishedAt;

  const Video({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.channelId,
    this.thumbnailUrl,
    this.duration,
    this.viewCount,
    this.likeCount,
    this.description,
    required this.publishedAt,
  });

  factory Video.fromSearchItem(Map<String, dynamic> item, Map<String, dynamic>? details) {
    final snippet = item['snippet'] as Map<String, dynamic>;
    final contentDetails = details?['contentDetails'] as Map<String, dynamic>?;
    final statistics = details?['statistics'] as Map<String, dynamic>?;

    return Video(
      id: item['id']['videoId'] as String? ?? details?['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      channelId: snippet['channelId'] as String? ?? '',
      thumbnailUrl: (snippet['thumbnails'] as Map?)?['medium']?['url'] as String? ??
          (snippet['thumbnails'] as Map?)?['default']?['url'] as String?,
      duration: contentDetails?['duration'] as String?,
      viewCount: _parseInt(statistics?['viewCount']),
      likeCount: _parseInt(statistics?['likeCount']),
      description: snippet['description'] as String?,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory Video.fromPlaylistItem(Map<String, dynamic> item, Map<String, dynamic>? details) {
    final snippet = item['snippet'] as Map<String, dynamic>;
    final contentDetails = details?['contentDetails'] as Map<String, dynamic>?;
    final statistics = details?['statistics'] as Map<String, dynamic>?;

    return Video(
      id: (snippet['resourceId'] as Map?)?['videoId'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? snippet['videoOwnerChannelTitle'] as String? ?? '',
      channelId: snippet['channelId'] as String? ?? snippet['videoOwnerChannelId'] as String? ?? '',
      thumbnailUrl: (snippet['thumbnails'] as Map?)?['medium']?['url'] as String? ??
          (snippet['thumbnails'] as Map?)?['default']?['url'] as String?,
      duration: contentDetails?['duration'] as String?,
      viewCount: _parseInt(statistics?['viewCount']),
      likeCount: _parseInt(statistics?['likeCount']),
      description: snippet['description'] as String?,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory Video.fromVideoItem(Map<String, dynamic> item) {
    final snippet = item['snippet'] as Map<String, dynamic>;
    final contentDetails = item['contentDetails'] as Map<String, dynamic>?;
    final statistics = item['statistics'] as Map<String, dynamic>?;

    return Video(
      id: item['id'] as String? ?? '',
      title: snippet['title'] as String? ?? '',
      channelTitle: snippet['channelTitle'] as String? ?? '',
      channelId: snippet['channelId'] as String? ?? '',
      thumbnailUrl: (snippet['thumbnails'] as Map?)?['maxres']?['url'] as String? ??
          (snippet['thumbnails'] as Map?)?['high']?['url'] as String? ??
          (snippet['thumbnails'] as Map?)?['medium']?['url'] as String?,
      duration: contentDetails?['duration'] as String?,
      viewCount: _parseInt(statistics?['viewCount']),
      likeCount: _parseInt(statistics?['likeCount']),
      description: snippet['description'] as String?,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  /// Returns duration in seconds, or null if not parseable.
  int? get durationSeconds {
    if (duration == null) return null;
    final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?').firstMatch(duration!);
    if (match == null) return null;
    final h = int.tryParse(match.group(1) ?? '0') ?? 0;
    final m = int.tryParse(match.group(2) ?? '0') ?? 0;
    final s = int.tryParse(match.group(3) ?? '0') ?? 0;
    return h * 3600 + m * 60 + s;
  }

  bool get isShort => (durationSeconds ?? 999) <= 65;

  /// Format duration as "4:30" or "1:04:30".
  String get formattedDuration {
    final secs = durationSeconds;
    if (secs == null) return '';
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
