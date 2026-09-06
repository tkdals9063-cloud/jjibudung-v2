-- 계정별 앱 데이터 저장용 (Supabase Auth의 auth.users와 1:1로 연결)
-- StorageService/PointManager가 로컬(SharedPreferences)에 들고 있던 값 중
-- 계정을 따라다녀야 하는 것만 옮긴다. 오늘자 카운터·진동/알림 설정처럼
-- 기기별로 달라도 되는 값은 그대로 로컬에 남겨둔다.

CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,

    point INTEGER NOT NULL DEFAULT 0,
    streak INTEGER NOT NULL DEFAULT 0,
    last_study_date DATE,

    total_study_time_seconds INTEGER NOT NULL DEFAULT 0,
    total_good_posture_time_seconds INTEGER NOT NULL DEFAULT 0,
    posture_rate DOUBLE PRECISION NOT NULL DEFAULT 100,

    posture_profile_id TEXT NOT NULL DEFAULT 'balanced',
    initial_baseline_angle DOUBLE PRECISION,
    initial_baseline_roll DOUBLE PRECISION,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 주간 사용 기록 (하루 1건 - 통계/스트릭 표시용 캘린더 체크)
CREATE TABLE IF NOT EXISTS usage_logs (
    user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    used_date DATE NOT NULL,
    PRIMARY KEY (user_id, used_date)
);

-- 휴대폰 스트레칭 루틴 완료 기록 (하루 1건만 허용).
-- UPDATE/DELETE 정책을 안 주고 INSERT만 허용 + (user_id, completed_date)
-- 기본키로 묶어서, 클라이언트가 뭘 시도하든 하루에 두 번은 물리적으로
-- 못 넣게 DB 레벨에서 막는다.
CREATE TABLE IF NOT EXISTS stretch_completions (
    user_id UUID NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
    completed_date DATE NOT NULL,
    earned_point INTEGER NOT NULL DEFAULT 10,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, completed_date)
);

-- ===========================================================
-- RLS: 클라이언트(Flutter 앱)가 이 테이블에 직접 붙는 구조라서
-- 반드시 켜야 한다. 없으면 다른 사용자 데이터까지 다 보이거나
-- 고쳐질 수 있다.
-- ===========================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "profiles_insert_own" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_update_own" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usage_logs_select_own" ON usage_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "usage_logs_insert_own" ON usage_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

ALTER TABLE stretch_completions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stretch_completions_select_own" ON stretch_completions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "stretch_completions_insert_own" ON stretch_completions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
-- UPDATE/DELETE 정책은 의도적으로 만들지 않는다 (완료 기록은 못 고치게).

-- ===========================================================
-- 회원가입(auth.users에 새 행 추가) 즉시 profiles 행을 자동 생성.
-- 앱이 별도로 INSERT를 안 해도 되게 해준다.
-- ===========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- updated_at 자동 갱신
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_touch_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- ===========================================================
-- point는 앱이 직접 UPDATE로 못 만지게 컬럼 권한 자체를 뺏고,
-- 아래 RPC 함수를 통해서만 바뀌도록 강제한다.
-- (RLS는 "어느 행"을 만질 수 있는지만 보고, "어느 컬럼"을 만질 수
-- 있는지는 별도 GRANT/REVOKE로 막아야 한다.)
-- ===========================================================

REVOKE UPDATE (point) ON public.profiles FROM authenticated;

-- 스트레칭 루틴 완료 처리: 오늘 완료 기록 남기기 + 포인트 지급을
-- 한 트랜잭션으로 묶는다. 오늘 이미 완료했다면 stretch_completions의
-- 기본키 충돌로 예외가 나면서 포인트도 지급되지 않는다(둘 다 롤백).
CREATE OR REPLACE FUNCTION public.complete_stretch_routine()
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  reward_point CONSTANT INTEGER := 10;
  result profiles;
BEGIN
  INSERT INTO stretch_completions (user_id, completed_date, earned_point)
  VALUES (auth.uid(), CURRENT_DATE, reward_point);

  UPDATE profiles
  SET point = point + reward_point
  WHERE user_id = auth.uid()
  RETURNING * INTO result;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.complete_stretch_routine() TO authenticated;
