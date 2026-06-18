FROM python:3.11-slim
RUN pip install litellm[proxy] prisma
COPY litellm-config.yaml /app/config.yaml
WORKDIR /app
EXPOSE 4000
CMD ["litellm", "--config", "config.yaml", "--port", "4000"]