#!/bin/bash
set -e

# 自动获取当前目录（保持CODE_PATH=$(pwd)）
CODE_PATH=$(pwd)

# ==================== 固定配置参数 ====================
CONTAINER_NAME="qwen3vl-sophon-service"
LOCAL_IMAGE="qwen3vl-sophon-service:py310"           # 本地目标镜像
REMOTE_IMAGE="registry.cn-hangzhou.aliyuncs.com/koudaimao/qwen3vl-sophon-service:py310"  # 阿里云远程镜像
TAR_FILE="qwen3vl-sophon-service-py310.tar"         # 本地tar包文件名

# ===================== 可配置参数（默认值）=============
DEFAULT_MODEL_DIR="./models/qwen3vl_2b"
DEFAULT_MAX_CONCURRENT="10"
DEFAULT_PORT="8899"
DEFAULT_API_KEY="abc@123"

# ===================== 解析命令行参数 ================
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
        *) echo "❌ 未知参数: $1"; exit 1 ;;
    esac
done

# 拼接启动命令参数
PY_ARGS="-m ${MODEL_DIR} -c ${MAX_CONCURRENT} -p ${PORT}"
if [[ -n "${API_KEY}" ]]; then
    PY_ARGS="${PY_ARGS} --api-key ${API_KEY}"
fi

echo -e "\n==================== 服务配置信息 ===================="
echo "模型目录：${MODEL_DIR}"
echo "最大并发：${MAX_CONCURRENT}"
echo "服务端口：${PORT}"
echo "API Key：${API_KEY:-未设置}"
echo "======================================================"

# 1. 检查本地是否已存在目标镜像
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${LOCAL_IMAGE}$"; then
    echo -e "\n✅ 检测到本地镜像：${LOCAL_IMAGE}，直接使用"
else
    echo -e "\n❌ 未检测到本地镜像，尝试加载本地tar包..."
    # 2. 检查本地tar包是否存在，存在则加载
    if [ -f "${TAR_FILE}" ]; then
        echo -e "✅ 检测到本地tar包：${TAR_FILE}，开始加载镜像..."
        sudo docker load -i "${TAR_FILE}"
        echo -e "✅ 镜像加载完成！"
    # 3. 无tar包则从阿里云拉取，并打标签为本地目标镜像
    else
        echo -e "❌ 未检测到本地tar包，从阿里云仓库拉取镜像..."
        sudo docker pull "${REMOTE_IMAGE}"
        sudo docker tag "${REMOTE_IMAGE}" "${LOCAL_IMAGE}"
        echo -e "✅ 镜像拉取并打标签完成！"
    fi
fi

sudo docker rm -f "${CONTAINER_NAME}" || true

sudo docker run -d \
  --name ${CONTAINER_NAME} \
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
  ${LOCAL_IMAGE} \
  /bin/bash -c "python main_serving.py ${PY_ARGS}"

echo -e "\n======================================================"
echo -e "✅ 容器 ${CONTAINER_NAME} 启动成功！"
echo -e "📡 服务端口：${PORT}"
echo -e "查看实时日志：sudo docker logs -f ${CONTAINER_NAME}"
echo -e "服务地址：http://宿主机IP:${PORT}"
echo -e "======================================================\n"