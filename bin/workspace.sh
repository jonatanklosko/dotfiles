#!/bin/bash

print_usage_and_exit() {
  echo "Usage: $0 <command>"
  echo ""
  echo "Available commands:"
  echo ""
  echo "  workspace link      Adds a .workspace symbolic link pointing to a workspace directory with the same name as the current directory"
  echo "  workspace unlink    Removes the workspace link (keeps the workspace intact)"
  echo ""
  exit 1
}

if [ $# -ne 1 ]; then
  print_usage_and_exit
fi

link_name=".workspace"
workspaces_dir="$HOME/workspace"

dir_name="$(basename "$(pwd)")"
workspace_dir="$workspaces_dir/$dir_name"

case "$1" in
  "link")
    mkdir -p "$workspace_dir"
    ln -s "$workspace_dir" "$link_name"
  ;;

  "unlink")
    unlink "$link_name"
  ;;

  *)
    print_usage_and_exit
  ;;
esac
