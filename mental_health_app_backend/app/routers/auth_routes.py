from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
import secrets
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import users as user_crud
from app.services import email_service

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=schemas.User, status_code=status.HTTP_201_CREATED)
def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    # Check if user already exists
    existing_user = user_crud.get_user_by_email(db, user.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    # Hash the password
    hashed_password = auth.get_password_hash(user.password_hash)
    user.password_hash = hashed_password
    
    # Create user
    return user_crud.create_user(db, user)

@router.post("/login", response_model=schemas.Token)
def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """Login and get access token"""
    # Find user by email (username in OAuth2 form)
    user = user_crud.get_user_by_email(db, form_data.username)
    
    if not user or not auth.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check for birthday and create notification if needed
    user_crud.check_and_create_birthday_notification(db, user.id)
    
    # Create access token - CONVERT user.id to STRING
    access_token = auth.create_access_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "email": user.email
    }

@router.get("/me", response_model=schemas.User)
def get_current_user_info(
    current_user: models.User = Depends(auth.get_current_user)
):
    """Get current user information"""
    return current_user

@router.post("/google")
def google_login(request: dict, db: Session = Depends(get_db)):
    """Login or register with Google OAuth"""
    from google.oauth2 import id_token
    from google.auth.transport import requests as google_requests
    
    try:
        # Verify the Google ID token
        idinfo = id_token.verify_oauth2_token(
            request['idToken'],
            google_requests.Request(),
            None  # We'll skip audience verification for now
        )
        
        # Get user info from token
        email = idinfo.get('email')
        given_name = idinfo.get('given_name', '')
        family_name = idinfo.get('family_name', '')
        
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email not found in token"
            )
        
        # Check if user exists
        user = user_crud.get_user_by_email(db, email)
        
        if not user:
            # Create new user
            user_data = schemas.UserCreate(
                email=email,
                first_name=given_name,
                last_name=family_name,
                password_hash="google_oauth"  # Placeholder - Google users don't need password
            )
            user = user_crud.create_user(db, user_data)
        
        # Create access token
        access_token = auth.create_access_token(data={"sub": str(user.id)})
        
        return {
            "access_token": access_token,
            "token_type": "bearer",
            "user_id": user.id,
            "email": user.email
        }
        
    except ValueError as e:
        # Invalid token
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid ID token: {str(e)}"
        )


# Password Reset Endpoints

@router.post("/forgot-password")
def forgot_password(
    request: dict,
    db: Session = Depends(get_db)
):
    """Send password reset email"""
    email = request.get('email')
    
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required"
        )
    
    user = user_crud.get_user_by_email(db, email)
    
    # Don't reveal if email exists (security best practice)
    if not user:
        return {"message": "If the email exists, a password reset link has been sent"}
    
    # Don't allow password reset for Google users
    if user.auth_provider == 'google':
        return {"message": "If the email exists, a password reset link has been sent"}
    
    # Generate reset token
    reset_token = secrets.token_urlsafe(32)
    user.reset_token = reset_token
    user.reset_token_expires = datetime.utcnow() + timedelta(hours=1)
    db.commit()
    
    # Send email
    email_service.send_password_reset_email(user.email, reset_token)
    
    return {"message": "If the email exists, a password reset link has been sent"}


@router.post("/reset-password")
def reset_password(
    request: dict,
    db: Session = Depends(get_db)
):
    """Reset password with token"""
    token = request.get('token')
    new_password = request.get('new_password')
    
    if not token or not new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token and new password are required"
        )
    
    user = db.query(models.User).filter(models.User.reset_token == token).first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token"
        )
    
    # Check if token expired
    if user.reset_token_expires < datetime.utcnow():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset token has expired"
        )
    
    # Hash new password
    hashed_password = auth.get_password_hash(new_password)
    user.password_hash = hashed_password
    user.reset_token = None
    user.reset_token_expires = None
    db.commit()
    
    return {"message": "Password reset successfully"}