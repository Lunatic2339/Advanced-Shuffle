import 'dart:io'; // 내장 서버를 위한 라이브러리
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http; // 상단에 추가되어 있는지 확인!
import 'dart:convert';
import 'services/spotify_api.dart';

import 'models/playlist.dart';

final logger = Logger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const LoginTestScreen());
  }
}

class LoginTestScreen extends StatefulWidget {
  const LoginTestScreen({super.key});
  @override
  State<LoginTestScreen> createState() => _LoginTestScreenState();


}

class _LoginTestScreenState extends State<LoginTestScreen> {
  HttpServer? _server;
  List<Playlist> _playlists = [];

  // 1. [해결] _exchangeCodeForToken이 반드시 이 클래스 { } 안에 있어야 합니다.
  Future<void> _exchangeCodeForToken(String code) async {
    final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    final String clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
    const String redirectUri = 'http://127.0.0.1:8888/callback';

    // [해결] + 연산자 대신 '$변수' 형태(Interpolation) 권장 경고 해결
    final String authHeader = base64Encode(utf8.encode('$clientId:$clientSecret'));

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'), // 진짜 스포티파이 토큰 창구
      headers: {
        'Authorization': 'Basic $authHeader',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access_token'];
      // 1. 비서(Service) 객체를 하나 만듭니다.
      final spotifyApi = SpotifyApiService();
      
      // 2. 비서에게 방금 얻은 '진짜 열쇠(Token)'를 건네줍니다.
      spotifyApi.setToken(accessToken);
      logger.i('🚀 열쇠 장착 완료! 이제 데이터를 가져옵니다...'); 
      await spotifyApi.getMyPlaylists(); // 여기서 멈춰있는지 확인용
      await _loadPlaylists(accessToken);
      logger.i('✅ 데이터 가져오기 완료!');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('토큰 교환 성공!')),
        );
      }
    } else {
      logger.e('토큰 교환 실패: ${response.body}');
    }
  }

  Future<void> _startLocalServer() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8888, shared: true);
    logger.i('내장 서버 대기 중...');

    await for (HttpRequest request in _server!) {
      final uri = request.uri;
      
      if (uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!;
        
        // [해결] 이제 클래스 내부 함수이므로 호출이 가능합니다.
        await _exchangeCodeForToken(code); 

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<h1>인증 성공!</h1><p>앱으로 돌아가세요.</p>')
          ..close();

        await _server?.close();
        _server = null;
        break;
      }
    }
  }

  Future<void> _loginToSpotify() async {
    final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    const String redirectUri = 'http://127.0.0.1:8888/callback';

    _startLocalServer();

    final String authUrl =
        'https://accounts.spotify.com/authorize' // 진짜 스포티파이 권한 승인 주소
        '?client_id=$clientId'
        '&response_type=code'
        '&redirect_uri=$redirectUri'
        '&scope=playlist-read-private%20user-read-private';

    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
    }
  }
  Future<void> _loadPlaylists(String token) async {
    final api = SpotifyApiService();
    api.setToken(token);
    
    final result = await api.getMyPlaylists(); // 데이터 가져오기
    
    setState(() {
      _playlists = result; // 화면 새로고침!
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 플레이리스트')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _loginToSpotify,
            child: const Text('스포티파이 연동'),
          ),
          
          // 리스트를 보여주는 영역
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final item = _playlists[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50, height: 50),
                  title: Text(item.name),
                  onTap: () => logger.i('${item.name} 클릭됨!'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}