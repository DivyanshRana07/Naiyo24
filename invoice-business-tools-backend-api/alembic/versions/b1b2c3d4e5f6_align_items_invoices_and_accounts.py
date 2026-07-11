"""align_items_invoices_and_accounts

Revision ID: b1b2c3d4e5f6
Revises: a1b2c3d4e5f6
Create Date: 2026-07-08 02:44:00.000000

"""
from __future__ import annotations

from alembic import op
# pyrefly: ignore [missing-import]
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'b1b2c3d4e5f6'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. Rename products to items
    op.rename_table('products', 'items')

    # 2. Add columns to invoices
    op.add_column('invoices', sa.Column('payment_method', sa.String(length=50), nullable=True))
    op.add_column('invoices', sa.Column('paid_amount', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'))
    op.add_column('invoices', sa.Column('round_off', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'))
    op.add_column('invoices', sa.Column('status', sa.String(length=50), nullable=False, server_default='due'))

    # 3. Add columns to quotation_items
    op.add_column('quotation_items', sa.Column('discount_percent', sa.Numeric(precision=5, scale=2), nullable=False, server_default='0.00'))
    op.add_column('quotation_items', sa.Column('gst_percent', sa.Numeric(precision=5, scale=2), nullable=False, server_default='0.00'))


def downgrade() -> None:
    # 3. Remove columns from quotation_items
    op.drop_column('quotation_items', 'gst_percent')
    op.drop_column('quotation_items', 'discount_percent')

    # 2. Remove columns from invoices
    op.drop_column('invoices', 'status')
    op.drop_column('invoices', 'round_off')
    op.drop_column('invoices', 'paid_amount')
    op.drop_column('invoices', 'payment_method')

    # 1. Rename items back to products
    op.rename_table('items', 'products')

