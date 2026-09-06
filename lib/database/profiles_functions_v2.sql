-- profiles_schema.sql 실행 이후에 추가로 실행하는 증분 스크립트.
-- (profiles_schema.sql을 통째로 다시 실행하면 정책 중복 생성 에러가 나므로
-- 이 파일만 새로 실행하면 된다.)

-- 공부 세션 결과 저장: 스트릭/누적 시간/포인트/자세유지율을 한 트랜잭션으로 반영.
-- 오늘자 로컬 카운터(today_study_time 등)는 기기에 그대로 남고,
-- 여기서는 계정에 귀속되는 값만 갱신한다.
CREATE OR REPLACE FUNCTION public.save_study_result(
    p_study_seconds INTEGER,
    p_good_posture_seconds INTEGER,
    p_earned_point INTEGER,
    p_posture_rate DOUBLE PRECISION
)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
  today DATE := CURRENT_DATE;
  prev_date DATE;
  new_streak INTEGER;
  result profiles;
BEGIN
  IF p_study_seconds <= 0 THEN
    SELECT * INTO result FROM profiles WHERE user_id = uid;
    RETURN result;
  END IF;

  SELECT last_study_date, streak INTO prev_date, new_streak
  FROM profiles WHERE user_id = uid;

  IF prev_date IS NULL THEN
    new_streak := 1;
  ELSIF prev_date = today THEN
    NULL; -- 오늘 이미 기록 있음: 스트릭 유지
  ELSIF prev_date = today - INTERVAL '1 day' THEN
    new_streak := COALESCE(new_streak, 0) + 1;
  ELSE
    new_streak := 1;
  END IF;

  UPDATE profiles SET
    total_study_time_seconds = total_study_time_seconds + p_study_seconds,
    total_good_posture_time_seconds = total_good_posture_time_seconds + p_good_posture_seconds,
    point = point + p_earned_point,
    posture_rate = p_posture_rate,
    streak = new_streak,
    last_study_date = today
  WHERE user_id = uid
  RETURNING * INTO result;

  INSERT INTO usage_logs (user_id, used_date)
  VALUES (uid, today)
  ON CONFLICT DO NOTHING;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.save_study_result(
    INTEGER, INTEGER, INTEGER, DOUBLE PRECISION
) TO authenticated;

-- 포인트 차감(리워드 교환). 잔액 부족하면 예외를 던지고 아무것도 안 바뀐다.
CREATE OR REPLACE FUNCTION public.spend_points(p_amount INTEGER)
RETURNS profiles
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid UUID := auth.uid();
  current_point INTEGER;
  result profiles;
BEGIN
  SELECT point INTO current_point FROM profiles WHERE user_id = uid FOR UPDATE;

  IF current_point IS NULL OR current_point < p_amount THEN
    RAISE EXCEPTION 'INSUFFICIENT_POINTS';
  END IF;

  UPDATE profiles SET point = point - p_amount
  WHERE user_id = uid
  RETURNING * INTO result;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.spend_points(INTEGER) TO authenticated;
