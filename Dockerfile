# =============================================================================
# STAGE 1: BUILDER
# Aquí se instalan todas las herramientas pesadas y se compila FFmpeg.
# =============================================================================
FROM python:3.9-slim as builder

# Instalar todas las dependencias de compilación y de ejecución.
# Los paquetes están ordenados alfabéticamente para facilitar la lectura.
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    fontconfig \
    fonts-liberation \
    git \
    libaom-dev \
    libasound2 \
    libass-dev \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdav1d-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libfribidi-dev \
    libgbm1 \
    libgnutls28-dev \
    libharfbuzz-dev \
    libmp3lame-dev \
    libnss3 \
    libnuma-dev \
    libopus-dev \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    librav1e-dev \
    libspeex-dev \
    libssl-dev \
    libsvtav1enc-dev \
    libtheora-dev \
    libtool \
    libunibreak-dev \
    libvorbis-dev \
    libvpx-dev \
    libwebp-dev \
    libx264-dev \
    libx265-dev \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libzimg-dev \
    meson \
    nasm \
    ninja-build \
    pkg-config \
    tar \
    wget \
    xz-utils \
    yasm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Compilar e instalar todas las dependencias de FFmpeg desde el código fuente
RUN git clone https://github.com/mstorsjo/fdk-aac.git && \
    cd fdk-aac && autoreconf -fiv && ./configure && make -j$(nproc) && make install && cd .. && rm -rf fdk-aac && \
    \
    git clone https://github.com/libass/libass.git && \
    cd libass && autoreconf -i && ./configure --enable-shared && make -j$(nproc) && make install && cd .. && rm -rf libass && \
    \
    ldconfig

# Construir e instalar FFmpeg
RUN git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg && \
    cd ffmpeg && \
    git checkout n7.0.2 && \
    PKG_CONFIG_PATH="/usr/local/lib/pkgconfig" ./configure \
        --prefix=/usr/local \
        --enable-gpl \
        --enable-nonfree \
        --enable-libaom \
        --enable-libass \
        --enable-libdav1d \
        --enable-libfdk-aac \
        --enable-libfreetype \
        --enable-libharfbuzz \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-librav1e \
        --enable-libsvtav1 \
        --enable-libtheora \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libwebp \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libzimg \
        --enable-gnutls \
    && make -j$(nproc) && \
    make install && \
    cd .. && rm -rf ffmpeg

# =============================================================================
# STAGE 2: FINAL IMAGE
# Construimos la imagen final, que es mucho más ligera.
# =============================================================================
FROM python:3.9-slim

# =========== AÑADE ESTAS DOS LÍNEAS AQUÍ ===========
# "Hornea" la variable de entorno en la imagen durante la construcción.
ARG LOCAL_STORAGE_PATH
ENV LOCAL_STORAGE_PATH=${LOCAL_STORAGE_PATH}
# ======================================================

# Instalar solo las dependencias de EJECUCIÓN necesarias + gosu para manejo de permisos
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    fontconfig \
    gosu \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libpangoft2-1.0-0 \
    libpangocairo-1.0-0 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    && rm -rf /var/lib/apt/lists/*

# Copiar los binarios compilados (FFmpeg, etc.) desde la etapa de "builder"
COPY --from=builder /usr/local/ /usr/local/
RUN ldconfig

# Copiar las fuentes y reconstruir la caché
COPY ./fonts /usr/share/fonts/custom
RUN fc-cache -f -v

WORKDIR /app

# Instalar dependencias de Python
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install openai-whisper jsonschema playwright

# Crear usuario no-root por seguridad
RUN useradd --create-home --shell /bin/bash appuser

# Descargar el modelo de Whisper y el navegador Playwright
ENV WHISPER_CACHE_DIR="/home/appuser/.cache/whisper"
RUN mkdir -p ${WHISPER_CACHE_DIR} && chown -R appuser:appuser /home/appuser
USER appuser
RUN python -c "import whisper; whisper.load_model('base')"
RUN playwright install chromium
USER root

# Copiar el resto del código de la aplicación, asignando propiedad a appuser
COPY --chown=appuser:appuser . .

# Exponer el puerto de la aplicación
EXPOSE 8080

# Establecer la variable de entorno
ENV PYTHONUNBUFFERED=1

# El CMD se ejecutará como root, y el script se encargará de cambiar a 'appuser'
CMD ["./run_gunicorn.sh"]