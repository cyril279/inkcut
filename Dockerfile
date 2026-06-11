# ---------- Stage 1: Builder ----------
FROM alpine:3.24 AS builder

# Install runtime + build dependencies
# py3-lxml satisfies the lxml requirement, so pip won't try to compile it.
# qt5-qtbase-dev is still needed if enaml requires compilation against Qt headers.
RUN apk add --no-cache \
    python3 \
    py3-pip \
    py3-pycups \
    py3-lxml \
    py3-qt6 \
    qt6-qtbase-dev \
    build-base \
    cups-dev

# Install Inkcut from PyPI
# --break-system-packages is required for Alpine 3.19+
RUN pip3 install --no-cache-dir --break-system-packages inkcut

# ---------- Stage 2: Runtime ----------
FROM alpine:3.24

# Install runtime dependencies
# Include py3-lxml here too, as it was used in builder
RUN apk add --no-cache \
    python3 \
    py3-pycups \
    py3-qt6 \
    py3-lxml \
    cups-libs \
    qt6-qtbase \
    qt6-qtsvg \
    qt6-qtdeclarative \
    qt6-qtserialport

WORKDIR /app

# Copy Python site-packages from builder
# Includes inkcut, enaml, pyqtgraph, and any pure-python deps
COPY --from=builder /usr/lib/python3.14/site-packages /usr/lib/python3.14/site-packages

# Copy executable scripts (inkcut)
COPY --from=builder /usr/bin/inkcut /usr/bin/inkcut

# Ensure the script is executable
RUN chmod +x /usr/bin/inkcut

ENV PATH="/usr/bin:$PATH"

CMD ["inkcut"]
