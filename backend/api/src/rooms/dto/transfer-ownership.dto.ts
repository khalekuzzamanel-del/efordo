import { IsNotEmpty, IsUUID } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class TransferOwnershipDto {
  @ApiProperty({ example: 'uuid-of-new-owner', description: 'ID of the member to become the new owner' })
  @IsUUID()
  @IsNotEmpty()
  new_owner_id: string;
}
