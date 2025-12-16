"""Add password reset fields

Revision ID: add_password_reset
Revises: 
Create Date: 2024-12-16

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'add_password_reset'
down_revision = None  # Update this if you have previous migrations
branch_labels = None
depends_on = None


def upgrade():
    # Add password reset fields
    op.add_column('users', sa.Column('reset_token', sa.String(255), nullable=True))
    op.add_column('users', sa.Column('reset_token_expires', sa.DateTime(timezone=True), nullable=True))
    op.create_index('ix_users_reset_token', 'users', ['reset_token'], unique=True)


def downgrade():
    # Remove index
    op.drop_index('ix_users_reset_token', table_name='users')
    
    # Remove columns
    op.drop_column('users', 'reset_token_expires')
    op.drop_column('users', 'reset_token')
