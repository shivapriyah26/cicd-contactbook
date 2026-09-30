# ---------- Stage 1: base (production dependencies only) ----------
FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------- Stage 2: test (CI runs this; the build FAILS if a test fails) ----------
FROM base AS test
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY pytest.ini .
COPY app ./app
COPY tests ./tests
RUN pytest -v

# ---------- Stage 3: runtime (small, no test tools, non-root user) ----------
FROM base AS runtime
RUN useradd --create-home --shell /usr/sbin/nologin appuser
COPY app ./app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
