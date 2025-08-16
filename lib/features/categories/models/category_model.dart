class Category {
  final String id;
  final String name;
  final String icon; // emoji or string
  final int count;
  final String? thumbnail;
  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
    this.thumbnail,
  });
}
