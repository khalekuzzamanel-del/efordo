import { IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateWorkspaceDto {
  @ApiProperty({ example: 'Personal' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: 'My personal projects' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 'folder' })
  @IsOptional()
  @IsString()
  icon?: string;

  @ApiPropertyOptional({ example: '#6C63FF' })
  @IsOptional()
  @IsString()
  color?: string;
}
