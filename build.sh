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
  compile|*)
    ensure_libft
    echo "==> Compiling exitsama with pasbuild..."
    if [ "${TARGET}" = "compile" ]; then
      shift 1 || true
    fi
    pasbuild compile "$@"
    ;;
esac
