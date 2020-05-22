#!/usr/bin/env sh
set -e

UPSTREAM_REPO=$1
UPSTREAM_BRANCH=$2
LOCAL_BRANCH=$3
TEMP_BRANCH=forksyncbranch

[[ -z ${UPSTREAM_REPO+x} ]] && (echo "Missing \$UPSTREAM_REPO"; exit 1)
[[ -z ${UPSTREAM_BRANCH+x} -o -z ${LOCAL_BRANCH+x} ]] && (echo "Missing \$UPSTREAM_BRANCH:\$LOCAL_BRANCH"; exit 1)

if ! echo $UPSTREAM_REPO | grep '\.git'; then
  UPSTREAM_REPO="https://github.com/${UPSTREAM_REPO}.git"
fi

echo "UPSTREAM_REPO: $UPSTREAM_REPO"
echo "UPSTREAM_BRANCH: $UPSTREAM_BRANCH"
echo "LOCAL_BRANCH: $LOCAL_BRANCH"
echo "TEMP_BRANCH: $TEMP_BRANCH"

# Test if files other than exceptions have changed

## Add $UPSTREAM_REPO as upstream
git remote add upstream "$UPSTREAM_REPO"

for item in $(git diff $LOCAL_BRANCH upstream/${UPSTREAM_BRANCH} --name-only); do
  if [[ $item == ".github/workflows/komodod_cd.yml" || $item == ".github/workflows/komodo_mac_ci.yml" || $item == ".github/workflows/komodo_linux_ci.yml" || $item == ".github/workflows/komodo_win_ci.yml" || $item == ".github/workflows/repo-sync.yml" ]]; then
    echo -e "## No change detected. ##\n"
    exit 0
  fi
done

# Remove extra headers
git config --unset-all http."https://github.com/".extraheader || true

if ! (git remote get-url origin); then
  git remote add origin https://github.com/${GITHUB_REPOSITORY}
fi

# Copy $LOCAL_BRANCH to $TEMP_BRANCH
echo -e "### Testing """
git remote -v
git fetch origin $LOCAL_BRANCH
git checkout -b $TEMP_BRANCH $LOCAL_BRANCH
git checkout $LOCAL_BRANCH

git remote set-url origin "https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY"

# Reset $LOCAL_BRANCH to match $UPSTREAM_REPO
git fetch upstream
git reset --hard upstream/${UPSTREAM_BRANCH}

# Restore files from the local branch
for item in repo-sync.yml komodod_cd.yml komodo_mac_ci.yml komodo_linux_ci.yml komodo_win_ci.yml; do
  git checkout $TEMP_BRANCH .github/workflows/${item}
done

# Commit and push
git config --global user.name "ns408bot"
git config --global user.email "ns408bot@github.com"
git commit -m 'restore files from meshbits workflow files'
git push origin $LOCAL_BRANCH --force

# Clean-up
git branch -D $TEMP_BRANCH
