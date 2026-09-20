import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'storage_service.dart';

class KakaoFriendsService {
  KakaoFriendsService._();

  /// 카카오로 로그인한 계정이면 카카오 고유 ID를 profiles.kakao_id에 저장한다.
  /// 이메일/비밀번호 계정이면 아무 것도 하지 않는다.
  static Future<void> syncKakaoIdentity() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    UserIdentity? kakaoIdentity;
    for (final identity in user.identities ?? const <UserIdentity>[]) {
      if (identity.provider == 'kakao') {
        kakaoIdentity = identity;
        break;
      }
    }
    if (kakaoIdentity == null) return;

    await StorageService.saveMyKakaoId(kakaoIdentity.id);
  }

  /// 카카오톡 친구 목록(카카오 고유 ID)을 가져온다.
  /// 카카오 로그인 세션이 없거나 friends 권한이 없으면 빈 리스트를 돌려준다.
  static Future<List<String>> fetchKakaoFriendIds() async {
    final providerToken =
        Supabase.instance.client.auth.currentSession?.providerToken;
    if (providerToken == null) return [];

    final ids = <String>[];
    String? nextUrl = 'https://kapi.kakao.com/v1/api/talk/friends?limit=100';

    while (nextUrl != null) {
      final response = await http.get(
        Uri.parse(nextUrl),
        headers: {'Authorization': 'Bearer $providerToken'},
      );

      if (response.statusCode != 200) break;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = body['elements'] as List? ?? const [];
      for (final element in elements) {
        final id = (element as Map<String, dynamic>)['id'];
        if (id != null) ids.add(id.toString());
      }

      nextUrl = body['after_url'] as String?;
    }

    return ids;
  }
}
