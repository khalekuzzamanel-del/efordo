export interface Workspace {
  id: string;
  user_id: string;
  name: string;
  description: string | null;
  icon: string | null;
  color: string | null;
  is_archived: boolean;
  created_at: string;
  updated_at: string;
  project_count?: number;
}
