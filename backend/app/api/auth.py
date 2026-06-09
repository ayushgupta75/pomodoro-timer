import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token
from app.db.database import get_db
from app.models.user import User
from app.schemas.auth import AppleSignInRequest, TokenResponse
from app.services.apple_auth import verify_apple_token

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/apple", response_model=TokenResponse)
async def apple_sign_in(
    payload: AppleSignInRequest,
    db: AsyncSession = Depends(get_db),
) -> TokenResponse:
    try:
        apple_user_id = await verify_apple_token(payload.identity_token)
    except ValueError as e:
        logger.warning("Apple token verification failed: %s", e)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid Apple token")

    result = await db.execute(select(User).where(User.id == apple_user_id))
    user = result.scalar_one_or_none()

    if not user:
        user = User(id=apple_user_id, email=payload.email)
        db.add(user)
        logger.info("New user created: %s", apple_user_id)

    return TokenResponse(access_token=create_access_token(user.id))
