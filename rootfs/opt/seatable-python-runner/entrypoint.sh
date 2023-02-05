#!/bin/bash

# Seatable FAAS Runner entrypoint

# Author: Vitali Quiering (vitali@quiering.com)

set -eu

_FAAS_SCHEDULER_URL="${FAAS_SCHEDULER_URL:?scheduler url missing}"

_SEATABLE_RUNNER_IMAGE="${SEATABLE_RUNNER_IMAGE:-seatable/python-runner:latest}"

# wait until docker is available
echo "wait for docker to become available"
while ! docker ps -a > /dev/null; do sleep 1; done

mkdir -p conf || ( echo "could not create conf directory" && exit 1 )
mkdir -p logs || ( echo "could not create logs directory" && exit 1 )

echo "SCHEDULER_URL = \"${_FAAS_SCHEDULER_URL}\"" > conf/seatable_python_runner_settings.py

_IMAGE_COUNT=$(docker image ls | awk -vt=: '{print $1t$2}' | grep "${_SEATABLE_RUNNER_IMAGE}" | wc -l)

if [[ "${_IMAGE_COUNT}" -eq 0 ]]; then
    docker pull "${_SEATABLE_RUNNER_IMAGE}"
fi

export IMAGE="${_SEATABLE_RUNNER_IMAGE}"

uwsgi --http ":8080" \
      --wsgi-file "function.py" \
      --callable "app" \
      --process 4 \
      --threads 2 \
      --buffer-size 65536 \
      --stats "127.0.0.1:9191" \
      --procname-prefix "run-python" \
      --logformat "[%(ltime)] %(method) %(uri) => generated %(size) bytes in %(secs) seconds"

exit 0
