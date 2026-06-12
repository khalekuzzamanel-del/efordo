import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService implements OnModuleInit {
  private _client!: SupabaseClient;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): void {
    const url = this.configService.get<string>('SUPABASE_URL');
    const anonKey = this.configService.get<string>('SUPABASE_ANON_KEY');

    if (!url || !anonKey) {
      throw new Error(
        'Supabase credentials are not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file.',
      );
    }

    this._client = createClient(url, anonKey);
  }

  get client(): SupabaseClient {
    return this._client;
  }
}
