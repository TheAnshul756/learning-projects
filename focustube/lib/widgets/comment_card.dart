import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/comment.dart';

class CommentCard extends StatelessWidget {
  final Comment comment;

  const CommentCard({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(url: comment.authorAvatarUrl, name: comment.authorName),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo(comment.publishedAt),
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(color: kTextPrimary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined, size: 14, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      formatCount(comment.likeCount),
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                    if (comment.replyCount > 0) ...[
                      const SizedBox(width: 16),
                      Text(
                        '${comment.replyCount} ${comment.replyCount == 1 ? 'reply' : 'replies'}',
                        style: const TextStyle(
                          color: Color(0xFF3EA6FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;
  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: kSurface,
      child: ClipOval(
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(color: kTextSecondary, fontWeight: FontWeight.bold),
      ),
    );
  }
}
