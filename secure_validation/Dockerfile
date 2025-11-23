# Secure container for code validation
FROM python:3.11-slim

# Security: Create non-root user
RUN groupadd -r validator && useradd -r -g validator validator

# Security: Remove potentially dangerous tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # Only essential packages
        ca-certificates \
        && \
    # Remove package manager and other tools
    apt-get purge -y apt apt-get && \
    rm -rf /var/lib/apt/lists/* && \
    # Remove shells except minimal sh
    rm -f /bin/bash /usr/bin/bash && \
    # Remove network tools
    rm -f /usr/bin/wget /usr/bin/curl /usr/bin/nc /usr/bin/telnet && \
    # Remove system tools
    rm -f /bin/mount /bin/umount /usr/bin/sudo

# Install only required Python packages in isolated environment
RUN pip install --no-cache-dir --disable-pip-version-check \
    pytest==7.4.0 \
    pytest-json-report==1.5.0 \
    boto3==1.26.137 && \
    # Remove pip after installation
    pip uninstall -y pip setuptools && \
    # Clean Python cache
    find /usr/local -name "*.pyc" -delete && \
    find /usr/local -name "__pycache__" -type d -exec rm -rf {} +

# Create restricted working directory
RUN mkdir -p /workspace && \
    chown validator:validator /workspace && \
    chmod 750 /workspace

# Copy validation script
COPY --chown=validator:validator validator_script.py /workspace/

# Security: Restrict filesystem permissions
RUN chmod -R o-rwx /workspace && \
    # Make most of filesystem read-only
    chmod -R a-w /usr /etc /var || true

# Switch to non-root user
USER validator
WORKDIR /workspace

# Security: Limit environment variables
ENV HOME=/workspace
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/workspace

# Resource limits will be set by ECS task definition:
# - Memory: 512MB
# - CPU: 0.25 vCPU  
# - Execution time: 60 seconds max

ENTRYPOINT ["python3", "validator_script.py"]