import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import WebSocket from 'ws';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private _client!: SupabaseClient;
  private _adminClient!: SupabaseClient;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): void {
    const url = this.configService.get<string>('SUPABASE_URL');
    const anonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
    const serviceRoleKey = this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');

    if (!url || !anonKey) {
      throw new Error(
        'Supabase credentials are not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file.',
      );
    }

    this._client = createClient(url, anonKey, {
      realtime: { transport: WebSocket as any },
    });

    if (serviceRoleKey) {
      this._adminClient = createClient(url, serviceRoleKey, {
        realtime: { transport: WebSocket as any },
      });
    }
  }

  /**
   * Standard client – uses anon key (respects RLS).
   * Use for all user-facing operations.
   */
  get client(): SupabaseClient {
    return this._client;
  }

  /**
   * Admin client – uses service_role key (bypasses RLS).
   * Use only for server-side operations like profile creation during registration.
   * Never expose this client or the service_role key to the frontend.
   */
  get adminClient(): SupabaseClient {
    if (!this._adminClient) {
      throw new Error(
        'Supabase admin client is not available. Set SUPABASE_SERVICE_ROLE_KEY in your .env file.',
      );
    }
    return this._adminClient;
  }
}
