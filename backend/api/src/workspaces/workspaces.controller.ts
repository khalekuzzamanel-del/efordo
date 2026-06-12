import {
  Controller, Get, Post, Patch, Delete, Body, Param, Req,
  UseGuards, HttpCode, HttpStatus, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { WorkspacesService } from './workspaces.service';
import { CreateWorkspaceDto } from './dto/create-workspace.dto';
import { UpdateWorkspaceDto } from './dto/update-workspace.dto';
import { JwtGuard } from '../auth/guards/jwt.guard';

@ApiTags('Workspaces')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller('workspaces')
export class WorkspacesController {
  constructor(private readonly workspacesService: WorkspacesService) {}

  @Get()
  @ApiOperation({ summary: 'List all workspaces' })
  @ApiQuery({ name: 'includeArchived', required: false, type: Boolean })
  findAll(@Req() req: any, @Query('includeArchived') includeArchived?: string) {
    return this.workspacesService.findAll(req.user.id, includeArchived === 'true');
  }

  @Post()
  @ApiOperation({ summary: 'Create a workspace' })
  @ApiBody({ type: CreateWorkspaceDto })
  create(@Req() req: any, @Body() dto: CreateWorkspaceDto) {
    return this.workspacesService.create(dto, req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get workspace by ID' })
  findOne(@Req() req: any, @Param('id') id: string) {
    return this.workspacesService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update workspace' })
  @ApiBody({ type: UpdateWorkspaceDto })
  update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateWorkspaceDto) {
    return this.workspacesService.update(id, dto, req.user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete workspace' })
  remove(@Req() req: any, @Param('id') id: string) {
    return this.workspacesService.remove(id, req.user.id);
  }

  @Post(':id/archive')
  @ApiOperation({ summary: 'Archive workspace' })
  archive(@Req() req: any, @Param('id') id: string) {
    return this.workspacesService.archive(id, req.user.id);
  }

  @Post(':id/restore')
  @ApiOperation({ summary: 'Restore archived workspace' })
  restore(@Req() req: any, @Param('id') id: string) {
    return this.workspacesService.restore(id, req.user.id);
  }
}
