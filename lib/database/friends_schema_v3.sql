-- 받은 친구 요청 목록에도 요청자 닉네임을 내려준다.
-- (닉네임 없으면 NULL -> 클라이언트에서 친구 코드로 대체)
-- friends_schema_v2.sql 실행 이후에 추가로 실행한다.

-- 반환 컬럼 구성이 바뀌므로 CREATE OR REPLACE로는 안 되고 먼저 지워야 한다.
DROP FUNCTION IF EXISTS public.get_pending_incoming_requests();

CREATE OR REPLACE FUNCTION public.get_pending_incoming_requests()
RETURNS TABLE (
    request_id UUID,
    requester_friend_code TEXT,
    requester_nickname TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  SELECT fr.id, p.friend_code, p.nickname, fr.created_at
  FROM friend_requests fr
  JOIN profiles p ON p.user_id = fr.requester_id
  WHERE fr.addressee_id = auth.uid() AND fr.status = 'pending'
  ORDER BY fr.created_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_pending_incoming_requests()
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_pending_incoming_requests() TO authenticated;
