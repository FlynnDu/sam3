FROM registry.cn-shenzhen.aliyuncs.com/flynndu/torch:2.8.0-cuda12.9.1-devel-ubuntu24.04 AS builder

COPY . /app/sam3
RUN --mount=type=cache,target=/root/.cache/pip \
    cd /app/sam3 && pip install . \
    -i https://pypi.tuna.tsinghua.edu.cn/simple

FROM registry.cn-shenzhen.aliyuncs.com/flynndu/torch:2.8.0-cuda12.9.1-devel-ubuntu24.04

COPY --from=builder \
    /opt/venv/lib/python3.12/site-packages \
    /opt/venv/lib/python3.12/site-packages

# docker build -f Dockerfile -t registry.cn-shenzhen.aliyuncs.com/flynndu/sam3.1:torch2.8.0-cuda12.9.1-devel-ubuntu24.04 .