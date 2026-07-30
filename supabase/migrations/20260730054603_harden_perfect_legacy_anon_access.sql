-- Existing Supabase projects can carry project-specific default privileges.
-- Keep Perfect's legacy bridge undiscoverable and unreadable to anonymous
-- callers even when those defaults grant SELECT on newly created tables.
revoke all on table public.perfect_items from anon;
