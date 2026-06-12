import {
  Controller, Get, Post, Patch, Delete, Body, Param, Req,
  UseGuards, HttpCode, HttpStatus, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { ProjectsService } from './projects.service';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';
import { JwtGuard } from '../auth/guards/jwt.guard';

@ApiTags('Projects')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller('projects')
export class ProjectsController {
  constructor(private readonly projectsService: ProjectsService) {}

  @Get()
  @ApiOperation({ summary: 'List all projects' })
  @ApiQuery({ name: 'workspaceId', required: false })
  @ApiQuery({ name: 'includeArchived', required: false, type: Boolean })
  findAll(
    @Req() req: any,
    @Query('workspaceId') workspaceId?: string,
    @Query('includeArchived') includeArchived?: string,
  ) {
    return this.projectsService.findAll(req.user.id, workspaceId, includeArchived === 'true');
  }

  @Post()
  @ApiOperation({ summary: 'Create a project' })
  @ApiBody({ type: CreateProjectDto })
  create(@Req() req: any, @Body() dto: CreateProjectDto) {
    return this.projectsService.create(dto, req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get project by ID' })
  findOne(@Req() req: any, @Param('id') id: string) {
    return this.projectsService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update project' })
  @ApiBody({ type: UpdateProjectDto })
  update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateProjectDto) {
    return this.projectsService.update(id, dto, req.user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete project' })
  remove(@Req() req: any, @Param('id') id: string) {
    return this.projectsService.remove(id, req.user.id);
  }

  @Post(':id/archive')
  @ApiOperation({ summary: 'Archive project' })
  archive(@Req() req: any, @Param('id') id: string) {
    return this.projectsService.archive(id, req.user.id);
  }

  @Post(':id/restore')
  @ApiOperation({ summary: 'Restore archived project' })
  restore(@Req() req: any, @Param('id') id: string) {
    return this.projectsService.restore(id, req.user.id);
  }
}
