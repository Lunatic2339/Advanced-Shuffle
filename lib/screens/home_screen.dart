import 'package:flutter/material.dart';
import '../models/playlist.dart';
import '../services/auth_service.dart';
import '../services/spotify_api.dart';
import 'track_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SpotifyApiService _apiService = SpotifyApiService();
  List<Playlist> _playlists = [];
  String? _token;

  void _handleLogin() async {
    await _authService.login((token) async {
      _token = token;
      _apiService.setToken(token);
      final playlists = await _apiService.getMyPlaylists();
      setState(() {
        _playlists = playlists;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('나의 플레이리스트')),
      body: Column(
        children: [
          ElevatedButton(onPressed: _handleLogin, child: const Text('스포티파이 연동')),
          Expanded(
            child: ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final item = _playlists[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text(item.name),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrackListScreen(playlist: item, token: _token!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}