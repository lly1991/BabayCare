import 'package:flutter/material.dart';

import '../data/knowledge_articles.dart';

class KnowledgeArticlePage extends StatelessWidget {
  const KnowledgeArticlePage({super.key, required this.articleId});

  final String articleId;

  @override
  Widget build(BuildContext context) {
    KnowledgeArticle? article;
    for (final item in knowledgeArticles) {
      if (item.id == articleId) {
        article = item;
        break;
      }
    }
    if (article == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('文章详情')),
        body: const Center(child: Text('文章不存在')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              article.category,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            article.summary,
            style: const TextStyle(
              color: Color(0xFF6C6C70),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            article.content.trim(),
            style: const TextStyle(
              color: Color(0xFF1C1C1E),
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
