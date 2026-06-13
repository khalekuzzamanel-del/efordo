import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { MessagesQueryDto } from './dto/messages-query.dto';
import { Message } from './interfaces/message.interface';

export interface PaginatedMessages {
  data: Message[];
  total: number;
  page: number;
  limit: number;
  total_pages: number;
}

@Injectable()
export class MessagesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findByRoom(
    roomId: string,
    userId: string,
    query: MessagesQueryDto,
  ): Promise<PaginatedMessages> {
    // Verify user is a member of the room
    await this._checkMembership(roomId, userId);

    const page = query.page ?? 1;
    const limit = query.limit ?? 50;
    const offset = (page - 1) * limit;

    // Get total count
    const { count: total, error: countError } = await this.supabaseService.client
      .from('messages')
      .select('*', { count: 'exact', head: true })
      .eq('room_id', roomId);

    if (countError) {
      throw new ForbiddenException('Failed to fetch messages');
    }

    // Get messages
    const { data: messagesData, error } = await this.supabaseService.client
      .from('messages')
      .select('*')
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      throw new ForbiddenException('Failed to fetch messages');
    }

    // Fetch sender profiles separately (messages.sender_id -> auth.users -> profiles.supabase_user_id)
    const senderIds = [...new Set((messagesData ?? []).map((m: any) => m.sender_id))];
    const profileMap = new Map<string, { username: string; display_name: string | null }>();

    if (senderIds.length > 0) {
      const { data: profiles } = await this.supabaseService.client
        .from('profiles')
        .select('supabase_user_id, username, display_name')
        .in('supabase_user_id', senderIds);

      for (const p of profiles ?? []) {
        profileMap.set(p.supabase_user_id, {
          username: p.username,
          display_name: p.display_name,
        });
      }
    }

    const messages = ((messagesData ?? []) as any[]).map((item) => {
      const profile = profileMap.get(item.sender_id);
      return {
        id: item.id,
        room_id: item.room_id,
        sender_id: item.sender_id,
        message_type: item.message_type,
        content: item.content,
        metadata: item.metadata ?? {},
        created_at: item.created_at,
        sender_username: profile?.username ?? 'Unknown',
        sender_display_name: profile?.display_name ?? null,
      };
    }) as Message[];

    return {
      data: messages,
      total: total ?? 0,
      page,
      limit,
      total_pages: total ? Math.ceil(total / limit) : 0,
    };
  }

  async create(
    roomId: string,
    dto: CreateMessageDto,
    userId: string,
  ): Promise<Message> {
    // Verify user is a member of the room
    await this._checkMembership(roomId, userId);

    // Validate content
    const trimmed = dto.content.trim();
    if (!trimmed) {
      throw new BadRequestException('Message cannot be empty');
    }
    if (trimmed.length > 5000) {
      throw new BadRequestException('Message must be at most 5000 characters');
    }

    // Determine message type (future: could detect images, etc.)
    const messageType = 'TEXT';

    // Insert message
    const { data, error } = await this.supabaseService.client
      .from('messages')
      .insert({
        room_id: roomId,
        sender_id: userId,
        message_type: messageType,
        content: trimmed,
        metadata: {},
      })
      .select()
      .single();

    if (error) {
      throw new ForbiddenException(`Failed to send message: ${error.message}`);
    }

    const message = data as any;

    // Fetch sender profile
    const { data: profile } = await this.supabaseService.client
      .from('profiles')
      .select('username, display_name')
      .eq('supabase_user_id', userId)
      .single();

    return {
      id: message.id,
      room_id: message.room_id,
      sender_id: message.sender_id,
      message_type: message.message_type,
      content: message.content,
      metadata: message.metadata ?? {},
      created_at: message.created_at,
      sender_username: profile?.username ?? 'Unknown',
      sender_display_name: profile?.display_name ?? null,
    } as Message;
  }

  private async _checkMembership(roomId: string, userId: string): Promise<void> {
    const { data, error } = await this.supabaseService.client
      .from('room_members')
      .select('id')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new NotFoundException('Room not found or you are not a member');
    }
  }
}
