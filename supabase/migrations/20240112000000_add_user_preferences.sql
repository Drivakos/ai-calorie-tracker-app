-- Add user preferences for units, activity level, and calorie goal
ALTER TABLE user_profiles
ADD COLUMN weight_unit TEXT DEFAULT 'kg' CHECK (weight_unit IN ('kg', 'lbs')),
ADD COLUMN height_unit TEXT DEFAULT 'cm' CHECK (height_unit IN ('cm', 'ft')),
ADD COLUMN activity_level TEXT CHECK (activity_level IN (
  'sedentary',           -- Little or no exercise, desk job
  'lightly_active',      -- Light exercise 1-3 days/week
  'moderately_active',   -- Moderate exercise 3-5 days/week
  'very_active',         -- Hard exercise 6-7 days/week
  'extra_active'         -- Very hard exercise, physical job
)),
ADD COLUMN calorie_goal TEXT DEFAULT 'maintain' CHECK (calorie_goal IN (
  'aggressive_cut',      -- -500 calories (lose ~0.5kg/week)
  'moderate_cut',        -- -300 calories
  'mild_cut',            -- -200 calories
  'maintain',            -- Maintenance calories
  'mild_bulk',           -- +200 calories
  'moderate_bulk',       -- +300 calories
  'aggressive_bulk'      -- +500 calories (gain ~0.5kg/week)
));

-- Add comments for documentation
COMMENT ON COLUMN user_profiles.weight_unit IS 'User preferred weight unit: kg or lbs';
COMMENT ON COLUMN user_profiles.height_unit IS 'User preferred height unit: cm or ft (feet/inches)';
COMMENT ON COLUMN user_profiles.activity_level IS 'User activity level for TDEE calculation';
COMMENT ON COLUMN user_profiles.calorie_goal IS 'User calorie goal relative to TDEE maintenance';