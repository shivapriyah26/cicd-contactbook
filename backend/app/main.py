"""Contact Book API - a tiny FastAPI app used to demonstrate CI/CD."""
import os

from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import Column, Integer, String, create_engine, text
from sqlalchemy.orm import Session, declarative_base, sessionmaker

# In Docker Compose this is a MySQL URL. In unit tests it is a local SQLite file.
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./local.db")
APP_VERSION = os.getenv("APP_VERSION", "dev")  # set to the Jenkins build number

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, pool_pre_ping=True, connect_args=connect_args)
SessionLocal = sessionmaker(bind=engine, autoflush=False)
Base = declarative_base()


class Contact(Base):
    __tablename__ = "contacts"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(120), nullable=False)
    phone = Column(String(30), nullable=True)


Base.metadata.create_all(bind=engine)


class ContactIn(BaseModel):
    name: str
    email: str
    phone: str | None = None


class ContactOut(ContactIn):
    id: int
    model_config = {"from_attributes": True}


app = FastAPI(title="Contact Book API")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


@app.get("/health")
def health(db: Session = Depends(get_db)):
    """Used by Docker, the Jenkins pipeline and the rollback logic."""
    try:
        db.execute(text("SELECT 1"))
    except Exception:
        raise HTTPException(status_code=503, detail="database unavailable")
    return {"status": "ok", "version": APP_VERSION}


@app.get("/contacts", response_model=list[ContactOut])
def list_contacts(db: Session = Depends(get_db)):
    return db.query(Contact).order_by(Contact.id).all()


@app.post("/contacts", response_model=ContactOut, status_code=201)
def create_contact(payload: ContactIn, db: Session = Depends(get_db)):
    contact = Contact(**payload.model_dump())
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


@app.delete("/contacts/{contact_id}")
def delete_contact(contact_id: int, db: Session = Depends(get_db)):
    contact = db.get(Contact, contact_id)
    if contact is None:
        raise HTTPException(status_code=404, detail="Contact not found")
    db.delete(contact)
    db.commit()
    return {"deleted": contact_id}
