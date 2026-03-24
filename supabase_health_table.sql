-- AI Health Guardian - Supabase Database Tables

-- Health Data Table (existing)
CREATE TABLE IF NOT EXISTS health_data (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bmi DOUBLE PRECISION,
  heart_risk DOUBLE PRECISION,
  sleep_hours DOUBLE PRECISION,
  steps INTEGER,
  date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Symptoms Table (new - for storing previous symptoms)
CREATE TABLE IF NOT EXISTS symptoms (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  symptoms TEXT NOT NULL,
  diagnosis TEXT,
  risk_score DOUBLE PRECISION,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Risk Scores Table (new - for storing risk scores history)
CREATE TABLE IF NOT EXISTS risk_scores (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  risk_type TEXT NOT NULL,
  score DOUBLE PRECISION NOT NULL,
  level TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Health Metrics Table (new - for weekly health trends)
CREATE TABLE IF NOT EXISTS health_metrics (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  bmi DOUBLE PRECISION,
  heart_rate DOUBLE PRECISION,
  blood_pressure DOUBLE PRECISION,
  weight DOUBLE PRECISION,
  sleep_hours DOUBLE PRECISION,
  steps INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Enable Row Level Security
ALTER TABLE health_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE symptoms ENABLE ROW LEVEL SECURITY;
ALTER TABLE risk_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_metrics ENABLE ROW LEVEL SECURITY;

-- Policies for user-specific data access
CREATE POLICY "Users can view own health_data" ON health_data
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health_data" ON health_data
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health_data" ON health_data
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health_data" ON health_data
  FOR DELETE USING (auth.uid() = user_id);

-- Symptoms policies
CREATE POLICY "Users can view own symptoms" ON symptoms
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own symptoms" ON symptoms
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own symptoms" ON symptoms
  FOR DELETE USING (auth.uid() = user_id);

-- Risk Scores policies
CREATE POLICY "Users can view own risk_scores" ON risk_scores
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own risk_scores" ON risk_scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own risk_scores" ON risk_scores
  FOR DELETE USING (auth.uid() = user_id);

-- Health Metrics policies
CREATE POLICY "Users can view own health_metrics" ON health_metrics
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own health_metrics" ON health_metrics
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own health_metrics" ON health_metrics
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own health_metrics" ON health_metrics
  FOR DELETE USING (auth.uid() = user_id);

-- Function to get user health summary
CREATE OR REPLACE FUNCTION get_user_health_summary(user_uuid UUID)
RETURNS TABLE (
  avg_bmi DOUBLE PRECISION,
  avg_heart_risk DOUBLE PRECISION,
  avg_sleep_hours DOUBLE PRECISION,
  avg_steps DOUBLE PRECISION,
  latest_bmi DOUBLE PRECISION,
  latest_heart_risk DOUBLE PRECISION,
  latest_sleep_hours DOUBLE PRECISION,
  latest_steps INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    AVG(hd.bmi)::DOUBLE PRECISION,
    AVG(hd.heart_risk)::DOUBLE PRECISION,
    AVG(hd.sleep_hours)::DOUBLE PRECISION,
    AVG(hd.steps)::DOUBLE PRECISION,
    FIRST_VALUE(hd.bmi) OVER (ORDER BY hd.date DESC)::DOUBLE PRECISION,
    FIRST_VALUE(hd.heart_risk) OVER (ORDER BY hd.date DESC)::DOUBLE PRECISION,
    FIRST_VALUE(hd.sleep_hours) OVER (ORDER BY hd.date DESC)::DOUBLE PRECISION,
    FIRST_VALUE(hd.steps) OVER (ORDER BY hd.date DESC)::INTEGER
  FROM health_data hd
  WHERE hd.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_health_data_user_date ON health_data(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_symptoms_user_created ON symptoms(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_risk_scores_user_created ON risk_scores(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_risk_scores_type ON risk_scores(risk_type);
CREATE INDEX IF NOT EXISTS idx_health_metrics_user_created ON health_metrics(user_id, created_at DESC);
