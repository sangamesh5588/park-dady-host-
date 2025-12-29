-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    role TEXT NOT NULL DEFAULT 'host' CHECK (role IN ('host', 'guest')),
    onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    permissions_granted JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for profiles table
-- Users can read their own profile
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Create function to automatically create profile on user signup
-- Note: This sets role to 'host' for the HOST APP
-- The same user can have different roles in different apps
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role)
    VALUES (
        NEW.id,
        NEW.email,
        'host'
    )
    ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to call the function when a new user signs up
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER on_profile_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create parking_spots table (for host functionality)
CREATE TABLE IF NOT EXISTS public.parking_spots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    host_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    zip_code TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    price_per_hour DECIMAL(10, 2) NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    images TEXT[], -- Array of image URLs
    amenities TEXT[], -- Array of amenities (e.g., 'covered', 'security', 'ev_charging')
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for parking_spots
ALTER TABLE public.parking_spots ENABLE ROW LEVEL SECURITY;

-- Policies for parking_spots
-- Anyone can view available parking spots
CREATE POLICY "Anyone can view available parking spots"
    ON public.parking_spots
    FOR SELECT
    USING (is_available = TRUE);

-- Hosts can view their own parking spots
CREATE POLICY "Hosts can view own parking spots"
    ON public.parking_spots
    FOR SELECT
    USING (auth.uid() = host_id);

-- Hosts can insert their own parking spots
CREATE POLICY "Hosts can insert own parking spots"
    ON public.parking_spots
    FOR INSERT
    WITH CHECK (auth.uid() = host_id);

-- Hosts can update their own parking spots
CREATE POLICY "Hosts can update own parking spots"
    ON public.parking_spots
    FOR UPDATE
    USING (auth.uid() = host_id);

-- Hosts can delete their own parking spots
CREATE POLICY "Hosts can delete own parking spots"
    ON public.parking_spots
    FOR DELETE
    USING (auth.uid() = host_id);

-- Create trigger for parking_spots updated_at
CREATE TRIGGER on_parking_spot_updated
    BEFORE UPDATE ON public.parking_spots
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create bookings table
CREATE TABLE IF NOT EXISTS public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parking_spot_id UUID REFERENCES public.parking_spots(id) ON DELETE CASCADE NOT NULL,
    guest_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    host_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security for bookings
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Policies for bookings
-- Guests can view their own bookings
CREATE POLICY "Guests can view own bookings"
    ON public.bookings
    FOR SELECT
    USING (auth.uid() = guest_id);

-- Hosts can view bookings for their parking spots
CREATE POLICY "Hosts can view bookings for their spots"
    ON public.bookings
    FOR SELECT
    USING (auth.uid() = host_id);

-- Guests can create bookings
CREATE POLICY "Guests can create bookings"
    ON public.bookings
    FOR INSERT
    WITH CHECK (auth.uid() = guest_id);

-- Guests can update their own bookings (to cancel)
CREATE POLICY "Guests can update own bookings"
    ON public.bookings
    FOR UPDATE
    USING (auth.uid() = guest_id);

-- Hosts can update bookings for their parking spots
CREATE POLICY "Hosts can update bookings for their spots"
    ON public.bookings
    FOR UPDATE
    USING (auth.uid() = host_id);

-- Create trigger for bookings updated_at
CREATE TRIGGER on_booking_updated
    BEFORE UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
