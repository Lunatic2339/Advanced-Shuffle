import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class AuthService {
  HttpServer? _server;
  
  // 인증 후 성공적으로 받은 토큰을 저장할 콜백 함수
  Future<void> login(Function(String) onTokenReceived) async {
    final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    const String redirectUri = 'http://127.0.0.1:8888/callback';

    // 1. 서버 시작
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8888, shared: true);
    
    // 2. 브라우저 열기
    final String authUrl = 'https://accounts.spotify.com/authorize'
        '?client_id=$clientId&response_type=code&redirect_uri=$redirectUri'
        '&scope=playlist-read-private%20user-read-private';

    if (await canLaunchUrl(Uri.parse(authUrl))) {
      await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication);
    }

    // 3. 코드 낚아채기 및 토큰 교환
    await for (HttpRequest request in _server!) {
      final code = request.uri.queryParameters['code'];
      if (code != null) {
        final token = await _exchangeCodeForToken(code);
        if (token != null) onTokenReceived(token);

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

  Future<String?> _exchangeCodeForToken(String code) async {
    final String clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
    final String clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
    
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'http://127.0.0.1:8888/callback',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['access_token'];
    }
    return null;
  }
}