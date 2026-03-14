#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK not found. Please install Flutter first."
  exit 1
fi

# Create missing platform folders/config files without overwriting lib/.
flutter create . --project-name babycare_flutter --org com.babycare.app
flutter pub get

echo "Bootstrap complete."
