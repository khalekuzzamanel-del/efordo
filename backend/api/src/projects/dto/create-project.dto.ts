import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateProjectDto {
  @ApiProperty({ example: 'uuid-of-workspace' })
  @IsString()
  @IsNotEmpty()
  workspace_id: string;

  @ApiProperty({ example: 'Launch eFordo' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ example: 'Get the MVP out the door' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: ['active', 'on_hold', 'completed'], default: 'active' })
  @IsOptional()
  @IsIn(['active', 'on_hold', 'completed'])
  status?: 'active' | 'on_hold' | 'completed';

  @ApiPropertyOptional({ example: '#4CAF50' })
  @IsOptional()
  @IsString()
  color?: string;

  @ApiPropertyOptional({ example: 'rocket' })
  @IsOptional()
  @IsString()
  icon?: string;
}
