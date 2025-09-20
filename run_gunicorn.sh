#!/bin/bash
set -e

# Asignar la propiedad del volumen de almacenamiento al usuario 'appuser'
# Esto se ejecuta para preparar el entorno, aunque la app no inicie.
chown -R appuser:appuser /app/storage

# ----------------- MODO DE DEPURACIÓN -----------------
# Hemos comentado la línea que inicia la aplicación para que no se cierre si hay un error.
# En su lugar, el contenedor se quedará esperando infinitamente.
#
# exec gosu appuser gunicorn --bind 0.0.0.0:8080 \
#     --workers ${GUNICORN_WORKERS:-2} \
#     --timeout ${GUNICORN_TIMEOUT:-300} \
#     --keep-alive 80 \
#     app:app

echo "Modo de depuración activado. El contenedor permanecerá en ejecución."
echo "Accede a la terminal del servicio en Coolify para investigar."
sleep infinity
