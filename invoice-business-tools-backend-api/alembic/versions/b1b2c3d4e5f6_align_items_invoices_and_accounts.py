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
    # 1. Create account_groups table
    op.create_table(
        'account_groups',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('group_id_str', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=150), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('parent_group_id', sa.String(length=50), nullable=True),
        sa.Column('category', sa.String(length=100), nullable=False),
        sa.Column('description', sa.String(length=300), nullable=True),
        sa.Column('is_system', sa.Boolean(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_account_groups_id'), 'account_groups', ['id'], unique=False)
    op.create_index(op.f('ix_account_groups_group_id_str'), 'account_groups', ['group_id_str'], unique=True)
    op.create_index(op.f('ix_account_groups_user_id'), 'account_groups', ['user_id'], unique=False)

    # 2. Create accounts table
    op.create_table(
        'accounts',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('account_id_str', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=150), nullable=False),
        sa.Column('code', sa.String(length=50), nullable=False),
        sa.Column('account_group_id', sa.String(length=50), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('opening_balance', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'),
        sa.Column('current_balance', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='1'),
        sa.Column('currency', sa.String(length=10), nullable=False, server_default='INR'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=True),
        sa.ForeignKeyConstraint(['account_group_id'], ['account_groups.group_id_str']),
        sa.ForeignKeyConstraint(['user_id'], ['users.id']),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_accounts_id'), 'accounts', ['id'], unique=False)
    op.create_index(op.f('ix_accounts_account_id_str'), 'accounts', ['account_id_str'], unique=True)
    op.create_index(op.f('ix_accounts_code'), 'accounts', ['code'], unique=False)
    op.create_index(op.f('ix_accounts_user_id'), 'accounts', ['user_id'], unique=False)

    # 3. Rename products to items
    op.rename_table('products', 'items')

    # 4. Add columns to invoices
    op.add_column('invoices', sa.Column('payment_method', sa.String(length=50), nullable=True))
    op.add_column('invoices', sa.Column('paid_amount', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'))
    op.add_column('invoices', sa.Column('round_off', sa.Numeric(precision=12, scale=2), nullable=False, server_default='0.00'))
    op.add_column('invoices', sa.Column('status', sa.String(length=50), nullable=False, server_default='due'))

    # 5. Add columns to quotation_items
    op.add_column('quotation_items', sa.Column('discount_percent', sa.Numeric(precision=5, scale=2), nullable=False, server_default='0.00'))
    op.add_column('quotation_items', sa.Column('gst_percent', sa.Numeric(precision=5, scale=2), nullable=False, server_default='0.00'))


def downgrade() -> None:
    # 5. Remove columns from quotation_items
    op.drop_column('quotation_items', 'gst_percent')
    op.drop_column('quotation_items', 'discount_percent')

    # 4. Remove columns from invoices
    op.drop_column('invoices', 'status')
    op.drop_column('invoices', 'round_off')
    op.drop_column('invoices', 'paid_amount')
    op.drop_column('invoices', 'payment_method')

    # 3. Rename items back to products
    op.rename_table('items', 'products')

    # 2. Drop accounts table
    op.drop_index(op.f('ix_accounts_user_id'), table_name='accounts')
    op.drop_index(op.f('ix_accounts_code'), table_name='accounts')
    op.drop_index(op.f('ix_accounts_account_id_str'), table_name='accounts')
    op.drop_index(op.f('ix_accounts_id'), table_name='accounts')
    op.drop_table('accounts')

    # 1. Drop account_groups table
    op.drop_index(op.f('ix_account_groups_user_id'), table_name='account_groups')
    op.drop_index(op.f('ix_account_groups_group_id_str'), table_name='account_groups')
    op.drop_index(op.f('ix_account_groups_id'), table_name='account_groups')
    op.drop_table('account_groups')

