class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.content,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String content;
}

const knowledgeArticles = [
  KnowledgeArticle(
    id: 'f1',
    category: '喂养',
    title: '新生儿母乳喂养指南',
    summary: '了解正确的衔乳姿势与喂养频率。',
    content: '''
衔乳姿势
正确的衔乳是成功的关键。宝宝应张大嘴巴，将大部分乳晕含入口中。

喂养频率
按需喂养是最佳选择。新生儿通常每天需要喂奶 8-12 次。
''',
  ),
  KnowledgeArticle(
    id: 's1',
    category: '睡眠',
    title: '建立健康的睡眠仪式',
    summary: '通过睡前仪式帮助宝宝更好入睡。',
    content: '''
睡眠仪式
每天固定时间进行洗澡、换衣、讲故事或唱摇篮曲。

睡眠环境
保持房间凉爽、安静、黑暗，减少光线与噪音刺激。
''',
  ),
  KnowledgeArticle(
    id: 'h1',
    category: '健康',
    title: '宝宝发烧怎么办？',
    summary: '掌握处理宝宝发烧的基础知识。',
    content: '''
观察症状
注意宝宝精神状态、食欲和尿量变化。

基础处理
减少衣物、保持通风，必要时及时就医。
''',
  ),
  KnowledgeArticle(
    id: 'a1',
    category: '安全',
    title: '家居环境安全检查',
    summary: '排查家中潜在的安全隐患。',
    content: '''
防窒息
确保地板上没有小硬币、纽扣等小物件。

家具固定
固定容易翻倒的柜子，避免攀爬危险。
''',
  ),
];
