class Station {
  final String stationuuid;
  final String name;
  final String url;
  final String urlResolved;
  final String homepage;
  final String favicon;
  final String tags;
  final String country;
  final String countrycode;
  final String state;
  final String language;
  final String codec;
  final int bitrate;
  final int votes;
  final int clickcount;

  Station({
    required this.stationuuid,
    required this.name,
    required this.url,
    required this.urlResolved,
    required this.homepage,
    required this.favicon,
    required this.tags,
    required this.country,
    required this.countrycode,
    required this.state,
    required this.language,
    required this.codec,
    required this.bitrate,
    required this.votes,
    required this.clickcount,
  });

  /// Parse the comma-separated list of tags into a list of clean strings.
  List<String> get tagList {
    if (tags.isEmpty) return [];
    return tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      stationuuid: json['stationuuid'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Station',
      url: json['url'] as String? ?? '',
      urlResolved:
          json['url_resolved'] as String? ?? json['url'] as String? ?? '',
      homepage: json['homepage'] as String? ?? '',
      favicon: json['favicon'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      country: json['country'] as String? ?? '',
      countrycode: json['countrycode'] as String? ?? '',
      state: json['state'] as String? ?? '',
      language: json['language'] as String? ?? '',
      codec: json['codec'] as String? ?? 'MP3',
      bitrate: json['bitrate'] is int
          ? json['bitrate'] as int
          : int.tryParse(json['bitrate']?.toString() ?? '') ?? 0,
      votes: json['votes'] is int
          ? json['votes'] as int
          : int.tryParse(json['votes']?.toString() ?? '') ?? 0,
      clickcount: json['clickcount'] is int
          ? json['clickcount'] as int
          : int.tryParse(json['clickcount']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationuuid': stationuuid,
      'name': name,
      'url': url,
      'url_resolved': urlResolved,
      'homepage': homepage,
      'favicon': favicon,
      'tags': tags,
      'country': country,
      'countrycode': countrycode,
      'state': state,
      'language': language,
      'codec': codec,
      'bitrate': bitrate,
      'votes': votes,
      'clickcount': clickcount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Station && other.stationuuid == stationuuid;
  }

  @override
  int get hashCode => stationuuid.hashCode;
}
