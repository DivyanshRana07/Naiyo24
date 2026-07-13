"""add subtitle logo settings

Revision ID: 20260714_add_subtitle_logo_settings
Revises: remove_accounts_module
Create Date: 2026-07-14 10:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20260714_add_subtitle_logo_settings'
down_revision: Union[str, None] = 'remove_accounts_module'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add columns to invoices table
    op.add_column('invoices', sa.Column('subtitle', sa.String(length=200), nullable=True))
    op.add_column('invoices', sa.Column('logo', sa.String(), nullable=True))
    op.add_column('invoices', sa.Column('settings', sa.JSON(), nullable=True))

    # Add columns to quotations table
    op.add_column('quotations', sa.Column('subtitle', sa.String(length=200), nullable=True))
    op.add_column('quotations', sa.Column('logo', sa.String(), nullable=True))
    op.add_column('quotations', sa.Column('settings', sa.JSON(), nullable=True))


def downgrade() -> None:
    # Remove columns from quotations table
    op.drop_column('quotations', 'settings')
    op.drop_column('quotations', 'logo')
    op.drop_column('quotations', 'subtitle')

    # Remove columns from invoices table
    op.drop_column('invoices', 'settings')
    op.drop_column('invoices', 'logo')
    op.drop_column('invoices', 'subtitle')
