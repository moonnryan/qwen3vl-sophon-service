FROM python:3.10-slim

LABEL authors="moonnryan"
LABEL version="0.1.0"
LABEL description="Qwen3-VL FastAPI Inference Service (Sophon BM1684X SE7)"

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
        libopencv-dev \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple \
    && pip install --no-cache-dir \
    fastapi==0.119.0 \
    uvicorn==0.38.0 \
    uvloop==0.22.1 \
    httptools==0.7.1 \
    numpy==1.26.4 \
    requests==2.32.3 \
    torch==2.4.1 \
    torchvision==0.19.1 \
    transformers==4.57.1 \
    qwen-vl-utils==0.0.14 \
    python-multipart==0.0.20 \
    -i https://pypi.tuna.tsinghua.edu.cn/simple