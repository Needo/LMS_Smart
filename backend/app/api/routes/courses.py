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
