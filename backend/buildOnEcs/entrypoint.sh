#!/bin/bash
set -e

bundle exec rails db:migrate

exec bundle exec puma -b "tcp://0.0.0.0:${PORT}"
