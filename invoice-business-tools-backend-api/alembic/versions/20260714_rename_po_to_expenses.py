"""rename po to expenses

Revision ID: 20260714_rename_po_to_expenses
Revises: 20260714_add_subtitle_logo_settings
Create Date: 2026-07-14 11:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '20260714_rename_po_to_expenses'
down_revision: Union[str, None] = '20260714_add_subtitle_logo_settings'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Rename tables
    op.rename_table('purchase_orders', 'expenses')
    op.rename_table('purchase_order_items', 'expense_items')

    # 2. Alter expenses table
    with op.batch_alter_table('expenses') as batch_op:
        batch_op.alter_column('po_number', new_column_name='expense_number')
        batch_op.alter_column('po_date', new_column_name='expense_date')
        batch_op.add_column(sa.Column('gst_amount', sa.Numeric(precision=12, scale=2), nullable=True))
        batch_op.add_column(sa.Column('receipt_image', sa.String(), nullable=True))

    # Recreate indexes for expenses
    op.drop_index('ix_purchase_orders_po_number', table_name='expenses')
    op.create_index(op.f('ix_expenses_expense_number'), 'expenses', ['expense_number'], unique=True)
    op.drop_index('ix_purchase_orders_id', table_name='expenses')
    op.create_index(op.f('ix_expenses_id'), 'expenses', ['id'], unique=False)

    # 3. Alter expense_items table
    with op.batch_alter_table('expense_items') as batch_op:
        batch_op.alter_column('po_id', new_column_name='expense_id')

    # Recreate indexes for expense_items
    op.drop_index('ix_purchase_order_items_id', table_name='expense_items')
    op.create_index(op.f('ix_expense_items_id'), 'expense_items', ['id'], unique=False)


def downgrade() -> None:
    # 3. Alter expense_items table back
    op.drop_index('ix_expense_items_id', table_name='expense_items')
    op.create_index(op.f('ix_purchase_order_items_id'), 'expense_items', ['id'], unique=False)

    with op.batch_alter_table('expense_items') as batch_op:
        batch_op.alter_column('expense_id', new_column_name='po_id')

    # 2. Alter expenses table back
    op.drop_index('ix_expenses_id', table_name='expenses')
    op.create_index(op.f('ix_purchase_orders_id'), 'expenses', ['id'], unique=False)
    op.drop_index('ix_expenses_expense_number', table_name='expenses')
    op.create_index(op.f('ix_purchase_orders_po_number'), 'expenses', ['po_number'], unique=True)

    with op.batch_alter_table('expenses') as batch_op:
        batch_op.drop_column('receipt_image')
        batch_op.drop_column('gst_amount')
        batch_op.alter_column('expense_date', new_column_name='po_date')
        batch_op.alter_column('expense_number', new_column_name='po_number')

    # 1. Rename tables back
    op.rename_table('expense_items', 'purchase_order_items')
    op.rename_table('expenses', 'purchase_orders')
