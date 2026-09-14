-- 친구 기능 보완: 닉네임 표시, 친구 삭제.
-- friends_schema.sql 실행 이후에 추가로 실행한다.

-- ===========================================================
-- 1) 닉네임
-- ===========================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS nickname TEXT;

-- 친구 목록에 닉네임도 같이 내려주도록 수정 (없으면 NULL -> 클라이언트에서 친구 코드로 대체).
-- 반환 컬럼 구성이 바뀌므로 CREATE OR REPLACE로는 안 되고 먼저 지워야 한다.
DROP FUNCTION IF EXISTS public.get_friends_with_posture();

CREATE OR REPLACE FUNCTION public.get_friends_with_posture()
RETURNS TABLE (
    friend_user_id UUID,
    friend_code TEXT,
    nickname TEXT,
    posture_profile_id TEXT
)
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    p.user_id,
    p.friend_code,
    p.nickname,
    p.posture_profile_id
  FROM friend_requests fr
  JOIN profiles p
    ON p.user_id = CASE
      WHEN fr.requester_id = auth.uid() THEN fr.addressee_id
      ELSE fr.requester_id
    END
  WHERE fr.status = 'accepted'
    AND (fr.requester_id = auth.uid() OR fr.addressee_id = auth.uid());
$$;

REVOKE EXECUTE ON FUNCTION public.get_friends_with_posture() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_friends_with_posture() TO authenticated;

-- 본인 닉네임 저장.
CREATE OR REPLACE FUNCTION public.set_my_nickname(p_nickname TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  UPDATE profiles
  SET nickname = NULLIF(trim(p_nickname), '')
  WHERE user_id = auth.uid();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.set_my_nickname(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_my_nickname(TEXT) TO authenticated;

-- ===========================================================
-- 2) 친구 삭제
-- 어느 쪽에서 삭제하든 friend_requests 행 자체를 지운다.
-- (다시 추가하려면 새 요청 -> 수락을 거쳐야 한다.)
-- ===========================================================

CREATE OR REPLACE FUNCTION public.remove_friend(p_friend_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  DELETE FROM friend_requests
  WHERE status = 'accepted'
    AND (
      (requester_id = auth.uid() AND addressee_id = p_friend_user_id)
      OR (requester_id = p_friend_user_id AND addressee_id = auth.uid())
    );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.remove_friend(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.remove_friend(UUID) TO authenticated;
