-- Add new columns for custom locations
ALTER TABLE public.driver_routes
ADD COLUMN IF NOT EXISTS departure text,
ADD COLUMN IF NOT EXISTS destination text,
ADD COLUMN IF NOT EXISTS departure_latitude double precision,
ADD COLUMN IF NOT EXISTS departure_longitude double precision,
ADD COLUMN IF NOT EXISTS destination_latitude double precision,
ADD COLUMN IF NOT EXISTS destination_longitude double precision,
ADD COLUMN IF NOT EXISTS departure_time timestamp with time zone,
ADD COLUMN IF NOT EXISTS arrival_time timestamp with time zone,
ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP;

-- Make station columns nullable if they exist
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'driver_routes' 
        AND column_name = 'start_station'
    ) THEN
        ALTER TABLE public.driver_routes
        ALTER COLUMN start_station DROP NOT NULL,
        ALTER COLUMN end_station DROP NOT NULL,
        ALTER COLUMN start_station_id DROP NOT NULL,
        ALTER COLUMN end_station_id DROP NOT NULL;
    END IF;
END $$;

-- Add constraints
ALTER TABLE public.driver_routes
ADD CONSTRAINT IF NOT EXISTS check_status CHECK (status IN ('pending', 'active', 'completed', 'cancelled'));

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_driver_routes_driver_id ON public.driver_routes(driver_id);
CREATE INDEX IF NOT EXISTS idx_driver_routes_bus_id ON public.driver_routes(bus_id);
CREATE INDEX IF NOT EXISTS idx_driver_routes_status ON public.driver_routes(status);
CREATE INDEX IF NOT EXISTS idx_driver_routes_departure_time ON public.driver_routes(departure_time);
CREATE INDEX IF NOT EXISTS idx_driver_routes_arrival_time ON public.driver_routes(arrival_time);
CREATE INDEX IF NOT EXISTS idx_driver_routes_created_at ON public.driver_routes(created_at);

-- Add comments for clarity
COMMENT ON COLUMN public.driver_routes.departure IS 'Name of departure location (can be station or custom location)';
COMMENT ON COLUMN public.driver_routes.destination IS 'Name of destination location (can be station or custom location)';
COMMENT ON COLUMN public.driver_routes.departure_latitude IS 'Latitude of departure point';
COMMENT ON COLUMN public.driver_routes.departure_longitude IS 'Longitude of departure point';
COMMENT ON COLUMN public.driver_routes.destination_latitude IS 'Latitude of destination point';
COMMENT ON COLUMN public.driver_routes.destination_longitude IS 'Longitude of destination point';
COMMENT ON COLUMN public.driver_routes.departure_time IS 'Scheduled departure time';
COMMENT ON COLUMN public.driver_routes.arrival_time IS 'Scheduled arrival time';
COMMENT ON COLUMN public.driver_routes.status IS 'Status of the trip (pending, active, completed, cancelled)';
COMMENT ON COLUMN public.driver_routes.created_at IS 'Timestamp when the trip was created';

-- Add RLS policy to allow drivers to delete their own trips
ALTER TABLE public.driver_routes ENABLE ROW LEVEL SECURITY;
CREATE POLICY IF NOT EXISTS "Allow drivers to delete their own trips"
  ON public.driver_routes
  FOR DELETE
  TO authenticated
  USING (auth.uid() = driver_id);
