#!/bin/bash
set -e

# Inicia Gunicorn con las variables de entorno para workers y timeout
# Si no se definen, usa 2 workers y 300 segundos de timeout por defecto.
gunicorn --bind 0.0.0.0:8080 \
    --workers ${GUNICORN_WORKERS:-2} \
    --timeout ${GUNICORN_TIMEOUT:-300} \
    --keep-alive 80 \
    app:app
