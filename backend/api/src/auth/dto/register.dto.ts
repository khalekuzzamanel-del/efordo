import { ApiProperty } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({
    example: 'johndoe',
    description: 'Username (3-30 chars, lowercase, letters/numbers/underscore only)',
  })
  username: string;

  @ApiProperty({ example: 'john@example.com' })
  email: string;

  @ApiProperty({ example: 'securePassword123', minLength: 8 })
  password: string;
}
