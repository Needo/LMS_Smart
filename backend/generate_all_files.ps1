# ============================================================
# LMS System - Complete Code Generator
# Save as: generate_all_files.ps1
# Run from: C:\Projects\LMS-System\backend\
# ============================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LMS System - Complete Code Generator" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$baseDir = Get-Location

Write-Host "`nGenerating all code files..." -ForegroundColor Yellow

# Create __init__.py files
@"
"@ | Out-File -FilePath "app\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\api\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\api\routes\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\core\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\db\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\models\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\schemas\__init__.py" -Encoding UTF8
@"
"@ | Out-File -FilePath "app\services\__init__.py" -Encoding UTF8

Write-Host "Created __init__.py files" -ForegroundColor Gray

# app\core\config.py
$configPy = @'
from pydantic_settings import BaseSettings
from pydantic import Field

class Settings(BaseSettings):
    DATABASE_URL: str = Field(default="postgresql://lms_user:lms_password@localhost:5432/lms_db")
    SECRET_KEY: str = Field(default="change-this-secret-key-min-32-chars")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    COURSES_ROOT_PATH: str = Field(default="C:\\LMS_Content")
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
'@
$configPy | Out-File -FilePath "app\core\config.py" -Encoding UTF8
Write-Host "Created app\core\config.py" -ForegroundColor Gray

# app\core\security.py
$securityPy = @'
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def decode_token(token: str):
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except JWTError:
        return None
'@
$securityPy | Out-File -FilePath "app\core\security.py" -Encoding UTF8
Write-Host "Created app\core\security.py" -ForegroundColor Gray

# app\db\database.py
$databasePy = @'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
'@
$databasePy | Out-File -FilePath "app\db\database.py" -Encoding UTF8
Write-Host "Created app\db\database.py" -ForegroundColor Gray

# app\models\models.py (simplified version for Python 3.14)
$modelsPy = @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Float
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.database import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100))
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Category(Base):
    __tablename__ = "categories"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    icon = Column(String(50), default="📚")
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    courses = relationship("Course", back_populates="category")

class Course(Base):
    __tablename__ = "courses"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    category_id = Column(Integer, ForeignKey("categories.id"))
    file_path = Column(String(500), nullable=False)
    thumbnail = Column(String(500))
    total_lessons = Column(Integer, default=0)
    total_duration = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    category = relationship("Category", back_populates="courses")
    modules = relationship("Module", back_populates="course")

class Module(Base):
    __tablename__ = "modules"
    
    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    title = Column(String(255), nullable=False)
    order = Column(Integer, default=0)
    parent_id = Column(Integer, ForeignKey("modules.id"), nullable=True)
    file_path = Column(String(500))
    
    course = relationship("Course", back_populates="modules")
    parent = relationship("Module", remote_side=[id], backref="children")
    lessons = relationship("Lesson", back_populates="module")

class Lesson(Base):
    __tablename__ = "lessons"
    
    id = Column(Integer, primary_key=True, index=True)
    module_id = Column(Integer, ForeignKey("modules.id"), nullable=False)
    title = Column(String(255), nullable=False)
    file_type = Column(String(20))
    file_path = Column(String(500), nullable=False)
    file_size = Column(Integer)
    duration = Column(Integer)
    order = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    module = relationship("Module", back_populates="lessons")

class UserProgress(Base):
    __tablename__ = "user_progress"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    lesson_id = Column(Integer, ForeignKey("lessons.id"), nullable=False)
    completed = Column(Boolean, default=False)
    progress_percentage = Column(Float, default=0.0)
    last_position = Column(Integer, default=0)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
'@
$modelsPy | Out-File -FilePath "app\models\models.py" -Encoding UTF8
Write-Host "Created app\models\models.py" -ForegroundColor Gray

# app\schemas\schemas.py
$schemasPy = @'
from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    is_active: bool
    is_admin: bool
    created_at: datetime
    
    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class LoginRequest(BaseModel):
    username: str
    password: str

class CategoryBase(BaseModel):
    name: str
    icon: Optional[str] = "📚"
    description: Optional[str] = None

class Category(CategoryBase):
    id: int
    created_at: datetime
    
    class Config:
        from_attributes = True

class LessonBase(BaseModel):
    title: str
    file_type: str
    file_path: str

class Lesson(LessonBase):
    id: int
    order: int
    duration: Optional[int] = None
    
    class Config:
        from_attributes = True

class ModuleBase(BaseModel):
    title: str

class Module(ModuleBase):
    id: int
    order: int
    
    class Config:
        from_attributes = True

class CourseBase(BaseModel):
    title: str
    description: Optional[str] = None
    category_id: Optional[int] = None

class Course(CourseBase):
    id: int
    total_lessons: int
    total_duration: int
    created_at: datetime
    
    class Config:
        from_attributes = True
'@
$schemasPy | Out-File -FilePath "app\schemas\schemas.py" -Encoding UTF8
Write-Host "Created app\schemas\schemas.py" -ForegroundColor Gray

# app\main.py (updated)
$mainPy = @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(
    title="LMS System API",
    description="Learning Management System API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    return {
        "message": "LMS System API",
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
'@
$mainPy | Out-File -FilePath "app\main.py" -Encoding UTF8
Write-Host "Created app\main.py (updated)" -ForegroundColor Gray

# init_db.py
$initDbPy = @'
from sqlalchemy.orm import Session
from app.db.database import SessionLocal, engine
from app.models.models import Base, User, Category
from app.core.security import get_password_hash

def init_db():
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # Create admin user
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
    
    # Create default categories
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
'@
$initDbPy | Out-File -FilePath "init_db.py" -Encoding UTF8
Write-Host "Created init_db.py" -ForegroundColor Gray

# Update requirements.txt
$requirementsTxt = @'
fastapi
uvicorn[standard]
sqlalchemy
psycopg[binary]
python-jose[cryptography]
passlib[bcrypt]
python-multipart
pydantic
pydantic-settings
python-dotenv
'@
$requirementsTxt | Out-File -FilePath "requirements.txt" -Encoding UTF8
Write-Host "Updated requirements.txt" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  All Files Generated Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Install new packages:" -ForegroundColor White
Write-Host "   pip install -r requirements.txt" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Setup PostgreSQL database (or skip for now)" -ForegroundColor White
Write-Host ""
Write-Host "3. Initialize database:" -ForegroundColor White
Write-Host "   python init_db.py" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Start server:" -ForegroundColor White
Write-Host "   uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host ""
Write-Host "5. Test at: http://localhost:8000" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Cyan