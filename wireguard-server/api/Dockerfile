FROM python:3.12-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wireguard-tools \
        iptables \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY server.py .

EXPOSE 3860

CMD ["gunicorn", "--bind", "0.0.0.0:3860", "--workers", "2", "--timeout", "30", "server:app"]
