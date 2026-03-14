import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/knowledge_articles.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  String _query = '';
  String _category = '全部';

  @override
  Widget build(BuildContext context) {
    final categories = <String>{'全部'};
    for (final article in knowledgeArticles) {
      categories.add(article.category);
    }
    final filtered = knowledgeArticles.where((article) {
      final categoryOk = _category == '全部' || article.category == _category;
      final searchText =
          '${article.title} ${article.summary} ${article.content}';
      final queryOk =
          _query.trim().isEmpty || searchText.contains(_query.trim());
      return categoryOk && queryOk;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('育儿知识')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: '搜索文章',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: _category == category,
                        onSelected: (_) => setState(() => _category = category),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  '暂无匹配内容',
                  style: TextStyle(color: Color(0xFF6C6C70)),
                ),
              ),
            )
          else
            ...filtered.map(
              (article) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    onTap: () => context.push('/knowledge/${article.id}'),
                    title: Text(
                      article.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      article.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
