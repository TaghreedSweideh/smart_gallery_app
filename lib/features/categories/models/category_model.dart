class Category {
  final String id;
  final String name;
  final String icon; // emoji or string
  final int count;
  final String? thumbnail;
  final List<String>? phonePaths;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.count,
    this.thumbnail,
    this.phonePaths,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(), // normalize to string
      name: json['name'] ?? '',
      icon: _mapIcon(json['name']),
      count: json['num_images'] ?? 0,
      thumbnail: json['thumbnail'],
      phonePaths: (json['phone_paths'] as List?)?.cast<String>(),
    );
  }

  static String _mapIcon(String? name) {
    if (name == null || name.trim().isEmpty) return '📸';
    switch (name.trim().toLowerCase()) {
      case 'greeting':
        return '🎉';
      case 'duplicate':
        return '📑';
      case 'night':
        return '🌃';
      case 'others':
        return '📂';
      case 'food':
        return '🍽️';
      case 'document':
        return '📄';
      case 'people':
        return '👥';
      case 'cars':
        return '🚗';
      case 'blurry':
        return '🔍';
      case 'animals':
        return '🐾';
      case 'nature':
        return '🌿';
      case 'clothes':
        return '👗';
      default:
        return '📸';
    }
  }
}
