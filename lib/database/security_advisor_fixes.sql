-- Supabase Security Advisor 경고 2건 수정.
-- profiles_schema.sql / profiles_functions_v2.sql 실행 이후에 추가로 실행한다.

-- ===========================================================
-- 1) "Function can be executed by the anon role" 수정
-- PostgreSQL 기본 동작(PUBLIC에 자동 부여)뿐 아니라, Supabase 프로젝트는
-- 새 함수마다 anon 역할에도 기본적으로 실행 권한을 자동으로 준다
-- (ALTER DEFAULT PRIVILEGES). GRANT ... TO authenticated만 해두고
-- 이 자동 권한들을 회수하지 않아서 로그인 안 한 사용자도 호출 가능한
-- 상태였다. PUBLIC과 anon 둘 다에서 회수해서 authenticated만 남긴다.
-- ===========================================================

REVOKE EXECUTE ON FUNCTION public.save_study_result(
    INTEGER, INTEGER, INTEGER, DOUBLE PRECISION
) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.spend_points(INTEGER) FROM PUBLIC, anon;

REVOKE EXECUTE ON FUNCTION public.complete_stretch_routine() FROM PUBLIC, anon;

-- 트리거 전용 함수. RPC로 직접 부를 일이 없으니 아무 역할에도 안 준다.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.touch_updated_at() FROM PUBLIC, anon, authenticated;

-- ===========================================================
-- 2) "Function Search Path Mutable" 수정
-- touch_updated_at에 SET search_path 지정이 빠져있었다.
-- ===========================================================

CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;
