#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
cd "$REPO_ROOT"
env_name=${1:?}; image=${2:?}; digest=${3:?}; version=${4:?}
[[ "$env_name" == dev || "$env_name" == stage ]] || exit 2
: "${GITOPS_URL:?}" "${SYSTEM_ACCESSTOKEN:?}" "${BUILD_BUILDID:?}"
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=http.extraheader
export GIT_CONFIG_VALUE_0="AUTHORIZATION: bearer $SYSTEM_ACCESSTOKEN"
work="$REPO_ROOT/out/release-$BUILD_BUILDID-$env_name"
git clone --branch main "$GITOPS_URL" "$work"
branch="release/$env_name-$BUILD_BUILDID"
git -C "$work" switch -c "$branch"
python scripts/gitops_update.py update --repo "$work" --env "$env_name" --image "$image" --digest "$digest" --version "$version"
git -C "$work" add "helm/sample-application/values-$env_name.yaml"
git -C "$work" -c user.name='Platform Pipeline' -c user.email='pipeline@localhost' commit -m "Release $version to $env_name"
git -C "$work" push origin "$branch"
GITOPS_BRANCH="$branch" python scripts/create-gitops-pr.py
