#!/usr/bin/env bash
set -euo pipefail

SRC="terragrunt-full"
DST="tfc-full"

if [ ! -d "${SRC}" ]; then
  echo "Source directory '${SRC}' not found. Aborting."
  exit 1
fi

if [ -e "${DST}" ]; then
  echo "Destination '${DST}' already exists. Remove or rename it and retry."
  exit 1
fi

echo "Copying '${SRC}' -> '${DST}'..."
cp -a "${SRC}" "${DST}"
echo "Copy complete."

# Create a simple root Terraform Cloud backend placeholder
cat > "${DST}/backend.tf" <<EOF
terraform {
  cloud {
    organization = "ssudevops-org" # 변경 필요
    workspaces {
      name = "migrateTerragrunt" # 변경 필요
    }
  }
}
EOF

echo "Created ${DST}/backend.tf (placeholder). Edit the organization/workspace."

# For each terragrunt.hcl directory create a backend-tfc.tf placeholder to help per-module TFC workspace naming
echo "Generating backend-tfc.tf placeholders next to each terragrunt.hcl..."
find "${DST}" -type f -name 'terragrunt.hcl' | while read -r H; do
  DIR="$(dirname "${H}")"
  RELPATH="$(realpath --relative-to "${DST}" "${DIR}" 2>/dev/null || echo "${DIR}")"
  WS_NAME="$(echo "${RELPATH}" | sed 's#/#-#g' | sed 's/[^a-zA-Z0-9_-]/_/g')"
  cat > "${DIR}/backend-tfc.tf" <<EOF
terraform {
  cloud {
    organization = "ssudevops-org"        # 변경 필요
    workspaces {
      name = "migtestpfx-${WS_NAME}"          # 변경 필요: 추천 규칙/예시
    }
  }
}
EOF
  echo "-> ${DIR}/backend-tfc.tf"
done

echo "Placeholders created. Review all 'backend.tf' / 'backend-tfc.tf' files in '${DST}' and replace placeholders with your Terraform Cloud organization and workspace names."
echo "After edit, init + push to a VCS repo connected to Terraform Cloud (or use Terraform Cloud CLI-driven runs)."
