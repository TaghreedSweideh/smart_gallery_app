class Photo {
  final String id;
  final String pcPath;
  final List<String> categories;
  final String? thumbnail;
  final List<String> phonePaths;
  final List<String>? tags;

  Photo(
    this.pcPath,
    this.thumbnail,
    this.tags,
    this.phonePaths, {
    required this.id,
    required this.categories,
  });
}
