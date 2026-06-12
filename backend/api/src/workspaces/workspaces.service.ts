import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';
import { UpdateWorkspaceDto } from './dto/update-workspace.dto';
import { Workspace } from './interfaces/workspace.interface';

@Injectable()
export class WorkspacesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(userId: string, includeArchived = false): Promise<Workspace[]> {
    let query = this.supabaseService.client
      .from('workspaces')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    const { data, error } = await query;
    if (error) throw new ForbiddenException('Failed to fetch workspaces');

    const workspaces = (data ?? []) as Workspace[];

    // Attach project counts for each workspace
    const { data: counts } = await this.supabaseService.client
      .from('projects')
      .select('workspace_id')
      .eq('user_id', userId)
      .in('workspace_id', workspaces.map((w) => w.id));

    const countMap = new Map<string, number>();
    for (const row of counts ?? []) {
      countMap.set(row.workspace_id, (countMap.get(row.workspace_id) ?? 0) + 1);
    }

    return workspaces.map((w) => ({
      ...w,
      project_count: countMap.get(w.id) ?? 0,
    })) as Workspace[];
  }

  async findOne(id: string, userId: string): Promise<Workspace> {
    const { data, error } = await this.supabaseService.client
      .from('workspaces')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error || !data) throw new NotFoundException('Workspace not found');

    // Count projects in this workspace
    const { count } = await this.supabaseService.client
      .from('projects')
      .select('*', { count: 'exact', head: true })
      .eq('workspace_id', id)
      .eq('user_id', userId);

    return { ...data, project_count: count ?? 0 } as Workspace;
  }

  async create(dto: CreateWorkspaceDto, userId: string): Promise<Workspace> {
    const { data, error } = await this.supabaseService.client
      .from('workspaces')
      .insert({
        user_id: userId,
        name: dto.name,
        description: dto.description ?? null,
        icon: dto.icon ?? null,
        color: dto.color ?? null,
      })
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to create workspace');
    return data as Workspace;
  }

  async update(id: string, dto: UpdateWorkspaceDto, userId: string): Promise<Workspace> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('workspaces')
      .update({
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.icon !== undefined && { icon: dto.icon }),
        ...(dto.color !== undefined && { color: dto.color }),
      })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to update workspace');
    return data as Workspace;
  }

  async remove(id: string, userId: string): Promise<void> {
    await this.findOne(id, userId);
    const { error } = await this.supabaseService.client
      .from('workspaces')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) throw new ForbiddenException('Failed to delete workspace');
  }

  async archive(id: string, userId: string): Promise<Workspace> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('workspaces')
      .update({ is_archived: true })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to archive workspace');
    return data as Workspace;
  }

  async restore(id: string, userId: string): Promise<Workspace> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('workspaces')
      .update({ is_archived: false })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to restore workspace');
    return data as Workspace;
  }
}
