import { IsNotEmpty, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateRoomDto {
  @ApiProperty({ example: 'Bachelor Mess', description: 'Room name' })
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(100)
  name: string;

  @ApiPropertyOptional({ example: 'Our bachelor mess expense sharing group', description: 'Room description' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
}
