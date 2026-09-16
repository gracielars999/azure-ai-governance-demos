FROM python:3.11-slim
WORKDIR /app

COPY app/backend/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

COPY app/backend/ /app/
COPY app/frontend/ /app/frontend/
COPY knowledge/ /app/knowledge/

ENV PORT=8000
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
