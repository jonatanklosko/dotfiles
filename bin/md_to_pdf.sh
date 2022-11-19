#!/bin/bash

print_usage_and_exit() {
  echo "Usage: $0 <md-file>"
  exit 1
}

if [ $# -ne 1 ]; then
  print_usage_and_exit
fi

md_file=$1
pdf_file="${md_file%.md}.pdf"

# Navigate to the directory, so that relative paths (e.g. images) work as expected.
cd "$(dirname "$md_file")"

pandoc $md_file -o $pdf_file -V geometry:"top=1.5cm, bottom=1.5cm, left=1cm, right=1cm" -V block-headings -V urlcolor="[HTML]0000ee"
