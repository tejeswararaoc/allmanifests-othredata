
 
#!/bin/bash
 
# Define the path to the .gitleaks.toml file
GITLEAKS_TOML_PATH="D:\gitleaks.toml"
 
# Check if the .gitleaks.toml file exists
if [ ! -f "$GITLEAKS_TOML_PATH" ]; then
 echo ".gitleaks.toml file not found at $GITLEAKS_TOML_PATH. Exiting."
 exit 1
fi
 
# Fetch all branches from the remote
git fetch --all
 
# Get a list of all branches
branches=$(git branch -r | grep -v '\->' | grep -v 'HEAD' | sed 's/origin\///')
 
# Loop through each branch
for branch in $branches; do
 echo "Processing branch: $branch"
 
 # Checkout the branch
 git checkout $branch
 
 # Copy the .gitleaks.toml file to the current branch
 cp "$GITLEAKS_TOML_PATH" ./
 
 # Add the .gitleaks.toml file to the branch
 git add .gitleaks.toml
 
 # Commit the changes if there are any
 if git commit -m "Add .gitleaks.toml for Gitleaks scan"; then
   # Push the changes to the remote branch
   git push origin $branch
   echo ".gitleaks.toml added to branch: $branch"
 else
   echo "No changes to commit in branch: $branch"
 fi
done
 
# Checkout back to the default branch (e.g., main)
git checkout main
