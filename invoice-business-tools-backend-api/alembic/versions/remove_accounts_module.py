"""remove accounts module

Revision ID: remove_accounts_module
Revises: ('4b4e89b25a0c', '20260708_160300', '20260710_add_notes')
Create Date: 2026-07-11 15:10:00.000000

"""
from typing import Sequence, Union

from alembic import op
# pyrefly: ignore [missing-import]
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'remove_accounts_module'
down_revision: Union[str, Sequence[str], None] = ('4b4e89b25a0c', '20260708_160300', '20260710_add_notes')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Drop accounts table
    op.drop_index('ix_accounts_user_id', table_name='accounts')
    op.drop_index('ix_accounts_code', table_name='accounts')
    op.drop_index('ix_accounts_account_id_str', table_name='accounts')
    op.drop_index('ix_accounts_id', table_name='accounts')
    op.drop_index('ix_accounts_created_at', table_name='accounts')
    op.drop_table('accounts')

    # 2. Drop account_groups table
    op.drop_index('ix_account_groups_user_id', table_name='account_groups')
    op.drop_index('ix_account_groups_group_id_str', table_name='account_groups')
    op.drop_index('ix_account_groups_id', table_name='account_groups')
    op.drop_index('ix_account_groups_created_at', table_name='account_groups')
    op.drop_table('account_groups')


def downgrade() -> None:
    # Dropping accounts module is one-way
    pass
