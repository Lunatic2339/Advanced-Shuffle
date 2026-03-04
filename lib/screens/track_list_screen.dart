import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../models/track.dart';
import '../services/spotify_api.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class TrackListScreen extends StatefulWidget {
  final Playlist playlist; // 앞 화면에서 넘겨받은 플레이리스트 정보
  final String token;      // API 호출에 필요한 인증 토큰

  const TrackListScreen({
    super.key, 
    required this.playlist, 
    required this.token
  });

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  final SpotifyApiService _apiService = SpotifyApiService();
  List<Track> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTracks(); // 화면이 열리자마자 곡 목록 가져오기
  }

  Future<void> _fetchTracks() async {
    try {
      _apiService.setToken(widget.token);
      logger.i('${widget.playlist.name}의 곡 목록을 가져오는 중...');
      
      final result = await _apiService.getPlaylistTracks(widget.playlist.id);
      
      setState(() {
        _tracks = result;
        _isLoading = false;
      });
      logger.i('${_tracks.length}개의 곡을 성공적으로 불러왔습니다.');
    } catch (e) {
      logger.e('곡 목록 로드 중 에러 발생: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.name),
        backgroundColor: Colors.green, // 스포티파이 느낌 한 스푼
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // 로딩 중 뱅글뱅글
          : _tracks.isEmpty
              ? const Center(child: Text('이 플레이리스트에는 곡이 없습니다.'))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: Image.network(
                        track.imageUrl, 
                        width: 45, 
                        height: 45, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.music_note), // 이미지 로드 실패 시 아이콘
                      ),
                      title: Text(
                        track.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis, // 제목 너무 길면 ... 처리
                      ),
                      subtitle: Text(track.artist),
                      trailing: const Icon(Icons.more_vert), // 우측 점 세개 메뉴 버튼
                    );
                  },
                ),
    );
  }
}