import logging

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.database import get_db
from app.models.session import SessionRecord
from app.models.user import User
from app.schemas.session import SessionRecordSchema, SyncSessionsRequest, SyncSessionsResponse

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.post("/sync", response_model=SyncSessionsResponse)
async def sync_sessions(
    payload: SyncSessionsRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> SyncSessionsResponse:
    """
    Upsert sessions from the device (offline-first sync).
    Returns all sessions for the user so the device can reconcile.
    """
    if payload.sessions:
        stmt = insert(SessionRecord).values([
            {"id": s.id, "user_id": current_user.id, "started_at": s.started_at, "completed_at": s.completed_at}
            for s in payload.sessions
        ]).on_conflict_do_nothing(index_elements=["id"])
        await db.execute(stmt)
        await db.commit()
        logger.info("Synced %d sessions for user %s", len(payload.sessions), current_user.id)

    result = await db.execute(
        select(SessionRecord)
        .where(SessionRecord.user_id == current_user.id)
        .order_by(SessionRecord.completed_at.asc())
    )
    all_sessions = result.scalars().all()

    return SyncSessionsResponse(
        synced=len(payload.sessions),
        sessions=[SessionRecordSchema(id=s.id, started_at=s.started_at, completed_at=s.completed_at) for s in all_sessions],
    )
