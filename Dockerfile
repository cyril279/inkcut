# ---------- Stage 1: Builder ----------
FROM alpine:3 AS builder

# Install runtime + build dependencies
RUN apk add --no-cache \
    python3 \
    py3-lxml \
    py3-pip \
    py3-pycups \
    py3-packaging \
    py3-qt6 \
    qt6-qtbase-dev \
    qt6-qtwayland-dev \
    build-base \
    cups-dev

# Create & activate virtual env, and install inkcut there-into
RUN python3 -m venv --system-site-packages /opt/inkcut-env
ENV PATH="/opt/inkcut-env/bin:$PATH"
RUN pip install --no-cache-dir inkcut

# Generate the .desktop file
RUN mkdir -p /output/usr/share/applications && \
    cat > /output/usr/share/applications/inkcut.desktop <<'EOL'
[Desktop Entry]
Name=Inkcut
GenericName=Terminal entering Inkcut
Comment=Terminal entering Inkcut
Categories=Distrobox;System;Utility
Exec=inkcut
Icon=/usr/share/icons/inkcut.svg
Keywords=distrobox;
NoDisplay=false
Terminal=false
Type=Application
EOL

# ---------- Stage 2: Runtime ----------
FROM alpine:3

# Install runtime dependencies
RUN apk add --no-cache \
    python3 \
    py3-lxml \
    py3-pycups \
    py3-packaging \
    py3-qt6 \
    cups-libs \
    qt6-qtbase \
    qt6-qtsvg \
    qt6-qtdeclarative \
    qt6-qtserialport \
    qt6-qtwayland

# Copy (& reference) the virtual environment from the builder stage
COPY --from=builder /opt/inkcut-env /opt/inkcut-env
ENV PATH="/opt/inkcut-env/bin:$PATH"

#ENV QT_QPA_PLATFORM=xcb

# Gather desktop-launcher components
COPY --from=builder /output/usr/share/applications/inkcut.desktop /usr/share/applications/inkcut.desktop
RUN cp /opt/inkcut-env/lib/python*/site-packages/inkcut/res/media/inkcut.svg /usr/share/icons/inkcut.svg 2>/dev/null || true

# Set the entrypoint
CMD ["inkcut"]
