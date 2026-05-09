#!/bin/bash
CONTAINER_NAME="qwen3vl-sophon-service"
IMAGE_NAME="sophon-qwen3vl-serving:py310"
CODE_PATH=$(pwd)

# ===================== 可配置参数（默认值）=====================
DEFAULT_MODEL_DIR="./models/qwen3vl_2b"
DEFAULT_MAX_CONCURRENT="10"
DEFAULT_PORT="8899"
DEFAULT_API_KEY="abc@123"

# ===================== 解析命令行参数 =====================
MODEL_DIR="${DEFAULT_MODEL_DIR}"
MAX_CONCURRENT="${DEFAULT_MAX_CONCURRENT}"
PORT="${DEFAULT_PORT}"
API_KEY="${DEFAULT_API_KEY}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --model_dir) MODEL_DIR="$2"; shift 2 ;;
        --max_concurrent) MAX_CONCURRENT="$2"; shift 2 ;;
        --port) PORT="$2"; shift 2 ;;
        --api-key) API_KEY="$2"; shift 2 ;;
        *) echo "未知参数: $1"; exit 1 ;;
    esac
done

# 拼接启动命令参数
PY_ARGS="-m ${MODEL_DIR} -c ${MAX_CONCURRENT} -p ${PORT}"
if [[ -n "${API_KEY}" ]]; then
    PY_ARGS="${PY_ARGS} --api-key ${API_KEY}"
fi

echo "===== 服务配置信息 ====="
echo "模型目录：${MODEL_DIR}"
echo "最大并发：${MAX_CONCURRENT}"
echo "服务端口：${PORT}"
echo "API Key：${API_KEY:-未设置}"
echo "========================"

echo "===== 停止并删除旧容器 $CONTAINER_NAME ====="
docker stop $CONTAINER_NAME >/dev/null 2>&1
docker rm $CONTAINER_NAME >/dev/null 2>&1

echo "===== 启动新容器 $CONTAINER_NAME ====="
docker run -d \
  --name $CONTAINER_NAME \
  --privileged \
  --restart unless-stopped \
  -p ${PORT}:${PORT} \
  -v /opt/sophon:/opt/sophon \
  -v ${CODE_PATH}:/data/qwen3vl-service \
  -v /data:/data \
  -v /dev:/dev \
  -w /data/qwen3vl-service \
  --log-driver json-file \
  --log-opt max-size=200m \
  --log-opt max-file=2 \
  --shm-size=2g \
  $IMAGE_NAME \
  /bin/bash -c "python main_serving.py ${PY_ARGS}"

echo "===== 容器启动完成 ====="
echo "查看实时日志：docker logs -f ${CONTAINER_NAME}"
echo "进入容器终端：docker exec -it ${CONTAINER_NAME} /bin/bash"
echo "服务地址：http://宿主机IP:${PORT}"