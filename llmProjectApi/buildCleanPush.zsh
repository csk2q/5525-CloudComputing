#!/usr/bin/env zsh
set -euo pipefail
source .env

# === CONFIGURATION ===
: "${PROJECT_ID:?Environment variable PROJECT_ID not set}"
: "${IMAGE_NAME:?Environment variable IMAGE_NAME not set}"
: "${REPO_NAME:?Environment variable REPO_NAME not set}"
: "${REGION:?Environment variable REGION not set}"

VERSION_TAG="${TAG:-$(date +%Y%m%d-%H%M%S)}"
AR_IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"
KEEP_RECENT=${KEEP_RECENT:-5}
# ======================

echo "Setting GCP project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

echo "Authenticating Docker with Artifact Registry: ${REGION}-docker.pkg.dev"
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "Ensuring Artifact Registry repo '${REPO_NAME}' exists in region '${REGION}'..."
if ! gcloud artifacts repositories describe "${REPO_NAME}" --location="${REGION}" &>/dev/null; then
  gcloud artifacts repositories create "${REPO_NAME}" \
    --repository-format=docker \
    --location="${REGION}" \
    --description="Docker repository for LLM project"
fi

echo "Building Docker image: ${IMAGE_NAME}:${VERSION_TAG}"
docker build -t "${IMAGE_NAME}:${VERSION_TAG}" .

echo "Tagging image as:"
echo " - ${AR_IMAGE}:${VERSION_TAG}"
echo " - ${AR_IMAGE}:latest"
docker tag "${IMAGE_NAME}:${VERSION_TAG}" "${AR_IMAGE}:${VERSION_TAG}"
docker tag "${IMAGE_NAME}:${VERSION_TAG}" "${AR_IMAGE}:latest"

echo "Pushing both tags to Artifact Registry..."
docker push "${AR_IMAGE}:${VERSION_TAG}"
docker push "${AR_IMAGE}:latest"

echo "Fetching all image tags (excluding 'latest') sorted by create time..."
image_path="${AR_IMAGE}"
echo "Image path: ${image_path}"

all_tags=("${(@f)$(gcloud artifacts docker images list "${image_path}" \
  --format="value(tags)" \
  --sort-by=~CREATE_TIME \
  --limit=9999 | grep -Ev '(^$|latest)')}")

total=${#all_tags[@]}
echo "Found $total tagged image(s) (excluding 'latest')"

if (( total <= KEEP_RECENT )); then
  echo "Number of tags ($total) is less than or equal to KEEP_RECENT ($KEEP_RECENT). No deletions necessary."
else
  delete_count=$((total - KEEP_RECENT))
  echo "Deleting $delete_count oldest image tag(s)..."

  for (( i = KEEP_RECENT + 1; i <= total; i++ )); do
    tag="${all_tags[i]}"
    if [[ -n "$tag" ]]; then
      echo "Deleting ${AR_IMAGE}:${tag}"
      gcloud artifacts docker images delete "${AR_IMAGE}:${tag}" --quiet
    else
      echo "Skipping empty or invalid tag at index $i"
    fi
  done
fi

echo "✅ Done. Image pushed:"
echo " - ${AR_IMAGE}:${VERSION_TAG}"
echo " - ${AR_IMAGE}:latest"
