-- Add foreign key constraints to bookings table if they don't exist

-- Add foreign key for renter_id -> profiles(id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'bookings_renter_id_fkey'
        AND table_name = 'bookings'
    ) THEN
        ALTER TABLE public.bookings
        ADD CONSTRAINT bookings_renter_id_fkey
        FOREIGN KEY (renter_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key for host_id -> profiles(id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'bookings_host_id_fkey'
        AND table_name = 'bookings'
    ) THEN
        ALTER TABLE public.bookings
        ADD CONSTRAINT bookings_host_id_fkey
        FOREIGN KEY (host_id)
        REFERENCES public.profiles(id)
        ON DELETE CASCADE;
    END IF;
END $$;

-- Add foreign key for listing_id -> listings(id)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'bookings_listing_id_fkey'
        AND table_name = 'bookings'
    ) THEN
        ALTER TABLE public.bookings
        ADD CONSTRAINT bookings_listing_id_fkey
        FOREIGN KEY (listing_id)
        REFERENCES public.listings(id)
        ON DELETE CASCADE;
    END IF;
END $$;
