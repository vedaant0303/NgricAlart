from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Text, ForeignKey
from app.database import Base
from pydantic import BaseModel
from datetime import datetime
import uuid

# --- SQLALCHEMY DATABASE MODELS ---

class DBIncident(Base):
    __tablename__ = "incidents"
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    type = Column(String, index=True)
    description = Column(Text)
    latitude = Column(Float)
    longitude = Column(Float)
    severity = Column(Integer)
    status = Column(String, default="Unverified") # Unverified, Verified, Resolved
    device_hash = Column(String, index=True)      # For Fingerprinting
    timestamp = Column(DateTime, default=datetime.utcnow)

class DBAuditLog(Base):
    __tablename__ = "audit_logs"
    id = Column(Integer, primary_key=True, autoincrement=True)
    incident_id = Column(String, ForeignKey("incidents.id"))
    action = Column(String)       # e.g., "AUTO_VERIFIED"
    performed_by = Column(String) # "SYSTEM" or "ADMIN"
    details = Column(String)
    timestamp = Column(DateTime, default=datetime.utcnow)

class DBDeviceRegistry(Base):
    __tablename__ = "device_registry"
    device_hash = Column(String, primary_key=True)
    is_banned = Column(Boolean, default=False)
    trust_score = Column(Float, default=1.0)
    last_seen = Column(DateTime, default=datetime.utcnow)

# --- PYDANTIC SCHEMAS ---

class IncidentCreate(BaseModel):
    type: str
    description: str
    latitude: float
    longitude: float
    severity: int
    reporter_id: str # Keep for legacy, but we rely on device_hash for security

class IncidentResponse(IncidentCreate):
    id: str
    status: str
    timestamp: datetime
    class Config:
        from_attributes = True