-- Create parking_active_slots table for daily slot allocation
CREATE TABLE IF NOT EXISTS public.parking_active_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    listing_id UUID NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    active_car_slots INTEGER NOT NULL DEFAULT 0 CHECK (active_car_slots >= 0),
    active_bike_slots INTEGER NOT NULL DEFAULT 0 CHECK (active_bike_slots >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(listing_id, date)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_parking_active_slots_listing_date ON public.parking_active_slots(listing_id, date);
CREATE INDEX IF NOT EXISTS idx_parking_active_slots_date ON public.parking_active_slots(date);

-- Enable Row Level Security
ALTER TABLE public.parking_active_slots ENABLE ROW LEVEL SECURITY;

-- RLS Policies for parking_active_slots table
-- Hosts can view their own active slots
CREATE POLICY "Hosts can view own active slots"
    ON public.parking_active_slots
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.listings
            WHERE listings.id = parking_active_slots.listing_id
            AND listings.host_id = auth.uid()
        )
    );

-- Hosts can insert their own active slots
CREATE POLICY "Hosts can insert own active slots"
    ON public.parking_active_slots
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.listings
            WHERE listings.id = parking_active_slots.listing_id
            AND listings.host_id = auth.uid()
        )
    );

-- Hosts can update their own active slots
CREATE POLICY "Hosts can update own active slots"
    ON public.parking_active_slots
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.listings
            WHERE listings.id = parking_active_slots.listing_id
            AND listings.host_id = auth.uid()
        )
    );

-- Hosts can delete their own active slots
CREATE POLICY "Hosts can delete own active slots"
    ON public.parking_active_slots
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.listings
            WHERE listings.id = parking_active_slots.listing_id
            AND listings.host_id = auth.uid()
        )
    );

-- Create trigger to automatically update updated_at
CREATE TRIGGER on_parking_active_slots_updated
    BEFORE UPDATE ON public.parking_active_slots
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Add comments for documentation
COMMENT ON TABLE public.parking_active_slots IS 'Daily active slot allocations for approved listings';
COMMENT ON COLUMN public.parking_active_slots.listing_id IS 'Reference to the parking listing';
COMMENT ON COLUMN public.parking_active_slots.date IS 'Date for which slots are allocated (YYYY-MM-DD)';
COMMENT ON COLUMN public.parking_active_slots.active_car_slots IS 'Number of car slots active for this date';
COMMENT ON COLUMN public.parking_active_slots.active_bike_slots IS 'Number of bike slots active for this date';
