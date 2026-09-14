-- 친구 추가/자세 타입 공유 기능.
-- profiles_schema.sql / profiles_functions_v2.sql / security_advisor_fixes.sql
-- 실행 이후에 추가로 실행한다.

-- ===========================================================
-- 1) 친구 코드
-- 가입 시 자동으로 6자리 코드를 하나씩 배정한다. 0/O/1/I처럼 헷갈리는
-- 문자는 빼서 사람이 직접 입력하기 쉽게 한다.
-- ===========================================================

ALTER TABLE profiles ADD COLUMN IF NOT EXISTS friend_code TEXT UNIQUE;

CREATE OR REPLACE FUNCTION public.generate_friend_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  chars CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code TEXT;
  already_used BOOLEAN;
BEGIN
  LOOP
    code := '';
    FOR i IN 1..6 LOOP
      code := code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
    END LOOP;

    SELECT EXISTS(
      SELECT 1 FROM profiles WHERE friend_code = code
    ) INTO already_used;

    EXIT WHEN NOT already_used;
  END LOOP;

  RETURN code;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.generate_friend_code()
    FROM PUBLIC, anon, authenticated;

-- 기존 handle_new_user에 friend_code 배정 추가.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, friend_code)
  VALUES (NEW.id, public.generate_friend_code());
  RETURN NEW;
END;
$$;

-- 스키마 실행 시점 이전에 이미 가입한 계정들 소급 배정.
UPDATE profiles
SET friend_code = public.generate_friend_code()
WHERE friend_code IS NULL;

ALTER TABLE profiles ALTER COLUMN friend_code SET NOT NULL;

-- ===========================================================
-- 2) 친구 요청
-- 코드만 입력하면 바로 친구가 되는 게 아니라, 요청 -> 상대방 수락
-- 절차를 거친다. 자세 타입은 개인적인 정보라 임의로 보이면 안 된다.
-- ===========================================================

CREATE TABLE IF NOT EXISTS friend_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'declined')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT friend_requests_no_self CHECK (requester_id <> addressee_id),
    UNIQUE (requester_id, addressee_id)
);

ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- 요청자 또는 받는 사람만 그 요청을 볼 수 있다.
CREATE POLICY "friend_requests_select_involved" ON friend_requests
    FOR SELECT USING (auth.uid() = requester_id OR auth.uid() = addressee_id);

-- 수락/거절은 받는 사람만 할 수 있다. INSERT는 클라이언트가 직접 못 하고
-- 아래 send_friend_request 함수를 통해서만 가능하다(코드->UUID 변환이
-- 필요해서 클라이언트가 직접 만들 수가 없다).
CREATE POLICY "friend_requests_update_addressee" ON friend_requests
    FOR UPDATE USING (auth.uid() = addressee_id);

-- ===========================================================
-- 3) 함수 3개
-- ===========================================================

-- 코드로 친구 요청 보내기.
CREATE OR REPLACE FUNCTION public.send_friend_request(p_friend_code TEXT)
RETURNS friend_requests
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  target_id UUID;
  result friend_requests;
BEGIN
  SELECT user_id INTO target_id
  FROM profiles
  WHERE friend_code = upper(trim(p_friend_code));

  IF target_id IS NULL THEN
    RAISE EXCEPTION 'FRIEND_CODE_NOT_FOUND';
  END IF;

  IF target_id = auth.uid() THEN
    RAISE EXCEPTION 'CANNOT_ADD_SELF';
  END IF;

  IF EXISTS (
    SELECT 1 FROM friend_requests
    WHERE (requester_id = auth.uid() AND addressee_id = target_id)
       OR (requester_id = target_id AND addressee_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'REQUEST_ALREADY_EXISTS';
  END IF;

  INSERT INTO friend_requests (requester_id, addressee_id)
  VALUES (auth.uid(), target_id)
  RETURNING * INTO result;

  RETURN result;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.send_friend_request(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.send_friend_request(TEXT) TO authenticated;

-- 나한테 온 대기 중인 친구 요청 목록 (요청자 코드 포함).
CREATE OR REPLACE FUNCTION public.get_pending_incoming_requests()
RETURNS TABLE (
    request_id UUID,
    requester_friend_code TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  SELECT fr.id, p.friend_code, fr.created_at
  FROM friend_requests fr
  JOIN profiles p ON p.user_id = fr.requester_id
  WHERE fr.addressee_id = auth.uid() AND fr.status = 'pending'
  ORDER BY fr.created_at DESC;
$$;

REVOKE EXECUTE ON FUNCTION public.get_pending_incoming_requests()
    FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_pending_incoming_requests() TO authenticated;

-- 수락된 친구 목록 + 자세 타입만 (포인트/스트릭 등 나머지는 안 보여준다).
CREATE OR REPLACE FUNCTION public.get_friends_with_posture()
RETURNS TABLE (
    friend_user_id UUID,
    friend_code TEXT,
    posture_profile_id TEXT
)
LANGUAGE sql
SECURITY DEFINER SET search_path = public
AS $$
  SELECT
    p.user_id,
    p.friend_code,
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
