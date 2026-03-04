class Track {
  final String id;
  final String name;
  final String artist;
  final String imageUrl;

  Track({
    required this.id, 
    required this.name, 
    required this.artist, 
    required this.imageUrl
  });

  // 1. [해결] 스포티파이 JSON 전용 생성자 (이름을 fromSpotifyJson으로 통일)
  factory Track.fromSpotifyJson(Map<String, dynamic> json) {
    final trackData = json['track'];
    return Track(
      id: trackData['id'] ?? '',
      name: trackData['name'] ?? 'Unknown Title',
      artist: (trackData['artists'] as List).isNotEmpty 
          ? trackData['artists'][0]['name'] 
          : 'Unknown Artist',
      imageUrl: (trackData['album']['images'] as List).isNotEmpty 
          ? trackData['album']['images'][0]['url'] 
          : 'https://via.placeholder.com/150',
    );
  }

  // 2. [해결] 나중에 SQLite DB에 저장할 때 쓸 변환 함수
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'imageUrl': imageUrl,
    };
  }
}