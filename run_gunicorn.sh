#!/bin/bash
set -e

# Asignar la propiedad del volumen de almacenamiento al usuario 'appuser'
# Esto soluciona el error de permisos [Errno 13] Permission denied
chown -R appuser:appuser /app/storage

# Ejecutar el proceso principal de Gunicorn como el usuario 'appuser'
# 'exec' reemplaza el proceso actual, y 'gosu' cambia de usuario de forma segura
exec gosu appuser gunicorn --bind 0.0.0.0:8080 \
    --workers ${GUNICORN_WORKERS:-2} \
    --timeout ${GUNICORN_TIMEOUT:-300} \
    --keep-alive 80 \
    app:app