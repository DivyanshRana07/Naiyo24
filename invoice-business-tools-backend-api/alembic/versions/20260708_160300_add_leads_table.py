"""add leads table

Revision ID: 20260708_160300
Revises: 20260708_160156
Create Date: 2026-07-08 16:03:00

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = '20260708_160300'
down_revision = '20260708_160156'
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'leads',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=False, index=True),
        sa.Column('name', sa.String(150), nullable=False),
        sa.Column('email', sa.String(120), nullable=True),
        sa.Column('phone', sa.String(50), nullable=True),
        sa.Column('company', sa.String(150), nullable=True),
        sa.Column('status', sa.String(50), default='new', nullable=False, index=True),
        sa.Column('notes', sa.String(1000), nullable=True),
        sa.Column('source', sa.String(100), nullable=True),
        sa.Column('converted_to_customer_id', sa.Integer(), sa.ForeignKey('customers.id'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), index=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now()),
    )


def downgrade():
    op.drop_table('leads')
