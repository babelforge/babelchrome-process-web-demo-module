#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
PORT="$(/usr/bin/ruby -rsocket -e 'server = TCPServer.new("127.0.0.1", 0); puts server.addr[1]; server.close')"
LOG_FILE="${TMPDIR:-/tmp}/babelchrome-process-web-demo-${PORT}.log"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
  rm -f "${LOG_FILE}"
}
trap cleanup EXIT

BABELCHROME_MODULE_ID="babelforge.process-web-demo" \
BABELCHROME_MODULE_DIR="${MODULE_DIR}" \
BABELCHROME_PORT="${PORT}" \
PORT="${PORT}" \
  /usr/bin/ruby "${MODULE_DIR}/server/app.rb" --port "${PORT}" >"${LOG_FILE}" 2>&1 &
SERVER_PID="$!"

for _ in {1..50}; do
  if /usr/bin/ruby -rnet/http -e "response = Net::HTTP.get_response(URI('http://127.0.0.1:${PORT}/health')); exit(response.code.to_i == 200 ? 0 : 1)" 2>/dev/null; then
    break
  fi

  sleep 0.1
done

/usr/bin/ruby -rnet/http -e "response = Net::HTTP.get_response(URI('http://127.0.0.1:${PORT}/health')); exit(response.code.to_i == 200 ? 0 : 1)"

BODY="$(/usr/bin/ruby -rnet/http -e "uri = URI('http://127.0.0.1:${PORT}/index'); request = Net::HTTP::Get.new(uri); request['X-BabelChrome-Module-Route'] = 'index'; request['X-BabelChrome-Source-Url'] = 'https://example.com/source'; request['X-BabelChrome-File-Types'] = 'md,json'; response = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(request) }; print response.body; exit(response.code.to_i == 200 ? 0 : 1)")"

printf '%s' "${BODY}" | grep 'Process Web Demo' >/dev/null
printf '%s' "${BODY}" | grep 'process-web' >/dev/null
printf '%s' "${BODY}" | grep 'https://example.com/source' >/dev/null

printf 'Process web demo smoke test passed.\n'
