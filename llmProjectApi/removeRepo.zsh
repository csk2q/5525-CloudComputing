#!/usr/bin/env zsh
set -euo pipefail
source .env

# === CONFIGURATION ===
: "${PROJECT_ID:?Environment variable PROJECT_ID not set}"
REPO_NAME="${REPO_NAME:-llm-repo}"       # e.g., 'llm-repo'
REGION="${REGION:-us-central1}"         # e.g., 'us-central1'
REPO_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"
# ======================

echo "Setting GCP project..."
gcloud config set project "$PROJECT_ID"

echo "Fetching list of images in repository '$REPO_NAME'..."
if ! gcloud artifacts docker images list "$REPO_PATH" \
  --format="table[box](package, tags, updateTime)"; then
  echo "Failed to list images. Repository may not exist or is empty."
  exit 1
fi

echo "Do you want to permanently delete the entire repository '$REPO_NAME' in region '$REGION'? Type 'yes' to confirm: "
read confirmation
if [[ "$confirmation" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo "Deleting repository: $REPO_NAME (region: $REGION)..."
gcloud artifacts repositories delete "$REPO_NAME" \
  --location="$REGION" \
  --quiet

echo "Repository '$REPO_NAME' deleted."
