export interface Project {
  id: string;
  workspace_id: string;
  user_id: string;
  name: string;
  description: string | null;
  status: 'active' | 'on_hold' | 'completed';
  color: string | null;
  icon: string | null;
  is_archived: boolean;
  created_at: string;
  updated_at: string;
}
