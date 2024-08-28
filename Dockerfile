# Stage 1: Build frontend
FROM node:20 AS frontend-builder

WORKDIR /app/frontend

# Copy frontend files
COPY app/frontend/package*.json ./
RUN npm install

COPY app/frontend .
RUN npm run build

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Set work directory
WORKDIR /app

# Install Python and pip
RUN apt-get update && apt-get install -y \
    curl \
    python3.12  \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Create a symbolic link for python
RUN ln -s /usr/bin/python3.12 /usr/bin/python

# Copy backend requirements
COPY app/backend/requirements.txt ./backend/

# Install Python dependencies
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"
RUN pip install --no-cache-dir -r backend/requirements.txt

# Copy backend code
COPY app/backend ./backend

# Copy built frontend from the previous stage
COPY --from=frontend-builder /app/frontend ./frontend

# Set environment variables
ENV PORT=50505
ENV HOST=0.0.0.0

# Expose the port the app runs on
EXPOSE 50505

CMD ["/bin/sh" , "-c", "az login --service-principal --username $SP_APP_ID --tenant $SP_TENANT_ID --password $SP_PASSWORD && cd backend && python3 -m quart --app main:app run --port 50505 --host 0.0.0.0"]