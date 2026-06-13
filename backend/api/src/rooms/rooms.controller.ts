import {
  Controller, Get, Post, Patch, Delete, Body, Param, Req,
  UseGuards, HttpCode, HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RoomsService } from './rooms.service';
import { CreateRoomDto } from './dto/create-room.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { JoinRoomDto } from './dto/join-room.dto';
import { TransferOwnershipDto } from './dto/transfer-ownership.dto';
import { JwtGuard } from '../auth/guards/jwt.guard';

@ApiTags('Rooms')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller('rooms')
export class RoomsController {
  constructor(private readonly roomsService: RoomsService) {}

  @Get()
  @ApiOperation({ summary: 'List all rooms the user belongs to' })
  findAll(@Req() req: any) {
    return this.roomsService.findAll(req.user.id);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new room (creator becomes OWNER)' })
  @ApiBody({ type: CreateRoomDto })
  create(@Req() req: any, @Body() dto: CreateRoomDto) {
    return this.roomsService.create(dto, req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get room details' })
  findOne(@Req() req: any, @Param('id') id: string) {
    return this.roomsService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update room (OWNER or ADMIN only)' })
  @ApiBody({ type: UpdateRoomDto })
  update(@Req() req: any, @Param('id') id: string, @Body() dto: UpdateRoomDto) {
    return this.roomsService.update(id, dto, req.user.id);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft delete room (OWNER only)' })
  remove(@Req() req: any, @Param('id') id: string) {
    return this.roomsService.remove(id, req.user.id);
  }

  @Post('join')
  @ApiOperation({ summary: 'Join a room using invite code' })
  @ApiBody({ type: JoinRoomDto })
  join(@Req() req: any, @Body() dto: JoinRoomDto) {
    return this.roomsService.join(dto, req.user.id);
  }

  @Post(':id/leave')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Leave a room (OWNER must transfer ownership first)' })
  leave(@Req() req: any, @Param('id') id: string) {
    return this.roomsService.leave(id, req.user.id);
  }

  @Post(':id/transfer-ownership')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Transfer room ownership (OWNER only)' })
  @ApiBody({ type: TransferOwnershipDto })
  transferOwnership(@Req() req: any, @Param('id') id: string, @Body() dto: TransferOwnershipDto) {
    return this.roomsService.transferOwnership(id, dto, req.user.id);
  }

  @Post(':id/regenerate-invite')
  @ApiOperation({ summary: 'Regenerate invite code (OWNER or ADMIN only)' })
  regenerateInvite(@Req() req: any, @Param('id') id: string) {
    return this.roomsService.regenerateInviteCode(id, req.user.id);
  }

  @Get(':id/members')
  @ApiOperation({ summary: 'List room members' })
  getMembers(@Req() req: any, @Param('id') id: string) {
    return this.roomsService.getMembers(id, req.user.id);
  }

  @Post(':id/members/:userId/promote')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Promote member to ADMIN (OWNER only)' })
  promoteMember(@Req() req: any, @Param('id') id: string, @Param('userId') userId: string) {
    return this.roomsService.promoteMember(id, userId, req.user.id);
  }

  @Post(':id/members/:userId/demote')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Demote ADMIN to MEMBER (OWNER only)' })
  demoteMember(@Req() req: any, @Param('id') id: string, @Param('userId') userId: string) {
    return this.roomsService.demoteMember(id, userId, req.user.id);
  }

  @Post(':id/members/:userId/remove')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remove member (OWNER or ADMIN, ADMIN cannot remove OWNER)' })
  removeMember(@Req() req: any, @Param('id') id: string, @Param('userId') userId: string) {
    return this.roomsService.removeMember(id, userId, req.user.id);
  }
}
