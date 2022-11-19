#!/bin/bash

print_usage_and_exit() {
  echo "Usage: $0 <path>"
  echo ""
  echo "Changes filenames in <path> from dashes to underscores"
  exit 1
}

if [ $# -ne 1 ]; then
  print_usage_and_exit
fi

dir=$1

for file in $dir/*; do
  new_file="${file//-/_}"
  if ! [ "$file" = "$new_file" ]; then
    echo "$file -> $new_file"
    mv $file $new_file
  fi
done
