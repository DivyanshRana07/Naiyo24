import sys
import os

sys.path.append(os.path.abspath(os.path.dirname(__file__)))
# pyrefly: ignore [missing-import]
from alembic.config import Config
from alembic import command

def main():
    alembic_cfg = Config("alembic.ini")
    print("Generating Alembic migration...")
    command.revision(alembic_cfg, message="align_items_invoices_and_expenses", autogenerate=True)
    print("Applying migrations to database...")
    command.upgrade(alembic_cfg, "head")
    print("Database migrations applied successfully!")

if __name__ == "__main__":
    main()
