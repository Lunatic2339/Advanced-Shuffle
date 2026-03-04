class Track {
  // 1. 스포티파이에서 받아올 기본 정보
  final String id;
  final String title;
  final String artist;
  final String album;
  final DateTime? addedAt;

  // 2. 우리 앱 내부 DB에 쌓을 자체 기록 (하이브리드 셔플용)
  int appPlayCount;
  DateTime? lastPlayedAt;
  int skipCount;

  // 생성자 (Constructor)
  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.addedAt,
    this.appPlayCount = 0, // 처음엔 재생 횟수 0
    this.lastPlayedAt,
    this.skipCount = 0,    // 처음엔 스킵 횟수 0
  });

  // 스포티파이 API의 JSON 데이터를 Dart 객체로 변환하는 팩토리 메서드
  factory Track.fromSpotifyJson(Map<String, dynamic> json) {
    final trackNode = json['track'];
    return Track(
      id: trackNode['id'] ?? '',
      title: trackNode['name'] ?? 'Unknown Title',
      artist: trackNode['artists'][0]['name'] ?? 'Unknown Artist',
      album: trackNode['album']['name'] ?? 'Unknown Album',
      addedAt: json['added_at'] != null ? DateTime.parse(json['added_at']) : null,
    );
  }

  // 나중에 SQLite DB에 저장하기 위해 Map 형태로 변환하는 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'app_play_count': appPlayCount,
      'last_played_at': lastPlayedAt?.toIso8601String(),
      'skip_count': skipCount,
    };
  }
}