#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# Build script for exitsama (Samarinda Session Termination Dialog)

TARGET="${1:-compile}"
FTPAS_DIR="../ftpas"
FT_DIR="../../floria-toolkit"

ensure_libft() {
  mkdir -p target
  if [ -f "${FT_DIR}/target/libft.so" ]; then
    cp -f "${FT_DIR}/target/libft.so" target/libft.so
  elif [ -f "${FTPAS_DIR}/target/libft.so" ]; then
    cp -f "${FTPAS_DIR}/target/libft.so" target/libft.so
  fi
}

case "${TARGET}" in
  test)
    ensure_libft
    echo "==> Running tests with pasbuild..."
    shift 1 || true
    pasbuild test "$@"
    ;;
  clean)
    echo "==> Cleaning target artifacts..."
    shift 1 || true
    pasbuild clean "$@"
    ;;
  install)
    PREFIX="${PREFIX:-/usr}"
    echo "==> Installing exitsama to ${PREFIX}..."
    install -d "${PREFIX}/bin"
    install -m 755 target/exitsama "${PREFIX}/bin/exitsama"
    install -d "${PREFIX}/share/applications"
    install -m 644 exitsama.desktop "${PREFIX}/share/applications/exitsama.desktop"
    if [ -f data/10-samarinda-actions.rules ]; then
      install -d /etc/polkit-1/rules.d
      install -m 644 data/10-samarinda-actions.rules /etc/polkit-1/rules.d/10-samarinda-actions.rules
    fi
    ;;
  compile|*)
    ensure_libft
    echo "==> Compiling exitsama with pasbuild..."
    if [ "${TARGET}" = "compile" ]; then
      shift 1 || true
    fi
    pasbuild compile "$@"
    ;;
esac
