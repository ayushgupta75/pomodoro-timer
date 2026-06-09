import logging

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import get_current_user
from app.db.database import get_db
from app.models.goal import DailyGoal
from app.models.user import User
from app.schemas.goal import DailyGoalResponse, DailyGoalSchema, UpsertDailyGoalRequest

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/goals", tags=["goals"])


@router.post("/sync", response_model=DailyGoalResponse)
async def sync_goals(
    payload: UpsertDailyGoalRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> DailyGoalResponse:
    """
    Upsert daily goals from device. Server wins on conflict (latest write wins by updated_at).
    Returns all goals for the user.
    """
    if payload.goals:
        stmt = insert(DailyGoal).values([
            {
                "id": f"{current_user.id}:{g.date}",
                "user_id": current_user.id,
                "date": g.date,
                "goal": g.goal,
            }
            for g in payload.goals
        ]).on_conflict_do_update(
            index_elements=["id"],
            set_={"goal": insert(DailyGoal).excluded.goal}
        )
        await db.execute(stmt)

    result = await db.execute(
        select(DailyGoal)
        .where(DailyGoal.user_id == current_user.id)
        .order_by(DailyGoal.date.asc())
    )
    all_goals = result.scalars().all()

    return DailyGoalResponse(
        goals=[DailyGoalSchema(date=g.date, goal=g.goal, duration_seconds=g.duration_seconds) for g in all_goals]
    )
