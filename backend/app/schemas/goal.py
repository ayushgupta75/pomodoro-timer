from datetime import date

from pydantic import BaseModel


class DailyGoalSchema(BaseModel):
    date: date
    goal: int


class UpsertDailyGoalRequest(BaseModel):
    goals: list[DailyGoalSchema]


class DailyGoalResponse(BaseModel):
    goals: list[DailyGoalSchema]
