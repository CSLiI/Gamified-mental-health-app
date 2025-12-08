from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.config import JWT_SECRET, JWT_ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
from app.database import get_db
from app import models

# Password hashing context
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# OAuth2 scheme for token authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# In-memory cache for authenticated users to reduce DB load
# Cache structure: {user_id: (user_object, expiry_timestamp)}
_user_cache = {}
_cache_ttl_seconds = 60  # 1 minute TTL - balances freshness and performance

def clear_auth_cache():
    """Clear the authentication cache (useful for testing or manual refresh)"""
    global _user_cache
    _user_cache = {}

def cleanup_expired_cache():
    """Remove expired entries from auth cache to prevent memory leaks"""
    now = datetime.utcnow()
    expired_keys = [uid for uid, (_, expiry) in _user_cache.items() if now >= expiry]
    for uid in expired_keys:
        del _user_cache[uid]
    return len(expired_keys)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a hashed password"""
    try:
        return pwd_context.verify(plain_password, hashed_password)
    except Exception as e:
        print(f"Password verification error: {e}")
        return False

def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def decode_token(token: str):
    """Decode a JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except JWTError as e:
        print(f"Token decode error: {e}")
        return None

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db)
):
    """Get the current authenticated user from JWT token with caching"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = decode_token(token)
        if payload is None:
            raise credentials_exception
        
        # Get user_id from "sub" claim - handle both int and str
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        
        # Convert to int if it's a string
        try:
            user_id = int(user_id)
        except (ValueError, TypeError):
            raise credentials_exception
        
        # Cache disabled to ensure fresh data for energy updates
        # if user_id in _user_cache:
        #     cached_user, expiry = _user_cache[user_id]
        #     if now < expiry:
        #         # Cache hit - return cached user without DB query
        #         return cached_user
        #     else:
        #         # Expired - remove from cache
        #         del _user_cache[user_id]
        
        # Always fetch from DB to get latest energy/XP
        user = db.query(models.User).filter(models.User.id == user_id).first()
        if user is None:
            raise credentials_exception
        
        # Store in cache with TTL
        # _user_cache[user_id] = (user, now + timedelta(seconds=_cache_ttl_seconds))
        
        return user
        
    except Exception as e:
        print(f"Auth error: {e}")
        raise credentials_exception