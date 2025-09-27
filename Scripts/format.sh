#!/bin/zsh
if command -v swiftformat >/dev/null 2>&1; then
  swiftformat .
else
  echo "swiftformat not installed. Install with: brew install swiftformat"
fi


