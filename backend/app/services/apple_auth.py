import httpx
from jose import jwt
from jose.exceptions import JWTError

from app.core.config import settings


async def verify_apple_token(identity_token: str) -> str:
    """
    Verify Apple identity token and return the Apple user ID (sub claim).
    Raises ValueError if the token is invalid.
    """
    keys = await _fetch_apple_public_keys()
    header = jwt.get_unverified_header(identity_token)
    kid = header.get("kid")

    signing_key = next((k for k in keys if k["kid"] == kid), None)
    if not signing_key:
        raise ValueError("No matching Apple public key found")

    try:
        claims = jwt.decode(
            identity_token,
            signing_key,
            algorithms=["RS256"],
            audience=settings.apple_bundle_id,
            issuer="https://appleid.apple.com",
        )
    except JWTError as e:
        raise ValueError(f"Apple token verification failed: {e}") from e

    apple_user_id: str = claims["sub"]
    return apple_user_id


async def _fetch_apple_public_keys() -> list[dict]:
    async with httpx.AsyncClient() as client:
        response = await client.get(settings.apple_keys_url)
        response.raise_for_status()
        return response.json()["keys"]
