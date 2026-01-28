#!/bin/sh
set -eu

log() {
  printf '%s\n' "$*" >&2
}

lower() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]'
}

is_true() {
  case "$(lower "${1:-}")" in
    1|true|yes|y|on) return 0 ;;
    *) return 1 ;;
  esac
}

DATA_DIR="${DATA_DIR:-/data}"
SERVER_DIR="${SERVER_DIR:-/data/server}"

check_dir_writable() {
  dir="$1"
  if [ ! -w "${dir}" ]; then
    log "ERROR: Cannot write to ${dir}"
    log "ERROR: Directory exists but is not writable by UID $(id -u)."
    log "ERROR: Current owner: $(ls -ld "${dir}" 2>/dev/null | awk '{print $3":"$4}')"
    log "ERROR: Fix: 'sudo chown -R $(id -u):$(id -g) <host-path>'"
    exit 1
  fi
}

HYTALE_SERVER_JAR="${HYTALE_SERVER_JAR:-${SERVER_DIR}/HytaleServer.jar}"
HYTALE_ASSETS_PATH="${HYTALE_ASSETS_PATH:-${DATA_DIR}/Assets.zip}"

# F2P download configuration
# Default to auth.sanasol.ws which is the unified F2P auth endpoint
HYTALE_F2P_DOWNLOAD_BASE="${HYTALE_F2P_DOWNLOAD_BASE:-https://download.sanasol.ws/download}"
HYTALE_F2P_DOWNLOAD_LOCK="${HYTALE_F2P_DOWNLOAD_LOCK:-true}"
HYTALE_F2P_AUTO_UPDATE="${HYTALE_F2P_AUTO_UPDATE:-false}"

mkdir -p "${SERVER_DIR}"
check_dir_writable "${SERVER_DIR}"

# Lock to avoid multiple containers downloading into the same volume simultaneously.
LOCK_DIR="${DATA_DIR}/.hytale-download-lock"
LOCK_CREATED_AT_PATH="${LOCK_DIR}/created_at_epoch"
LOCK_TTL_SECONDS=300

lock_acquired=0

cleanup() {
  if [ "${lock_acquired}" -eq 1 ]; then
    rm -rf "${LOCK_DIR}" 2>/dev/null || true
  fi
}

if is_true "${HYTALE_F2P_DOWNLOAD_LOCK}"; then
  trap cleanup EXIT INT TERM

  for _i in 1 2 3 4 5 6 7 8 9 10; do
    if mkdir "${LOCK_DIR}" 2>/dev/null; then
      lock_acquired=1
      now_epoch="$(date +%s 2>/dev/null || echo 0)"
      printf '%s\n' "${now_epoch}" >"${LOCK_CREATED_AT_PATH}" 2>/dev/null || true
      printf '%s\n' "$$" >"${LOCK_DIR}/pid" 2>/dev/null || true
      break
    fi

    if [ -f "${LOCK_CREATED_AT_PATH}" ]; then
      created_epoch="$(cat "${LOCK_CREATED_AT_PATH}" 2>/dev/null || echo 0)"
      now_epoch="$(date +%s 2>/dev/null || echo 0)"
      if [ "${created_epoch}" -gt 0 ] && [ $((now_epoch - created_epoch)) -ge "${LOCK_TTL_SECONDS}" ]; then
        log "F2P download: stale lock detected at ${LOCK_DIR} (older than ${LOCK_TTL_SECONDS}s); removing"
        rm -rf "${LOCK_DIR}" 2>/dev/null || true
        continue
      fi
    fi

    log "F2P download: another container may be downloading into ${DATA_DIR}; waiting for lock (${LOCK_DIR})"
    log "F2P download: if this gets stuck, delete ${LOCK_DIR} or set HYTALE_F2P_DOWNLOAD_LOCK=false (power users)"
    sleep 3
  done

  if [ "${lock_acquired}" -ne 1 ]; then
    log "ERROR: F2P download: could not acquire lock ${LOCK_DIR}"
    log "ERROR: If no other container is running, the lock may be stale. You can delete ${LOCK_DIR} and try again."
    log "ERROR: Power users can disable the lock with HYTALE_F2P_DOWNLOAD_LOCK=false"
    exit 1
  fi
else
  log "F2P download: download lock disabled via HYTALE_F2P_DOWNLOAD_LOCK=false"
fi

# Check if files already present
server_files_present=0
if [ -f "${HYTALE_SERVER_JAR}" ] && [ -f "${HYTALE_ASSETS_PATH}" ]; then
  server_files_present=1
  if ! is_true "${HYTALE_F2P_AUTO_UPDATE}"; then
    log "F2P download: server files already present and HYTALE_F2P_AUTO_UPDATE=false; skipping"
    exit 0
  fi
  log "F2P download: server files already present; HYTALE_F2P_AUTO_UPDATE=true, re-downloading"
fi

# Download function with retries and line-by-line progress
# Progress is printed on new lines so it shows in Docker logs
download_file() {
  _url="$1"
  _dest="$2"
  _name="$3"
  _expected_mb="${4:-0}"

  log "F2P download: downloading ${_name} from ${_url}"
  if [ "${_expected_mb}" -gt 0 ] 2>/dev/null; then
    log "F2P download: expected size ~${_expected_mb} MB"
  fi

  # Use temp file for atomic download
  _tmp_dest="${_dest}.tmp"

  for _attempt in 1 2 3; do
    rm -f "${_tmp_dest}" 2>/dev/null || true

    # Start curl in background (silent mode)
    curl -fL -s -o "${_tmp_dest}" "${_url}" &
    _curl_pid=$!

    # Monitor progress every 5 seconds
    _last_size=0
    while kill -0 ${_curl_pid} 2>/dev/null; do
      sleep 5
      if [ -f "${_tmp_dest}" ]; then
        _current_size=$(stat -c%s "${_tmp_dest}" 2>/dev/null || stat -f%z "${_tmp_dest}" 2>/dev/null || echo "0")
        _current_mb=$((_current_size / 1024 / 1024))

        # Calculate speed
        _delta=$((_current_size - _last_size))
        _speed_mb=$((_delta / 1024 / 1024 / 5))

        if [ "${_expected_mb}" -gt 0 ] 2>/dev/null; then
          _pct=$((_current_mb * 100 / _expected_mb))
          if [ ${_speed_mb} -lt 1 ]; then
            _speed_kb=$((_delta / 1024 / 5))
            log "F2P download: ${_name} - ${_current_mb}/${_expected_mb} MB (${_pct}%) - ${_speed_kb} KB/s"
          else
            log "F2P download: ${_name} - ${_current_mb}/${_expected_mb} MB (${_pct}%) - ${_speed_mb} MB/s"
          fi
        else
          if [ ${_speed_mb} -lt 1 ]; then
            _speed_kb=$((_delta / 1024 / 5))
            log "F2P download: ${_name} - ${_current_mb} MB - ${_speed_kb} KB/s"
          else
            log "F2P download: ${_name} - ${_current_mb} MB - ${_speed_mb} MB/s"
          fi
        fi
        _last_size=${_current_size}
      fi
    done

    # Check if curl succeeded
    wait ${_curl_pid}
    _curl_exit=$?

    if [ ${_curl_exit} -eq 0 ] && [ -f "${_tmp_dest}" ]; then
      _final_size=$(stat -c%s "${_tmp_dest}" 2>/dev/null || stat -f%z "${_tmp_dest}" 2>/dev/null || echo "0")
      _final_mb=$((_final_size / 1024 / 1024))
      log "F2P download: ${_name} downloaded (${_final_mb} MB)"
      mv "${_tmp_dest}" "${_dest}"
      return 0
    fi

    log "F2P download: attempt ${_attempt} failed for ${_name}, retrying..."
    rm -f "${_tmp_dest}" 2>/dev/null || true
    sleep 2
  done

  log "ERROR: F2P download: failed to download ${_name} after 3 attempts"
  rm -f "${_tmp_dest}" 2>/dev/null || true
  return 1
}

# Download HytaleServer.jar if missing
if [ ! -f "${HYTALE_SERVER_JAR}" ] || is_true "${HYTALE_F2P_AUTO_UPDATE}"; then
  JAR_URL="${HYTALE_F2P_DOWNLOAD_BASE}/HytaleServer.jar"
  if ! download_file "${JAR_URL}" "${HYTALE_SERVER_JAR}" "HytaleServer.jar" "80"; then
    log "ERROR: Failed to download HytaleServer.jar"
    log "ERROR: Check if ${JAR_URL} is accessible"
    exit 1
  fi
fi

# Download Assets.zip if missing
if [ ! -f "${HYTALE_ASSETS_PATH}" ] || is_true "${HYTALE_F2P_AUTO_UPDATE}"; then
  ASSETS_URL="${HYTALE_F2P_DOWNLOAD_BASE}/Assets.zip"
  log "F2P download: Assets.zip is a large file, this may take a while..."
  if ! download_file "${ASSETS_URL}" "${HYTALE_ASSETS_PATH}" "Assets.zip" "3300"; then
    log "ERROR: Failed to download Assets.zip"
    log "ERROR: Check if ${ASSETS_URL} is accessible"
    exit 1
  fi
fi

# Verify files
if [ ! -f "${HYTALE_SERVER_JAR}" ]; then
  log "ERROR: F2P download: HytaleServer.jar not found after download at ${HYTALE_SERVER_JAR}"
  exit 1
fi

if [ ! -f "${HYTALE_ASSETS_PATH}" ]; then
  log "ERROR: F2P download: Assets.zip not found after download at ${HYTALE_ASSETS_PATH}"
  exit 1
fi

# Mark download source
printf 'f2p\n' > "${DATA_DIR}/.hytale-download-source"

log "F2P download: done"
log "F2P download: Server JAR: ${HYTALE_SERVER_JAR}"
log "F2P download: Assets: ${HYTALE_ASSETS_PATH}"
