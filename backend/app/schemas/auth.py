from pydantic import BaseModel


class AppleSignInRequest(BaseModel):
    identity_token: str
    email: str | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
