class Playlist {
  final String id;
  final String name;
  final String imageUrl;

  Playlist({required this.id, required this.name, required this.imageUrl});

  // JSON이라는 원재료를 넣으면 Playlist 객체라는 완성품을 만들어주는 공장입니다.
  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      // 이미지가 없는 경우를 대비한 방어 코드입니다.
      imageUrl: (json['images'] != null && json['images'].isNotEmpty) 
          ? json['images'][0]['url'] 
          : 'https://via.placeholder.com/150', 
    );
  }
}