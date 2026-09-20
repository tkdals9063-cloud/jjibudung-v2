-- 카카오 친구 중 이미 가입한 사람 추천 기능.
-- friends_schema_v3.sql 실행 이후에 추가로 실행한다.

-- ===========================================================
-- 1) 카카오 고유 ID 저장
-- ===========================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS kakao_id TEXT;

-- 카카오 계정 하나는 프로필 하나에만 연결돼야 한다.
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_kakao_id
    ON profiles (kakao_id)
    WHERE kakao_id IS NOT NULL;

CREATE OR REPLACE FUNCTION public.set_my_kakao_id(p_kakao_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE profiles SET kakao_id = p_kakao_id WHERE user_id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_my_kakao_id(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_my_kakao_id(TEXT) TO authenticated;

-- ===========================================================
-- 2) 카카오 친구 중 가입한 사람 찾기
-- 이미 친구이거나 요청을 주고받은 사이는 추천 목록에서 뺀다.
-- ===========================================================

CREATE OR REPLACE FUNCTION public.find_signed_up_kakao_friends(p_kakao_ids TEXT[])
RETURNS TABLE (
    friend_user_id UUID,
    friend_code TEXT,
    nickname TEXT
)
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  SELECT p.user_id, p.friend_code, p.nickname
  FROM profiles p
  WHERE p.kakao_id = ANY(p_kakao_ids)
    AND p.user_id <> auth.uid()
    AND NOT EXISTS (
      SELECT 1 FROM friend_requests fr
      WHERE (fr.requester_id = auth.uid() AND fr.addressee_id = p.user_id)
         OR (fr.requester_id = p.user_id AND fr.addressee_id = auth.uid())
    );
$$;

REVOKE EXECUTE ON FUNCTION public.find_signed_up_kakao_friends(TEXT[])
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.find_signed_up_kakao_friends(TEXT[]) TO authenticated;
