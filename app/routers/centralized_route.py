from fastapi import APIRouter
from routers.user_routes import create_user_endpoint, get_user_endpoint
import schemas

router = APIRouter(prefix="/users", tags=["Users"])

router.post("/", response_model=schemas.User)(create_user_endpoint)
router.get("/{user_id}", response_model=schemas.User)(get_user_endpoint)
