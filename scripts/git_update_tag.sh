#!/bin/bash

VERSION_TYPE=""

# get parameters
while getopts v: flag
do
  case "${flag}" in
    v) VERSION_TYPE=${OPTARG};;
    *) echo "Invalid option: -${OPTARG}" >&2; exit 1;;
  esac
done

# get highest tag number, and add v0.1.0 if it doesn't exist
git fetch --tags --prune --unshallow 2>/dev/null
CURRENT_VERSION=$(git describe --abbrev=0 --tags 2>/dev/null)

if [[ $CURRENT_VERSION == '' ]]
then
  CURRENT_VERSION='v0.1.0'
fi
echo "Current Version: $CURRENT_VERSION"

# Remove the 'v' prefix for versioning
CURRENT_VERSION=${CURRENT_VERSION#v}

# Use mapfile to split version parts more safely
IFS='.' read -r -a CURRENT_VERSION_PARTS <<< "$CURRENT_VERSION"

# get number parts
VNUM1=${CURRENT_VERSION_PARTS[0]}
VNUM2=${CURRENT_VERSION_PARTS[1]}
VNUM3=${CURRENT_VERSION_PARTS[2]}

# increment version number
if [[ $VERSION_TYPE == 'major' ]]
then
  VNUM1=$((VNUM1+1))
  VNUM2=0
  VNUM3=0
elif [[ $VERSION_TYPE == 'minor' ]]
then
  VNUM2=$((VNUM2+1))
  VNUM3=0
elif [[ $VERSION_TYPE == 'patch' ]]
then
  VNUM3=$((VNUM3+1))
else
  echo "No version type (https://semver.org/) or incorrect type specified, try: -v [major, minor, patch]"
  exit 1
fi

# create new tag
NEW_TAG="v$VNUM1.$VNUM2.$VNUM3"
echo "($VERSION_TYPE) updating $CURRENT_VERSION to $NEW_TAG"

# get current hash and see if it already has a tag
GIT_COMMIT=$(git rev-parse HEAD)
NEEDS_TAG=$(git describe --contains "$GIT_COMMIT" 2>/dev/null)

# only tag if no tag already
if [ -z "$NEEDS_TAG" ]; then
  echo "Tagged with $NEW_TAG"
  git tag "$NEW_TAG"
  git push --tags
  git push
else
  echo "Already a tag on this commit"
fi

# Set output using environment file
echo "git-tag=$NEW_TAG" >> $GITHUB_OUTPUT

exit 0