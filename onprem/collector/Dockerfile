# Small image that only runs the collector.
FROM python:3.12-slim
WORKDIR /app
# Install dependencies first: Docker reuses this layer as long as requirements.txt does not change.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY collector.py .
# Run as a normal user, not root.
USER nobody
ENTRYPOINT ["python", "collector.py"]
