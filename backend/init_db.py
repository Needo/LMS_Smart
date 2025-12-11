import os
from pathlib import Path
from dotenv import load_dotenv

# Build the path to .env that is in the project root (same folder as init_db.py)
env_path = Path(__file__).parent / ".env"   # ← this is the key line
# or if .env is one level up: Path(__file__).parent.parent / ".env"

load_dotenv(dotenv_path=env_path)

# Debug — remove later
print("Looking for .env at:", env_path)
print("Exists?", env_path.exists())
print("DATABASE_URL =", os.getenv("DATABASE_URL"))

from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.models.models import Base, User, Category
from app.core.security import get_password_hash


def init_db():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()

    # ----------------------------
    # Create ADMIN user
    # ----------------------------
    admin = db.query(User).filter(User.username == "admin").first()
    
    if not admin:
        admin = User(
            username="admin",
            email="admin@lms.com",
            full_name="System Administrator",
            hashed_password=get_password_hash("admin123"),
            is_admin=True,
            is_active=True
        )
        db.add(admin)
        print("[OK] Created admin user (username: admin, password: admin123)")

    # ----------------------------
    # Default course categories
    # (Fixed UTF-8 icons)
    # ----------------------------
    categories_data = [
        {"name": "Programming", "icon": "💻"},
        {"name": "Books", "icon": "📖"},
        {"name": "Novels", "icon": "📚"},
        {"name": "Tutorials", "icon": "🎓"},
        {"name": "Uncategorized", "icon": "📂"},
    ]

    for cat in categories_data:
        existing = db.query(Category).filter(Category.name == cat["name"]).first()
        if not existing:
            category = Category(**cat)
            db.add(category)
            print(f"[OK] Created category: {cat['name']}")

    db.commit()
    db.close()

    print("\n[SUCCESS] Database initialized!")
    print("Admin credentials: username='admin', password='admin123'")


if __name__ == "__main__":
    init_db()

