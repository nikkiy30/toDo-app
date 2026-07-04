from pathlib import Path
import os
import time

import psycopg2
from psycopg2.extras import RealDictCursor
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field


app = FastAPI(title="Docker TODO App")

BASE_DIR = Path(__file__).resolve().parent

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "todo-db"),
    "database": os.getenv("DB_NAME", "tododb"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
}


def get_db_connection():
    for _ in range(10):
        try:
            return psycopg2.connect(**DB_CONFIG)
        except psycopg2.OperationalError:
            time.sleep(1)

    raise RuntimeError("データベースに接続できませんでした。")


def init_db():
    conn = get_db_connection()

    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS todos (
                        id SERIAL PRIMARY KEY,
                        title TEXT NOT NULL
                    );
                """)
    finally:
        conn.close()


@app.on_event("startup")
def startup_event():
    init_db()


class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)


@app.get("/", response_class=HTMLResponse)
def read_root():
    html_path = BASE_DIR / "index.html"
    return HTMLResponse(html_path.read_text(encoding="utf-8"))


@app.get("/todos")
def get_todos():
    conn = get_db_connection()

    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, title FROM todos ORDER BY id DESC;")
            return cur.fetchall()
    finally:
        conn.close()


@app.post("/todos", status_code=status.HTTP_201_CREATED)
def create_todo(item: TodoCreate):
    title = item.title.strip()

    if not title:
        raise HTTPException(status_code=400, detail="TODOの内容を入力してください。")

    conn = get_db_connection()

    try:
        with conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    "INSERT INTO todos (title) VALUES (%s) RETURNING id, title;",
                    (title,)
                )
                return cur.fetchone()
    finally:
        conn.close()


@app.delete("/todos/{todo_id}")
def delete_todo(todo_id: int):
    conn = get_db_connection()

    try:
        with conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cur:
                cur.execute(
                    "DELETE FROM todos WHERE id = %s RETURNING id;",
                    (todo_id,)
                )
                deleted = cur.fetchone()

                if deleted is None:
                    raise HTTPException(status_code=404, detail="TODOが見つかりません。")

                return {"status": "deleted", "id": deleted["id"]}
    finally:
        conn.close()