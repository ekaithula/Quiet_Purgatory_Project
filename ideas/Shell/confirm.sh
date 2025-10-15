ls -l ~/.vscode_git_autosync.sh
# should show: -rwxr-xr-x~
cd ~/Documents/Quiet_Purgatory_Project
git branch --show-current           # expect: main
git remote -v                       # origin should be your GitHub URL
git push -u origin main             # only if upstream isn’t set yet