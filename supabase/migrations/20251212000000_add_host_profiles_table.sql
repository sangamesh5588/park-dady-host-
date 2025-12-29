-- Create host_profiles table for storing host onboarding data and approval status
CREATE TABLE IF NOT EXISTS public.host_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    identity_proof_url TEXT,
    profile_photo_url TEXT,
    business_type TEXT NOT NULL CHECK (business_type IN ('Individual', 'Company')),
    company_name TEXT,
    gst_number TEXT,
    udyam_id TEXT,
    business_address_proof_url TEXT,
    udyam_certificate_url TEXT,
    account_holder_name TEXT NOT NULL,
    bank_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    ifsc_code TEXT NOT NULL,
    cancelled_cheque_url TEXT,
    manager_name TEXT NOT NULL,
    manager_phone TEXT NOT NULL,
    manager_email TEXT,
    status TEXT NOT NULL DEFAULT 'pending_approval' CHECK (status IN ('pending_approval', 'approved', 'rejected')),
    rejection_reason TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_host_profiles_user_id ON public.host_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_host_profiles_status ON public.host_profiles(status);
CREATE INDEX IF NOT EXISTS idx_host_profiles_created_at ON public.host_profiles(created_at);

-- Enable Row Level Security
ALTER TABLE public.host_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for host_profiles table
-- Users can view their own host profile
CREATE POLICY "Users can view own host profile"
    ON public.host_profiles
    FOR SELECT
    USING (auth.uid() = user_id);

-- Users can insert their own host profile
CREATE POLICY "Users can insert own host profile"
    ON public.host_profiles
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own host profile (only if pending)
CREATE POLICY "Users can update own pending host profile"
    ON public.host_profiles
    FOR UPDATE
    USING (auth.uid() = user_id AND status = 'pending_approval');

-- Admin/Reviewer policies (assuming reviewers have a special role or we can add later)
-- For now, allow users to see their own, but in production you'd want admin access

-- Create trigger to automatically update updated_at
CREATE TRIGGER on_host_profile_updated
    BEFORE UPDATE ON public.host_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Add comments for documentation
COMMENT ON TABLE public.host_profiles IS 'Stores host onboarding information and approval status';
COMMENT ON COLUMN public.host_profiles.status IS 'Approval status: pending_approval, approved, or rejected';
COMMENT ON COLUMN public.host_profiles.rejection_reason IS 'Reason for rejection if status is rejected';
COMMENT ON COLUMN public.host_profiles.reviewed_by IS 'User ID of the admin who reviewed this profile';
COMMENT ON COLUMN public.host_profiles.reviewed_at IS 'Timestamp when the profile was reviewed';
