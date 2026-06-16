# ---------- Global definitions -----------
ARG envPath="/opt/inkcut-env"

# ---------- Stage 1: Builder ----------
FROM alpine:3 AS builder
ARG envPath

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
RUN python3 -m venv --system-site-packages $envPath
ENV PATH="$envPath/bin:$PATH"
RUN pip install --no-cache-dir inkcut

# Generate the .desktop file
RUN mkdir -p $envPath/share/applications
RUN cat > $envPath/share/applications/inkcut.desktop <<EOL
[Desktop Entry]
Name=Inkcut
GenericName=Terminal entering Inkcut
Comment=Terminal entering Inkcut
Categories=Distrobox;System;Utility
Exec=inkcut
Icon=$envPath/share/icons/inkcut.svg
Keywords=distrobox;
NoDisplay=false
Terminal=false
Type=Application
EOL

RUN mkdir $envPath/share/icons
RUN cp $envPath/lib/python*/site-packages/inkcut/res/media/inkcut.svg $envPath/share/icons/inkcut.svg

# ---------- Stage 2: Runtime ----------
FROM alpine:3
ARG envPath

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
COPY --from=builder $envPath $envPath
ENV PATH="$envPath/bin:$PATH"

#ENV QT_QPA_PLATFORM=xcb

# Set the entrypoint
CMD ["inkcut"]
