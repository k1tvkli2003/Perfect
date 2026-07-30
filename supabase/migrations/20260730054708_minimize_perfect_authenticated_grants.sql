-- Perfect sync reads change snapshots through its owner-scoped RPC and needs
-- direct SELECT on planner_changes only for Realtime authorization. Owner
-- profiles and durable conflict receipts remain internal RPC implementation
-- details, so remove their otherwise-unused Data API/GraphQL visibility.
revoke select on table public.planner_owner_profiles from authenticated;
revoke select on table public.planner_sync_conflicts from authenticated;
