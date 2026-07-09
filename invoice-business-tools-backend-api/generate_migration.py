import sys
import os

# Add current directory to path
sys.path.append(os.path.abspath(os.path.dirname(__file__)))

# pyrefly: ignore [missing-import]
from alembic.config import Config
from alembic import command

def main():
    print("Generating Alembic migration for Account and AccountGroup models...")
    alembic_cfg = Config("alembic.ini")
    command.revision(alembic_cfg, message="add_account_tables", autogenerate=True)
    print("Migration generated successfully!")

if __name__ == "__main__":
    main()
