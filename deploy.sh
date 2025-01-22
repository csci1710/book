cd book
mdbook build
git worktree add deployed-pages
git config user.name "Deploy from CI" 
git config user.email ""
cd deployed-pages 
# Delete the ref to avoid keeping history.
git update-ref -d refs/heads/deployed-pages
rm -rf *
mv ../book/* .
git add .
git commit -m "Deploy $GITHUB_SHA to deployed-pages"
git push --force --set-upstream origin deployed-pages
