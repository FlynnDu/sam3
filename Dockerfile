ARG MIRROR_URL=https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
ARG APP_UID=1011
ARG APP_GID=1011
ARG TORCH_IMAGE=registry.cn-shenzhen.aliyuncs.com/flynndu/torch:2.8.0-cu12.9.1-base-ubuntu24.04

# ============================================================
# Builder 阶段：安装 sam3
# ============================================================
FROM ${TORCH_IMAGE} AS builder

ARG MIRROR_URL
# ubuntu24.04 用 ubuntu.sources，不是 sources.list
RUN sed -i "s|http://archive.ubuntu.com/ubuntu/|${MIRROR_URL}|g" \
        /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY sam3 /app/sam3
RUN --mount=type=cache,target=/root/.cache/pip \
    cd /app/sam3 && pip install . -i https://pypi.tuna.tsinghua.edu.cn/simple

# ============================================================
# Runtime 阶段
# ============================================================
FROM ${TORCH_IMAGE} AS runtime

ARG MIRROR_URL
ARG APP_UID
ARG APP_GID

RUN sed -i "s|http://archive.ubuntu.com/ubuntu/|${MIRROR_URL}|g" \
        /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
        zip unzip tzdata curl && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo Asia/Shanghai > /etc/timezone && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid ${APP_GID} appuser && \
    useradd --uid ${APP_UID} --gid ${APP_GID} --no-create-home --shell /bin/false appuser

WORKDIR /app

# 只拷贝新装的包，不拷整个 /app/base（torch层已在父镜像里）
COPY --from=builder \
    /app/base/lib/python3.12/site-packages \
    /app/base/lib/python3.12/site-packages

ENV PATH=/app/base/bin:$PATH
ENV PYTORCH_ALLOC_CONF=expandable_segments:True
ENV APP_PROJECT_ROOT=/app
ENV ORT_DISABLE_GPU_DEVICE_DISCOVERY=1
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Shanghai
ENV LOG_LEVEL=INFO

USER appuser


# docker build -f Dockerfile -t registry.cn-shenzhen.aliyuncs.com/flynndu/sam3-base:3.1 .