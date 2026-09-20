import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main_navigation.dart';
import '../services/kakao_friends_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _authErrorText;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    // 이메일/비밀번호 로그인, 카카오 로그인(브라우저에서 돌아오는 딥링크)
    // 둘 다 이 이벤트로 감지해서 공통으로 처리한다.
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint(
          '[Auth] onAuthStateChange: event=${data.event}, '
          'session=${data.session != null}, '
          'user=${data.session?.user.id}',
        );
        if (data.event == AuthChangeEvent.signedIn) {
          KakaoFriendsService.syncKakaoIdentity();
          _goToMain();
        }
      },
      onError: (error, stackTrace) {
        debugPrint('[Auth] onAuthStateChange error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToMain() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return '이메일을 입력해주세요.';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return '올바른 이메일 형식이 아니에요.';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
    return null;
  }

  String _translateLoginError(AuthException e) {
    final message = e.message.toLowerCase();
    if (e.code == 'invalid_credentials' ||
        message.contains('invalid login credentials')) {
      return '아이디 또는 비밀번호가 틀렸습니다.';
    }
    if (e.code == 'email_not_confirmed' ||
        message.contains('email not confirmed')) {
      return '이메일 인증이 필요해요. 메일함을 확인해주세요.';
    }
    return '로그인 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _authErrorText = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // 성공하면 _authSubscription의 signedIn 이벤트가 메인 화면으로 넘겨준다.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _authErrorText = _translateLoginError(e));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _authErrorText = '로그인 중 오류가 발생했어요. 잠시 후 다시 시도해주세요.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  Future<void> _signInWithKakao() async {
    debugPrint('[Kakao] signInWithOAuth 시작');
    try {
      final launched = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: 'jjibudung://login-callback/',
        // 비즈니스 인증 완료로 account_email도 승인돼서 같이 요청한다.
        // friends: 카카오 친구 중 가입한 사람 추천 기능에 사용.
        scopes: 'account_email,profile_nickname,profile_image,friends',
      );
      debugPrint('[Kakao] signInWithOAuth 브라우저 실행 결과: $launched');
    } on AuthException catch (e) {
      debugPrint(
        '[Kakao] AuthException: message=${e.message}, '
        'statusCode=${e.statusCode}, code=${e.code}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, stackTrace) {
      debugPrint('[Kakao] 알 수 없는 오류: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카카오 로그인 중 오류가 발생했어요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '로그인',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Text(
                  '다시 만나서 반가워요',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _authErrorText != null ? '' : null,
                  ),
                  onChanged: (_) {
                    if (_authErrorText != null) {
                      setState(() => _authErrorText = null);
                    }
                  },
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    errorText: _authErrorText,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  onChanged: (_) {
                    if (_authErrorText != null) {
                      setState(() => _authErrorText = null);
                    }
                  },
                  onFieldSubmitted: (_) => _onSubmit(),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            '로그인',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('또는', style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  height: 45,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE500),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _signInWithKakao,
                      child: Center(
                        child: Image.asset(
                          'assets/icon/kakao_login_medium_wide.png',
                          width: 300,
                          height: 45,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: _goToSignup,
                    child: const Text('계정이 없으신가요? 회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
