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
