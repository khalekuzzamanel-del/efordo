import { Injectable, ConflictException, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { UsersService } from '../users/users.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AuthResponse } from './interfaces/auth-response.interface';

@Injectable()
export class AuthService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly usersService: UsersService,
  ) {}

  async register(dto: RegisterDto): Promise<{ message: string }> {
    // Validate username
    const usernameRegex = /^[a-z0-9_]+$/;
    if (!usernameRegex.test(dto.username.toLowerCase())) {
      throw new BadRequestException(
        'Username must contain only lowercase letters, numbers, and underscores',
      );
    }
    if (dto.username.length < 3 || dto.username.length > 30) {
      throw new BadRequestException('Username must be between 3 and 30 characters');
    }

    // Validate email
    const emailRegex = /^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$/;
    if (!emailRegex.test(dto.email)) {
      throw new BadRequestException('Please provide a valid email address');
    }

    // Validate password
    if (!dto.password || dto.password.length < 8) {
      throw new BadRequestException('Password must be at least 8 characters');
    }

    // Normalize
    const normalizedUsername = dto.username.toLowerCase();
    const normalizedEmail = dto.email.toLowerCase().trim();

    // Check uniqueness
    const usernameTaken = await this.usersService.isUsernameTaken(normalizedUsername);
    if (usernameTaken) {
      throw new ConflictException('Username is already taken');
    }

    const emailTaken = await this.usersService.isEmailTaken(normalizedEmail);
    if (emailTaken) {
      throw new ConflictException('Email is already registered');
    }

    // Create Supabase Auth user
    const { data: authData, error: authError } = await this.supabaseService.client.auth.signUp({
      email: normalizedEmail,
      password: dto.password,
    });

    if (authError) {
      throw new BadRequestException(`Registration failed: ${authError.message}`);
    }

    if (!authData.user) {
      throw new BadRequestException('Registration failed: No user returned');
    }

    // Create profile record using admin client (bypasses RLS)
    await this.usersService.createProfile(
      {
        username: normalizedUsername,
        email: normalizedEmail,
      },
      authData.user.id,
    );

    return { message: 'Registration successful' };
  }

  async login(dto: LoginDto): Promise<AuthResponse> {
    // Determine if identifier is username or email
    const isEmail = dto.identifier.includes('@');
    let email: string;

    if (isEmail) {
      email = dto.identifier.toLowerCase().trim();
    } else {
      // It's a username - find the associated email
      const profile = await this.usersService.findByUsername(dto.identifier.toLowerCase());
      if (!profile) {
        throw new UnauthorizedException('Invalid credentials');
      }
      email = profile.email;
    }

    // Authenticate with Supabase
    const { data: authData, error: authError } =
      await this.supabaseService.client.auth.signInWithPassword({
        email,
        password: dto.password,
      });

    if (authError || !authData.session) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Get profile
    const profile = await this.usersService.findBySupabaseUserId(authData.user.id);

    return {
      access_token: authData.session.access_token,
      refresh_token: authData.session.refresh_token,
      user: {
        id: authData.user.id,
        email: authData.user.email ?? email,
        username: profile?.username ?? '',
        display_name: profile?.display_name ?? null,
      },
    };
  }

  async getCurrentUser(supabaseUserId: string): Promise<AuthResponse['user'] | null> {
    const profile = await this.usersService.findBySupabaseUserId(supabaseUserId);
    if (!profile) {
      return null;
    }

    return {
      id: supabaseUserId,
      email: profile.email,
      username: profile.username,
      display_name: profile.display_name,
    };
  }

  async logout(): Promise<{ message: string }> {
    const { error } = await this.supabaseService.client.auth.signOut();

    if (error) {
      throw new BadRequestException(`Logout failed: ${error.message}`);
    }

    return { message: 'Logged out successfully' };
  }
}
