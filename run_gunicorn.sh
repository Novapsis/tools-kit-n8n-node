#!/bin/bash
set -e

# Asignar la propiedad del volumen de almacenamiento al usuario 'appuser'
# Esto se mantiene por si en el futuro volvemos a usar almacenamiento local
chown -R appuser:appuser /app/storage

# Ejecutar el proceso principal de Gunicorn como el usuario 'appuser'
exec gosu appuser gunicorn --bind 0.0.0.0:8080 \
    --workers ${GUNICORN_WORKERS:-2} \
    --timeout ${GUNICORN_TIMEOUT:-300} \
    --keep-alive 80 \
    app:app