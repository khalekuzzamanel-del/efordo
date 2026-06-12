import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { Profile } from './interfaces/profile.interface';
import { CreateProfileDto } from './dto/create-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findBySupabaseUserId(supabaseUserId: string): Promise<Profile | null> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .select('*')
      .eq('supabase_user_id', supabaseUserId)
      .single();

    if (error || !data) {
      return null;
    }

    return data as Profile;
  }

  async findByUsername(username: string): Promise<Profile | null> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .select('*')
      .ilike('username', username)
      .single();

    if (error || !data) {
      return null;
    }

    return data as Profile;
  }

  async findByEmail(email: string): Promise<Profile | null> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .select('*')
      .ilike('email', email)
      .single();

    if (error || !data) {
      return null;
    }

    return data as Profile;
  }

  async createProfile(dto: CreateProfileDto, supabaseUserId: string): Promise<Profile> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .insert({
        supabase_user_id: supabaseUserId,
        username: dto.username.toLowerCase(),
        email: dto.email.toLowerCase(),
        display_name: dto.display_name ?? null,
      })
      .select()
      .single();

    if (error) {
      throw new ConflictException(`Failed to create profile: ${error.message}`);
    }

    return data as Profile;
  }

  async isUsernameTaken(username: string): Promise<boolean> {
    const profile = await this.findByUsername(username);
    return profile !== null;
  }

  async isEmailTaken(email: string): Promise<boolean> {
    const profile = await this.findByEmail(email);
    return profile !== null;
  }
}
