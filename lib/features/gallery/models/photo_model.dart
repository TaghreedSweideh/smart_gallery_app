class Photo {
  final String id;
  final String title;
  final String category;
  final List<String>? tags;
  final String url;

  Photo({
    required this.id,
    required this.title,
    required this.category,
    this.tags,
    required this.url,
  });
}
