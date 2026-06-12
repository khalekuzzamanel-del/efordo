import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({
    example: 'johndoe',
    description: 'Username or email',
  })
  identifier: string;

  @ApiProperty({ example: 'securePassword123' })
  password: string;
}
