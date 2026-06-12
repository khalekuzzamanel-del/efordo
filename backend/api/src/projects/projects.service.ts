import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { Project } from './interfaces/project.interface';

@Injectable()
export class ProjectsService {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(userId: string, workspaceId?: string, includeArchived = false): Promise<Project[]> {
    let query = this.supabaseService.client
      .from('projects')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (workspaceId) {
      query = query.eq('workspace_id', workspaceId);
    }

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    const { data, error } = await query;
    if (error) throw new ForbiddenException('Failed to fetch projects');
    return (data ?? []) as Project[];
  }

  async findOne(id: string, userId: string): Promise<Project> {
    const { data, error } = await this.supabaseService.client
      .from('projects')
      .select('*')
      .eq('id', id)
      .eq('user_id', userId)
      .single();

    if (error || !data) throw new NotFoundException('Project not found');
    return data as Project;
  }

  async create(dto: CreateProjectDto, userId: string): Promise<Project> {
    const { data, error } = await this.supabaseService.client
      .from('projects')
      .insert({
        workspace_id: dto.workspace_id,
        user_id: userId,
        name: dto.name,
        description: dto.description ?? null,
        status: dto.status ?? 'active',
        color: dto.color ?? null,
        icon: dto.icon ?? null,
      })
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to create project');
    return data as Project;
  }

  async update(id: string, dto: UpdateProjectDto, userId: string): Promise<Project> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('projects')
      .update({
        ...(dto.workspace_id !== undefined && { workspace_id: dto.workspace_id }),
        ...(dto.name !== undefined && { name: dto.name }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.status !== undefined && { status: dto.status }),
        ...(dto.color !== undefined && { color: dto.color }),
        ...(dto.icon !== undefined && { icon: dto.icon }),
      })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to update project');
    return data as Project;
  }

  async remove(id: string, userId: string): Promise<void> {
    await this.findOne(id, userId);
    const { error } = await this.supabaseService.client
      .from('projects')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

    if (error) throw new ForbiddenException('Failed to delete project');
  }

  async archive(id: string, userId: string): Promise<Project> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('projects')
      .update({ is_archived: true })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to archive project');
    return data as Project;
  }

  async restore(id: string, userId: string): Promise<Project> {
    await this.findOne(id, userId);
    const { data, error } = await this.supabaseService.client
      .from('projects')
      .update({ is_archived: false })
      .eq('id', id)
      .eq('user_id', userId)
      .select()
      .single();

    if (error) throw new ForbiddenException('Failed to restore project');
    return data as Project;
  }

  async countByWorkspace(workspaceId: string, userId: string): Promise<number> {
    const { count, error } = await this.supabaseService.client
      .from('projects')
      .select('*', { count: 'exact', head: true })
      .eq('workspace_id', workspaceId)
      .eq('user_id', userId);

    if (error) return 0;
    return count ?? 0;
  }
}
