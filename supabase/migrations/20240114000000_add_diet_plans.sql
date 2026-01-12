-- Add diet_plans table for persisting weekly diet plans
CREATE TABLE IF NOT EXISTS diet_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_data JSONB NOT NULL,
    macro_targets JSONB NOT NULL,
    meals_per_day INTEGER NOT NULL DEFAULT 3,
    avoided_allergens TEXT[] DEFAULT '{}',
    dietary_restrictions TEXT[] DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT true,
    week_start_date DATE,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index for faster user queries
CREATE INDEX IF NOT EXISTS idx_diet_plans_user_id ON diet_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_diet_plans_active ON diet_plans(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_diet_plans_week_start ON diet_plans(user_id, week_start_date);

-- Enable RLS
ALTER TABLE diet_plans ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view their own diet plans"
    ON diet_plans FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own diet plans"
    ON diet_plans FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own diet plans"
    ON diet_plans FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own diet plans"
    ON diet_plans FOR DELETE
    USING (auth.uid() = user_id);

-- Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_diet_plans_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS trigger_diet_plans_updated_at ON diet_plans;
CREATE TRIGGER trigger_diet_plans_updated_at
    BEFORE UPDATE ON diet_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_diet_plans_updated_at();
