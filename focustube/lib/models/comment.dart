class Comment {
  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String text;
  final int likeCount;
  final DateTime publishedAt;
  final int replyCount;

  const Comment({
    required this.id,
    required this.authorName,
    this.authorAvatarUrl,
    required this.text,
    required this.likeCount,
    required this.publishedAt,
    required this.replyCount,
  });

  factory Comment.fromJson(Map<String, dynamic> item) {
    final top = (item['snippet'] as Map)['topLevelComment'] as Map;
    final snippet = top['snippet'] as Map<String, dynamic>;
    return Comment(
      id: item['id'] as String? ?? '',
      authorName: snippet['authorDisplayName'] as String? ?? 'Unknown',
      authorAvatarUrl: snippet['authorProfileImageUrl'] as String?,
      text: snippet['textOriginal'] as String? ?? snippet['textDisplay'] as String? ?? '',
      likeCount: int.tryParse(snippet['likeCount']?.toString() ?? '0') ?? 0,
      publishedAt: DateTime.tryParse(snippet['publishedAt'] as String? ?? '') ?? DateTime.now(),
      replyCount: int.tryParse((item['snippet'] as Map)['totalReplyCount']?.toString() ?? '0') ?? 0,
    );
  }
}
