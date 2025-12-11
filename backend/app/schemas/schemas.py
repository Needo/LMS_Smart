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
    icon: Optional[str] = "books"
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
