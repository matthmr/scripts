#!/usr/bin/awk -f

BEGIN {
	fs=5;
	cf=0;
}

!/^$/ {
	if (cf < fs) {
		a[cf]=$0;
		cf++;
	}
	else {
		a[cf]=$0;
		cf=0;
		printf "\n%s -- %s\n%s -- %s -- %s\n\
https://www.youtube.com/watch?v=%s\n\n---\n", a[1], a[2], a[3], a[4], a[5], a[0];
	}
}
