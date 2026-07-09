"""add invoice_type field

Revision ID: 20260708_160156
Revises: b1b2c3d4e5f6
Create Date: 2026-07-08 16:01:56

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20260708_160156'
down_revision = 'b1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade():
    # Add invoice_type column to invoices table
    op.add_column('invoices', sa.Column('invoice_type', sa.String(20), nullable=False, server_default='regular'))


def downgrade():
    op.drop_column('invoices', 'invoice_type')
