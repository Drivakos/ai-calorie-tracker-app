-- Add food preferences and allergies for AI diet recommendations
ALTER TABLE user_profiles
ADD COLUMN preferred_foods TEXT[] DEFAULT '{}',
ADD COLUMN allergies TEXT[] DEFAULT '{}',
ADD COLUMN dietary_restrictions TEXT[] DEFAULT '{}';

-- Add comments for documentation
COMMENT ON COLUMN user_profiles.preferred_foods IS 'Array of foods the user prefers/enjoys';
COMMENT ON COLUMN user_profiles.allergies IS 'Array of food allergies (e.g., peanuts, shellfish, dairy)';
COMMENT ON COLUMN user_profiles.dietary_restrictions IS 'Array of dietary restrictions (e.g., vegetarian, vegan, halal, kosher, gluten-free)';

-- Create index for searching preferences (optional, for future use)
CREATE INDEX idx_user_profiles_allergies ON user_profiles USING GIN (allergies);
CREATE INDEX idx_user_profiles_dietary_restrictions ON user_profiles USING GIN (dietary_restrictions);
