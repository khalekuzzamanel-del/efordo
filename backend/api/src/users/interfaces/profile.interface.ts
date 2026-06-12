export interface Profile {
  id: string;
  supabase_user_id: string;
  username: string;
  email: string;
  display_name: string | null;
  created_at: string;
  updated_at: string;
}
