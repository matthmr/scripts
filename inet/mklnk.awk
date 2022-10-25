#!/usr/bin/awk -f

BEGIN {
  if (x == 1) {
    LINES=6;
  }
  else if (x == 2) {
    LINES=2;
  }
  lines=0;
  n=1;
  entry="";
}

!/^[ 	]*$/ {
  if (lines == LINES) {
    printf("%d %s\n", n, entry);
    entry="";
    lines = 0;
    n++;
  }
  entry=entry " " $0;
  lines++;
}
