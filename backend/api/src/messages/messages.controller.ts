import {
  Controller, Get, Post, Body, Param, Req, Query,
  UseGuards, HttpCode, HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation, ApiQuery, ApiTags } from '@nestjs/swagger';
import { MessagesService } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { MessagesQueryDto } from './dto/messages-query.dto';
import { JwtGuard } from '../auth/guards/jwt.guard';

@ApiTags('Messages')
@ApiBearerAuth()
@UseGuards(JwtGuard)
@Controller()
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get('rooms/:roomId/messages')
  @ApiOperation({ summary: 'Get paginated chat messages for a room (newest first)' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 50 })
  findByRoom(
    @Req() req: any,
    @Param('roomId') roomId: string,
    @Query() query: MessagesQueryDto,
  ) {
    return this.messagesService.findByRoom(roomId, req.user.id, query);
  }

  @Post('rooms/:roomId/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Send a message in a room' })
  @ApiBody({ type: CreateMessageDto })
  create(
    @Req() req: any,
    @Param('roomId') roomId: string,
    @Body() dto: CreateMessageDto,
  ) {
    return this.messagesService.create(roomId, dto, req.user.id);
  }
}
