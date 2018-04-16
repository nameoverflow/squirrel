#!/bin/bash
get_app_version() {
    sed -n '/CFBundleVersion/{n;s/.*<string>\(.*\)<\/string>.*/\1/;p;}' $@
}
HASH=$(git rev-parse HEAD)
REPO_HOME="https://${GH_TOKEN}@github.com/nameoverflow/home.git"

app_version=$(get_app_version "Info.plist")
arichive="package/archives/Squirrel-${app_version}.zip"
target_archive="package/archives/Squirrel-${app_version}-${HASH}.zip"

mv $arichive $target_archive

file_length=$(stat -f%z "${target_archive}")

cd package/sign
ruby generate_keys.rb > /dev/null 2>&1
dsa_signature=$(ruby sign_update.rb "${target_archive}" dsa_priv.pem)
cd ../..

echo "cloning"
git clone $REPO_HOME pages > /dev/null 2>&1

echo "cloned"

cd pages/blog/source

yes | cp -rf squirrel.appcast.xml.template testing/squirrel/appcast.xml
app_cast_file="testing/squirrel/appcast.xml"
date_time=$(date -R)

sed -i "" 's/{{TYPE}}/測試/g' $app_cast_file
sed -i "" 's/{{PATH}}/testing/g' $app_cast_file
sed -i "" "s/{{VERSION}}/${app_version}-${HASH}/g" $app_cast_file
sed -i "" "s/{{TIME}}/${date_time}/g" $app_cast_file
sed -i "" "s/{{SIZE}}/${file_length}/g" $app_cast_file
sed -i "" "s|{{SIGN}}|${dsa_signature}|g" $app_cast_file

echo "appcast generated"
cd ../../

git config user.name "Travis CI"
git config user.email "$COMMIT_AUTHOR_EMAIL"
if git diff --quiet; then
    echo "No changes to the output on this push; exiting."
    exit 0
fi
git add -A .
git commit -m "Deploy to GitHub Pages: ${HASH}"

echo "committed"

git push --quiet

echo "pushed"

cd ..


sed -i '.bak' 's/git-commit-hash/'"$HASH"'/g' travis-deploy-package.json
