-- 회원 탈퇴(계정 및 데이터 완전 삭제).
-- profiles_schema.sql / friends_schema*.sql 실행 이후에 추가로 실행한다.

-- profiles, usage_logs, stretch_completions, friend_requests 는 모두
-- auth.users(id) 를 ON DELETE CASCADE 로 참조하므로, auth.users 행 하나만
-- 지우면 그 계정의 모든 데이터가 함께 삭제된다.
--
-- auth 스키마는 일반 사용자가 건드릴 수 없으므로 SECURITY DEFINER 로 만들고,
-- 본인(auth.uid()) 계정만 지울 수 있게 제한한다.
CREATE OR REPLACE FUNCTION public.delete_my_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  target_id UUID := auth.uid();
BEGIN
  IF target_id IS NULL THEN
    RAISE EXCEPTION 'NOT_AUTHENTICATED';
  END IF;

  DELETE FROM auth.users WHERE id = target_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.delete_my_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_my_account() TO authenticated;
