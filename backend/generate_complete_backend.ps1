# ============================================================
# LMS System - COMPLETE Generator
# This creates ALL backend API route files
# Save as: generate_complete_backend.ps1
# Run from: C:\Projects\LMS-System\backend\
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LMS Complete Backend Generator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$baseDir = Get-Location
Write-Host "Generating complete backend in: $baseDir`n" -ForegroundColor Yellow

# ============================================================
# API Routes - Auth
# ============================================================
$authPy = @'
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from datetime import timedelta
from app.db.database import get_db
from app.models.models import User
from app.schemas.schemas import Token, LoginRequest, User as UserSchema
from app.core.security import verify_password, create_access_token, decode_token
from app.core.config import settings

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_token(token)
    if payload is None:
        raise credentials_exception
    username: str = payload.get("sub")
    if username is None:
        raise credentials_exception
    user = db.query(User).filter(User.username == username).first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/login", response_model=Token)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == request.username).first()
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Incorrect username or password")
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Inactive user")
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=UserSchema)
def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
'@
$authPy | Out-File -FilePath "app\api\routes\auth.py" -Encoding UTF8
Write-Host "[OK] app\api\routes\auth.py" -ForegroundColor Green

# ============================================================
# API Routes - Users
# ============================================================
$usersPy = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.models import User
from app.schemas.schemas import User as UserSchema, UserCreate, UserUpdate
from app.core.security import get_password_hash
from app.api.routes.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[UserSchema])
def get_all_users(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    users = db.query(User).all()
    return users

@router.get("/{user_id}", response_model=UserSchema)
def get_user(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.post("/", response_model=UserSchema)
def create_user(user: UserCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_user = db.query(User).filter(User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    new_user = User(
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        hashed_password=get_password_hash(user.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.put("/{user_id}", response_model=UserSchema)
def update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db), 
                current_user: User = Depends(get_current_user)):
    if not current_user.is_admin and current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if user.email:
        db_user.email = user.email
    if user.full_name:
        db_user.full_name = user.full_name
    if user.is_active is not None and current_user.is_admin:
        db_user.is_active = user.is_active
    
    db.commit()
    db.refresh(db_user)
    return db_user

@router.delete("/{user_id}")
def delete_user(user_id: int, db: Session = Depends(get_db), 
                current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_user = db.query(User).filter(User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(db_user)
    db.commit()
    return {"message": "User deleted successfully"}
'@
$usersPy | Out-File -FilePath "app\api\routes\users.py" -Encoding UTF8
Write-Host "[OK] app\api\routes\users.py" -ForegroundColor Green

# ============================================================
# API Routes - Categories
# ============================================================
$categoriesPy = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.models import Category, User
from app.schemas.schemas import Category as CategorySchema, CategoryBase
from app.api.routes.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[CategorySchema])
def get_all_categories(db: Session = Depends(get_db)):
    categories = db.query(Category).all()
    return categories

@router.get("/{category_id}", response_model=CategorySchema)
def get_category(category_id: int, db: Session = Depends(get_db)):
    category = db.query(Category).filter(Category.id == category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    return category

@router.post("/", response_model=CategorySchema)
def create_category(category: CategoryBase, db: Session = Depends(get_db),
                   current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_category = db.query(Category).filter(Category.name == category.name).first()
    if db_category:
        raise HTTPException(status_code=400, detail="Category already exists")
    
    new_category = Category(**category.dict())
    db.add(new_category)
    db.commit()
    db.refresh(new_category)
    return new_category
'@
$categoriesPy | Out-File -FilePath "app\api\routes\categories.py" -Encoding UTF8
Write-Host "[OK] app\api\routes\categories.py" -ForegroundColor Green

# ============================================================
# API Routes - Courses
# ============================================================
$coursesPy = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.models import Course, User
from app.schemas.schemas import Course as CourseSchema, CourseBase
from app.api.routes.auth import get_current_user

router = APIRouter()

@router.get("/", response_model=List[CourseSchema])
def get_all_courses(db: Session = Depends(get_db)):
    courses = db.query(Course).all()
    return courses

@router.get("/category/{category_id}", response_model=List[CourseSchema])
def get_courses_by_category(category_id: int, db: Session = Depends(get_db)):
    courses = db.query(Course).filter(Course.category_id == category_id).all()
    return courses

@router.get("/{course_id}", response_model=CourseSchema)
def get_course(course_id: int, db: Session = Depends(get_db)):
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course
'@
$coursesPy | Out-File -FilePath "app\api\routes\courses.py" -Encoding UTF8
Write-Host "[OK] app\api\routes\courses.py" -ForegroundColor Green

# ============================================================
# API Routes - Scanner
# ============================================================
$scannerPy = @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.models import User
from app.api.routes.auth import get_current_user

router = APIRouter()

@router.post("/scan")
def scan_courses(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Scanner implementation will be added later
    return {
        "success": True,
        "message": "File system scanner - coming soon",
        "courses_found": 0,
        "lessons_found": 0
    }
'@
$scannerPy | Out-File -FilePath "app\api\routes\scanner.py" -Encoding UTF8
Write-Host "[OK] app\api\routes\scanner.py" -ForegroundColor Green

# ============================================================
# Update main.py with all routes
# ============================================================
$mainPy = @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.database import engine, Base
from app.api.routes import auth, users, categories, courses, scanner

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="LMS System API",
    description="Learning Management System with file scanner",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(categories.router, prefix="/api/categories", tags=["Categories"])
app.include_router(courses.router, prefix="/api/courses", tags=["Courses"])
app.include_router(scanner.router, prefix="/api/scanner", tags=["Scanner"])

@app.get("/")
def read_root():
    return {
        "message": "LMS System API",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs",
        "endpoints": {
            "auth": "/api/auth",
            "users": "/api/users",
            "categories": "/api/categories",
            "courses": "/api/courses",
            "scanner": "/api/scanner"
        }
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "database": "connected"}
'@
$mainPy | Out-File -FilePath "app\main.py" -Encoding UTF8
Write-Host "[OK] app\main.py (updated with all routes)" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Backend Complete!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Start the server:" -ForegroundColor Cyan
Write-Host "  uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host "`nTest at:" -ForegroundColor Cyan
Write-Host "  http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "`nLogin credentials:" -ForegroundColor Cyan
Write-Host "  username: admin" -ForegroundColor Yellow
Write-Host "  password: admin123" -ForegroundColor Yellow
Write-Host "`n========================================`n" -ForegroundColor Cyan