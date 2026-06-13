import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateRoomDto {
  @ApiPropertyOptional({ example: 'Family Hub', description: 'Room name' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ example: 'Family expense and grocery tracking', description: 'Room description' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
