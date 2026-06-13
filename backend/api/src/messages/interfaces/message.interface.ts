export interface Message {
  id: string;
  room_id: string;
  sender_id: string;
  message_type: string;
  content: string;
  metadata: Record<string, any>;
  created_at: string;
  sender_username?: string;
  sender_display_name?: string;
}
