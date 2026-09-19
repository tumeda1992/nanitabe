#!/bin/bash
set -e

echo "[entrypoint] rails db:migrate を開始します"
bundle exec rails db:migrate
echo "[entrypoint] rails db:migrate が完了しました"

exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"
