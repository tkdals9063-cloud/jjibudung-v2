-- Apply after profiles_schema.sql and friends_schema_v2.sql.
BEGIN;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS explorer_id TEXT;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pet_id TEXT;

UPDATE public.profiles SET
  explorer_id = CASE posture_profile_id
    WHEN 'forward' THEN 'forward_head'
    WHEN 'slouch' THEN 'rested'
    WHEN 'tilted' THEN 'tilted'
    ELSE 'balanced' END,
  pet_id = CASE posture_profile_id
    WHEN 'forward' THEN 'posterior_hedgehog'
    WHEN 'slouch' THEN 'posterior_hedgehog'
    WHEN 'tilted' THEN 'anterior_fox'
    ELSE 'centered_penguin' END
WHERE explorer_id IS NULL OR pet_id IS NULL;

ALTER TABLE public.profiles ALTER COLUMN explorer_id SET DEFAULT 'balanced';
ALTER TABLE public.profiles ALTER COLUMN pet_id SET DEFAULT 'centered_penguin';
ALTER TABLE public.profiles ALTER COLUMN explorer_id SET NOT NULL;
ALTER TABLE public.profiles ALTER COLUMN pet_id SET NOT NULL;

ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS valid_companion_selection;
ALTER TABLE public.profiles ADD CONSTRAINT valid_companion_selection CHECK (
  (explorer_id = 'balanced' AND pet_id = 'centered_penguin') OR
  (explorer_id = 'tilted' AND pet_id = 'anterior_fox') OR
  (explorer_id IN ('forward_head', 'rested') AND pet_id = 'posterior_hedgehog') OR
  (explorer_id IN ('forward_head', 'rested', 'tilted') AND pet_id = 'tilted_panda')
);

DROP FUNCTION IF EXISTS public.get_friends_with_posture();
ALTER TABLE public.profiles DROP COLUMN IF EXISTS posture_profile_id;
CREATE FUNCTION public.get_friends_with_posture()
RETURNS TABLE (
  friend_user_id UUID,
  friend_code TEXT,
  nickname TEXT,
  explorer_id TEXT,
  pet_id TEXT
)
LANGUAGE sql SECURITY DEFINER SET search_path = public
AS $$
  SELECT p.user_id, p.friend_code, p.nickname, p.explorer_id, p.pet_id
  FROM friend_requests fr
  JOIN profiles p ON p.user_id = CASE
    WHEN fr.requester_id = auth.uid() THEN fr.addressee_id
    ELSE fr.requester_id END
  WHERE fr.status = 'accepted'
    AND (fr.requester_id = auth.uid() OR fr.addressee_id = auth.uid());
$$;
REVOKE EXECUTE ON FUNCTION public.get_friends_with_posture() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_friends_with_posture() TO authenticated;
COMMIT;
