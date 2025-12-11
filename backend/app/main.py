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
