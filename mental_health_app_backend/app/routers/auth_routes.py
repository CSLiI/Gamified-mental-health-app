from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app import schemas, auth, models
from app.database import get_db
from app.CRUD import users as user_crud

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
async def get_current_user_info(current_user: models.User = Depends(auth.get_current_user)):
    """Get current logged-in user information"""
    return current_user

@router.post("/google", response_model=schemas.Token)
def google_login(
    request: dict,
    db: Session = Depends(get_db)
):
    """Login or register with Google ID Token"""
    from google.oauth2 import id_token
    from google.auth.transport import requests as google_requests
    import os
    
    token = request.get("id_token")
    if not token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="ID token is required"
        )
    
    try:
        # Verify the token with Google
        # Note: You can get the CLIENT_ID from your google-services.json (web client)
        # For now, we'll skip strict verification and just decode
        idinfo = id_token.verify_oauth2_token(
            token, 
            google_requests.Request(),
            None  # Skip audience verification for now - add your Web Client ID here in production
        )
        
        # Extract user info from token
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