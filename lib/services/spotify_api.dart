import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/playlist.dart';
import 'package:logger/logger.dart'; // 1. 로거 임포트

// 2. 이 파일 전용 로거 인스턴스 생성
final logger = Logger();

class SpotifyApiService {
  // 스포티파이 API의 기본 주소
  static const String _baseUrl = 'https://api.spotify.com/v1';
  
  // 인증 토큰 (나중에 로그인 로직이 완성되면 여기에 토큰이 들어옵니다)
  String _accessToken = '';

  // 토큰 세팅 함수
  void setToken(String token) {
    _accessToken = token;
  }

  // ==========================================
  // [핵심 기능] 플레이리스트의 곡 목록 가져오기
  // ==========================================
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    // 1. 요청 보낼 주소 만들기
    final url = Uri.parse('$_baseUrl/playlists/$playlistId/tracks');

    // 2. 스포티파이 서버에 GET 요청 날리기 (헤더에 토큰 포함)
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
    );

    // 3. 응답 결과 처리
    if (response.statusCode == 200) {
      // 통신 성공! JSON 글자를 Dart 맵(Map)으로 변환
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];

      // 4. 지저분한 JSON 데이터를 우리가 만든 깔끔한 Track 객체 리스트로 변환
      // (C++의 std::transform이나 map 함수와 완벽히 같은 역할입니다)
      List<Track> trackList = items.map((item) {
        return Track.fromSpotifyJson(item);
      }).toList();

      return trackList;
      
    } else {
      // 통신 실패 시 에러 던지기
      throw Exception('스포티파이 데이터를 불러오는 데 실패했습니다. 상태 코드: ${response.statusCode}');
    }
  }

  // 내 플레이리스트 목록 가져오기
  Future<List<Playlist>> getMyPlaylists() async {
    final url = Uri.parse('$_baseUrl/me/playlists');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> items = data['items'];
      logger.i('플레이리스트 데이터 수신 성공!');
      // JSON 리스트를 하나하나 Playlist 객체로 변환해서 리스트로 만듭니다.
      return items.map((item) => Playlist.fromJson(item)).toList();
  
      // logger.d('전달받은 데이터: ${response.body}');
    } else {
      // 4. 에러 발생 시 logger.e (Error) 사용
      logger.e('데이터 가져오기 실패: ${response.statusCode}');
      logger.e('에러 내용: ${response.body}');
      return [];
    }
  }
  
}