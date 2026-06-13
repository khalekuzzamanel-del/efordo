export interface Room {
  id: string;
  name: string;
  description: string | null;
  invite_code: string;
  created_by: string;
  is_deleted: boolean;
  created_at: string;
  updated_at: string;
  member_count?: number;
  user_role?: string;
}
