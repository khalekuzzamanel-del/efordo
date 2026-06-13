import { IsNotEmpty, IsString, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class JoinRoomDto {
  @ApiProperty({ example: 'ABC12345', description: 'Invite code (6-8 uppercase alphanumeric characters)' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^[A-Z0-9]{6,8}$/, { message: 'Invite code must be 6-8 uppercase letters and numbers' })
  invite_code: string;
}
