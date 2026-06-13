import { Injectable, NotFoundException, ForbiddenException, ConflictException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { JoinRoomDto } from './dto/join-room.dto';
import { TransferOwnershipDto } from './dto/transfer-ownership.dto';
import { Room } from './interfaces/room.interface';

@Injectable()
export class RoomsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(userId: string): Promise<Room[]> {
    const { data, error } = await this.supabaseService.client
      .from('rooms')
      .select(`
        *,
        member_count:room_members(count),
        user_role:room_members!inner(role)
      `)
      .eq('room_members.user_id', userId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false });

    if (error) throw new ForbiddenException('Failed to fetch rooms');

    return ((data ?? []) as any[]).map((item) => ({
      ...item,
      member_count: item.member_count?.[0]?.count ?? 0,
      user_role: item.user_role?.[0]?.role ?? null,
    })) as Room[];
  }

  async findOne(id: string, userId: string): Promise<Room> {
    const { data, error } = await this.supabaseService.client
      .from('rooms')
      .select(`
        *,
        member_count:room_members(count),
        user_role:room_members!inner(role)
      `)
      .eq('id', id)
      .eq('room_members.user_id', userId)
      .eq('is_deleted', false)
      .single();

    if (error || !data) throw new NotFoundException('Room not found');

    const room = data as any;
    return {
      ...room,
      member_count: room.member_count?.[0]?.count ?? 0,
      user_role: room.user_role?.[0]?.role ?? null,
    } as Room;
  }

  async create(dto: CreateRoomDto, userId: string): Promise<Room> {
    // The trigger handle_new_room() will auto-assign OWNER role
    const { data, error } = await this.supabaseService.client
      .from('rooms')
      .insert({
        name: dto.name,
        description: dto.description ?? null,
        created_by: userId,
      })
      .select()
      .single();

    if (error) throw new ForbiddenException(`Failed to create room: ${error.message}`);
    return data as Room;
  }

  async update(id: string, dto: UpdateRoomDto, userId: string): Promise<Room> {
    // Verify access and role
    await this._checkAdminOrOwner(id, userId);

    const updateData: Record<string, any> = {};
    if (dto.name !== undefined) updateData.name = dto.name;
    if (dto.description !== undefined) updateData.description = dto.description;

    const { data, error } = await this.supabaseService.client
      .from('rooms')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to update room');
    return data as Room;
  }

  async remove(id: string, userId: string): Promise<void> {
    // Verify owner
    await this._checkOwner(id, userId);

    const { error } = await this.supabaseService.client
      .from('rooms')
      .update({ is_deleted: true })
      .eq('id', id);

    if (error) throw new ForbiddenException('Failed to delete room');
  }

  async join(dto: JoinRoomDto, userId: string): Promise<Room> {
    // Find room by invite code
    const { data: room, error: roomError } = await this.supabaseService.client
      .from('rooms')
      .select('*')
      .eq('invite_code', dto.invite_code)
      .eq('is_deleted', false)
      .single();

    if (roomError || !room) throw new NotFoundException('Invalid invite code');

    // Check if already a member
    const { data: existing } = await this.supabaseService.client
      .from('room_members')
      .select('id')
      .eq('room_id', room.id)
      .eq('user_id', userId)
      .single();

    if (existing) throw new ConflictException('You are already a member of this room');

    // Add member
    const { error: joinError } = await this.supabaseService.client
      .from('room_members')
      .insert({
        room_id: room.id,
        user_id: userId,
        role: 'MEMBER',
      });

    if (joinError) throw new ForbiddenException(`Failed to join room: ${joinError.message}`);

    return room as Room;
  }

  async leave(id: string, userId: string): Promise<void> {
    // Check if user is the owner
    const { data: membership } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', id)
      .eq('user_id', userId)
      .single();

    if (!membership) throw new NotFoundException('You are not a member of this room');

    if (membership.role === 'OWNER') {
      throw new BadRequestException('Owner cannot leave. Transfer ownership first.');
    }

    const { error } = await this.supabaseService.client
      .from('room_members')
      .delete()
      .eq('room_id', id)
      .eq('user_id', userId);

    if (error) throw new ForbiddenException('Failed to leave room');
  }

  async transferOwnership(id: string, dto: TransferOwnershipDto, userId: string): Promise<void> {
    // Verify current user is owner
    await this._checkOwner(id, userId);

    // Verify new owner is a member
    const { data: newOwnerMembership, error: memberError } = await this.supabaseService.client
      .from('room_members')
      .select('id, role')
      .eq('room_id', id)
      .eq('user_id', dto.new_owner_id)
      .single();

    if (memberError || !newOwnerMembership) {
      throw new NotFoundException('New owner is not a member of this room');
    }

    // Demote current owner to ADMIN
    const { error: demoteError } = await this.supabaseService.client
      .from('room_members')
      .update({ role: 'ADMIN' })
      .eq('room_id', id)
      .eq('user_id', userId);

    if (demoteError) throw new ForbiddenException('Failed to transfer ownership');

    // Promote new owner to OWNER
    const { error: promoteError } = await this.supabaseService.client
      .from('room_members')
      .update({ role: 'OWNER' })
      .eq('room_id', id)
      .eq('user_id', dto.new_owner_id);

    if (promoteError) {
      // Rollback: restore previous owner
      await this.supabaseService.client
        .from('room_members')
        .update({ role: 'OWNER' })
        .eq('room_id', id)
        .eq('user_id', userId);
      throw new ForbiddenException('Failed to transfer ownership');
    }

    // Update created_by to reflect new owner
    const { error: updateRoomError } = await this.supabaseService.client
      .from('rooms')
      .update({ created_by: dto.new_owner_id })
      .eq('id', id);

    if (updateRoomError) {
      // Non-critical: log but don't throw
      console.error('Failed to update room created_by after ownership transfer');
    }
  }

  async regenerateInviteCode(id: string, userId: string): Promise<{ invite_code: string }> {
    await this._checkAdminOrOwner(id, userId);

    // Generate new invite code using the DB function
    const { data, error } = await this.supabaseService.client.rpc('generate_invite_code');

    if (error) throw new ForbiddenException('Failed to generate invite code');

    const code = data as string;

    // Update room with new code
    const { error: updateError } = await this.supabaseService.client
      .from('rooms')
      .update({ invite_code: code })
      .eq('id', id);

    if (updateError) throw new ForbiddenException('Failed to update invite code');

    return { invite_code: code };
  }

  async getMembers(roomId: string, userId: string): Promise<any[]> {
    // Verify user is a member
    await this._checkMember(roomId, userId);

    const { data, error } = await this.supabaseService.client
      .from('room_members')
      .select(`
        id,
        role,
        joined_at,
        user_id,
        profiles:user_id!inner(
          username,
          display_name,
          email
        )
      `)
      .eq('room_id', roomId)
      .order('joined_at', { ascending: true });

    if (error) throw new ForbiddenException('Failed to fetch members');

    return (data ?? []).map((item: any) => ({
      id: item.id,
      user_id: item.user_id,
      role: item.role,
      joined_at: item.joined_at,
      username: item.profiles?.username ?? 'Unknown',
      display_name: item.profiles?.display_name ?? null,
      email: item.profiles?.email ?? '',
    }));
  }

  async promoteMember(roomId: string, targetUserId: string, userId: string): Promise<void> {
    // Only owner can promote
    await this._checkOwner(roomId, userId);

    const { data: membership } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', targetUserId)
      .single();

    if (!membership) throw new NotFoundException('Member not found');
    if (membership.role === 'OWNER') throw new BadRequestException('Cannot promote the owner');
    if (membership.role === 'ADMIN') throw new BadRequestException('User is already an admin');

    const { error } = await this.supabaseService.client
      .from('room_members')
      .update({ role: 'ADMIN' })
      .eq('room_id', roomId)
      .eq('user_id', targetUserId);

    if (error) throw new ForbiddenException('Failed to promote member');
  }

  async demoteMember(roomId: string, targetUserId: string, userId: string): Promise<void> {
    // Only owner can demote
    await this._checkOwner(roomId, userId);

    const { data: membership } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', targetUserId)
      .single();

    if (!membership) throw new NotFoundException('Member not found');
    if (membership.role === 'OWNER') throw new BadRequestException('Cannot demote the owner');
    if (membership.role === 'MEMBER') throw new BadRequestException('User is already a member');

    const { error } = await this.supabaseService.client
      .from('room_members')
      .update({ role: 'MEMBER' })
      .eq('room_id', roomId)
      .eq('user_id', targetUserId);

    if (error) throw new ForbiddenException('Failed to demote member');
  }

  async removeMember(roomId: string, targetUserId: string, userId: string): Promise<void> {
    // Check if actor is OWNER or ADMIN
    const { data: actorMembership } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!actorMembership) throw new NotFoundException('You are not a member of this room');

    // Check target is a member
    const { data: targetMembership } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', targetUserId)
      .single();

    if (!targetMembership) throw new NotFoundException('Target user is not a member');

    // ADMIN cannot remove OWNER
    if (actorMembership.role === 'ADMIN' && targetMembership.role === 'OWNER') {
      throw new ForbiddenException('Admins cannot remove the owner');
    }

    // MEMBER cannot remove anyone
    if (actorMembership.role === 'MEMBER') {
      throw new ForbiddenException('Only owners and admins can remove members');
    }

    const { error } = await this.supabaseService.client
      .from('room_members')
      .delete()
      .eq('room_id', roomId)
      .eq('user_id', targetUserId);

    if (error) throw new ForbiddenException('Failed to remove member');
  }

  // --- Helper methods ---

  private async _checkMember(roomId: string, userId: string): Promise<void> {
    const { data } = await this.supabaseService.client
      .from('room_members')
      .select('id')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!data) throw new NotFoundException('Room not found or you are not a member');
  }

  private async _checkAdminOrOwner(roomId: string, userId: string): Promise<void> {
    const { data } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!data) throw new NotFoundException('Room not found');
    if (data.role !== 'OWNER' && data.role !== 'ADMIN') {
      throw new ForbiddenException('Only owners and admins can perform this action');
    }
  }

  private async _checkOwner(roomId: string, userId: string): Promise<void> {
    const { data } = await this.supabaseService.client
      .from('room_members')
      .select('role')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!data) throw new NotFoundException('Room not found');
    if (data.role !== 'OWNER') {
      throw new ForbiddenException('Only the owner can perform this action');
    }
  }
}
