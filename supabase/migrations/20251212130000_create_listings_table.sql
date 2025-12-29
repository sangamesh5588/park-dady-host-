-- Create listings table for parking space listings
CREATE TABLE IF NOT EXISTS public.listings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    parking_space_name TEXT NOT NULL,
    parking_address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    landmark TEXT,
    parking_type TEXT NOT NULL CHECK (parking_type IN ('Car', 'Bike', 'Both')),
    total_car_slots INTEGER,
    total_bike_slots INTEGER,
    is_24x7 BOOLEAN NOT NULL DEFAULT FALSE,
    open_time TIME,
    close_time TIME,
    amenities TEXT[], -- Array of selected amenities
    parking_photos TEXT[], -- Array of parking photo URLs
    entrance_photo_url TEXT NOT NULL,
    signboard_photo_url TEXT,
    pricing_model TEXT NOT NULL CHECK (pricing_model IN ('Hourly', 'Daily', 'Both')),
    hourly_rate_car DECIMAL(10, 2),
    hourly_rate_bike DECIMAL(10, 2),
    daily_rate_car DECIMAL(10, 2),
    daily_rate_bike DECIMAL(10, 2),
    special_instructions TEXT,
    agreed_to_terms BOOLEAN NOT NULL DEFAULT FALSE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'active', 'inactive')),
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_listings_host_id ON public.listings(host_id);
CREATE INDEX IF NOT EXISTS idx_listings_status ON public.listings(status);
CREATE INDEX IF NOT EXISTS idx_listings_parking_type ON public.listings(parking_type);
CREATE INDEX IF NOT EXISTS idx_listings_latitude_longitude ON public.listings(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_listings_created_at ON public.listings(created_at);

-- Enable Row Level Security
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for listings table
-- Anyone can view approved/active listings (for booking)
CREATE POLICY "Anyone can view approved listings"
    ON public.listings
    FOR SELECT
    USING (status IN ('approved', 'active'));

-- Hosts can view their own listings (including pending)
CREATE POLICY "Hosts can view own listings"
    ON public.listings
    FOR SELECT
    USING (auth.uid() = host_id);

-- Hosts can insert their own listings
CREATE POLICY "Hosts can insert own listings"
    ON public.listings
    FOR INSERT
    WITH CHECK (auth.uid() = host_id);

-- Hosts can update their own listings (only if pending or rejected)
CREATE POLICY "Hosts can update own pending listings"
    ON public.listings
    FOR UPDATE
    USING (auth.uid() = host_id AND status IN ('pending', 'rejected'));

-- Hosts can delete their own listings (only if not approved/active)
CREATE POLICY "Hosts can delete own non-active listings"
    ON public.listings
    FOR DELETE
    USING (auth.uid() = host_id AND status NOT IN ('approved', 'active'));

-- Admin policies (for approving/rejecting listings)
-- Note: Add admin role checks when admin system is implemented

-- Create trigger to automatically update updated_at
CREATE TRIGGER on_listing_updated
    BEFORE UPDATE ON public.listings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Add comments for documentation
COMMENT ON TABLE public.listings IS 'Parking space listings created by hosts';
COMMENT ON COLUMN public.listings.parking_type IS 'Type of parking: Car, Bike, or Both';
COMMENT ON COLUMN public.listings.amenities IS 'Array of selected amenities (CCTV, Security Guard, etc.)';
COMMENT ON COLUMN public.listings.pricing_model IS 'Pricing model: Hourly, Daily, or Both';
COMMENT ON COLUMN public.listings.status IS 'Listing status: pending, approved, rejected, active, inactive';
