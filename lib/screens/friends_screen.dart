import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/posture_profile_info.dart';
import '../services/storage_service.dart';

// 친구 목록 카드의 작은 아바타 전용 이미지. 코드/이름/소개 문구는
// posture_profile_info.dart의 것을 그대로 써서 스트레칭 탭과 항상 일치시킨다.
String _avatarImagePathFor(String postureProfileId) {
  return switch (postureProfileId) {
    'forward' => 'assets/characters/avatar_forward_fox.png',
    'slouch' => 'assets/characters/avatar_rested_hedgehog.png',
    'tilted' => 'assets/characters/avatar_tilted_panda.png',
    _ => 'assets/characters/avatar_balanced_penguin.png',
  };
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _codeController = TextEditingController();

  bool _isSending = false;
  List<Map<String, dynamic>> _pendingRequests = [];
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final requests = await StorageService.loadPendingFriendRequests();
    final friends = await StorageService.loadFriends();

    if (!mounted) return;
    setState(() {
      _pendingRequests = requests;
      _friends = friends;
    });
  }

  String _errorMessage(Object error) {
    final message = error is PostgrestException ? error.message : '$error';
    if (message.contains('FRIEND_CODE_NOT_FOUND')) {
      return '그 코드를 가진 친구를 찾을 수 없어요.';
    }
    if (message.contains('CANNOT_ADD_SELF')) {
      return '본인 코드는 추가할 수 없어요.';
    }
    if (message.contains('REQUEST_ALREADY_EXISTS')) {
      return '이미 친구이거나 요청을 보낸 상대예요.';
    }
    return '친구 추가 중 오류가 발생했어요.';
  }

  Future<void> _sendRequest() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await StorageService.sendFriendRequest(code);
      _codeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 보냈어요.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _respond(String requestId, bool accept) async {
    await StorageService.respondFriendRequest(
      requestId: requestId,
      accept: accept,
    );
    await _loadAll();
  }

  Future<void> _removeFriend(String friendUserId, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('친구 삭제'),
        content: Text('$label 님을 친구에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await StorageService.removeFriend(friendUserId);
    await _loadAll();
  }

  void _showProfileDialog(PostureProfileInfo profile, String displayName) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displayName 님의 자세 친구',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Image.asset(
                profile.imagePath,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 42,
                  color: Color(0xff725AC1),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile.code,
                style: const TextStyle(
                  color: Color(0xff725AC1),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${profile.explorerName}\n${profile.petName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                profile.brief,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final friendUserId = friend['friend_user_id'] as String;
    final friendCode = friend['friend_code'] as String? ?? '';
    final nickname = friend['nickname'] as String?;
    final displayName = (nickname == null || nickname.isEmpty)
        ? friendCode
        : nickname;
    final profileId = friend['posture_profile_id'] as String? ?? 'balanced';
    final profile = postureProfileInfoFor(profileId);

    return Card(
      child: ListTile(
        onTap: () => _showProfileDialog(profile, displayName),
        leading: CircleAvatar(
          backgroundImage: AssetImage(_avatarImagePathFor(profileId)),
        ),
        title: Text(displayName),
        subtitle: Text(profile.code),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, color: Colors.grey),
          onPressed: () => _removeFriend(friendUserId, displayName),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF3F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Color(0xff725AC1)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '내 이름과 친구 코드는 설정 탭에서 확인하고 수정할 수 있어요.',
                    style: TextStyle(fontSize: 12, color: Color(0xff725AC1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '친구 코드로 추가하기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: '친구 코드 입력 (예: AB12CD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 50),
                ),
                onPressed: _isSending ? null : _sendRequest,
                child: const Text('추가'),
              ),
            ],
          ),

          if (_pendingRequests.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              '받은 친구 요청',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (final request in _pendingRequests)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: Text('${request['requester_friend_code']} 님의 요청'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () =>
                            _respond(request['request_id'] as String, true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () =>
                            _respond(request['request_id'] as String, false),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          const SizedBox(height: 28),
          const Text(
            '내 친구',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (_friends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '아직 친구가 없어요.\n친구 코드로 추가해보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            for (final friend in _friends) ...[
              _buildFriendCard(friend),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
