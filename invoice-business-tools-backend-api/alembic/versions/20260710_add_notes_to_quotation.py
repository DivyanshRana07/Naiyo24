"""add notes to quotation

Revision ID: 20260710_add_notes
Revises: b1b2c3d4e5f6
Create Date: 2026-07-10 23:07:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20260710_add_notes'
down_revision: Union[str, None] = 'b1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add notes column to quotations table
    op.add_column('quotations', sa.Column('notes', sa.String(length=500), nullable=True))


def downgrade() -> None:
    # Remove notes column from quotations table
    op.drop_column('quotations', 'notes')
