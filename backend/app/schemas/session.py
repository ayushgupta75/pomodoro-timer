from datetime import datetime

from pydantic import BaseModel


class SessionRecordSchema(BaseModel):
    id: str
    started_at: datetime
    completed_at: datetime


class SyncSessionsRequest(BaseModel):
    sessions: list[SessionRecordSchema]


class SyncSessionsResponse(BaseModel):
    synced: int
    sessions: list[SessionRecordSchema]
