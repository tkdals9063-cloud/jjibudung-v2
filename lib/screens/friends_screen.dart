import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/posture_profile_info.dart';
import '../models/posture_companion.dart';
import '../services/storage_service.dart';

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
  String _myNickname = '';
  CompanionSelection _mySelection = CompanionSelection.balanced;
  bool _profileLoaded = false;

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
    final nickname = await StorageService.loadMyNickname();
    final selection = await StorageService.loadCompanionSelection();

    if (!mounted) return;
    setState(() {
      _pendingRequests = requests;
      _friends = friends;
      _myNickname = nickname;
      _mySelection = selection;
      _profileLoaded = true;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('친구 요청을 보냈어요.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _requesterDisplayName(Map<String, dynamic> request) {
    final code = request['requester_friend_code'] as String? ?? '';
    final nickname = request['requester_nickname'] as String?;
    return (nickname == null || nickname.isEmpty) ? code : nickname;
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

  void _showProfileDialog(
    PostureProfileInfo profile,
    String displayName,
    String? standingImagePath, {
    bool isMe = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isMe ? '내 자세 친구' : '$displayName 님의 자세 친구',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (standingImagePath == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('이 조합의 선 자세 이미지를 준비 중이에요.'),
                )
              else
                Image.asset(
                  standingImagePath,
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
    final selection = CompanionSelection.fromIds(
      friend['explorer_id'] as String?,
      friend['pet_id'] as String?,
      legacyProfileId: friend['posture_profile_id'] as String?,
    );
    final profile = postureProfileInfoForSelection(selection);

    return Card(
      child: ListTile(
        onTap: () => _showProfileDialog(
          profile,
          displayName,
          selection.standingImagePath,
        ),
        leading: CircleAvatar(
          backgroundImage: selection.seatedImagePath == null
              ? null
              : AssetImage(selection.seatedImagePath!),
          child: selection.seatedImagePath == null
              ? const Icon(Icons.person_outline)
              : null,
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

  Widget _buildMyCard() {
    final profile = postureProfileInfoForSelection(_mySelection);
    final displayName = _myNickname.isEmpty ? '나' : _myNickname;
    final avatarUrl = _myAvatarUrl();
    return Card(
      color: const Color(0xffF3F0FF),
      child: ListTile(
        onTap: () => _showProfileDialog(
          profile,
          displayName,
          _mySelection.standingImagePath,
          isMe: true,
        ),
        leading: CircleAvatar(
          child: ClipOval(
            child: avatarUrl == null
                ? _myAvatarFallback()
                : Image.network(
                    avatarUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _myAvatarFallback(),
                  ),
          ),
        ),
        title: Text(_myNickname.isEmpty ? '나' : '$displayName (나)'),
        subtitle: Text(profile.code),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String? _myAvatarUrl() {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    for (final key in ['avatar_url', 'picture', 'profile_image_url']) {
      final value = metadata?[key];
      if (value is String && Uri.tryParse(value)?.scheme == 'https') {
        return value;
      }
    }
    return null;
  }

  Widget _myAvatarFallback() {
    final imagePath = _mySelection.seatedImagePath;
    return imagePath == null
        ? const Icon(Icons.person_outline)
        : Image.asset(imagePath, width: 40, height: 40, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구'), centerTitle: true),
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 8,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!_isSending) _sendRequest();
                  },
                  decoration: const InputDecoration(
                    hintText: '친구 코드 입력 (예: AB12CD)',
                    border: OutlineInputBorder(),
                    isDense: true,
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
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            '내 프로필',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (_profileLoaded)
            _buildMyCard()
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 28),
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
                  title: Text('${_requesterDisplayName(request)} 님의 요청'),
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
        ],
      ),
    );
  }
}
