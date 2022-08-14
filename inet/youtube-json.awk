#!/usr/bin/awk -f

BEGIN {
	print "<!DOCTYPE html> \
<html> \
<head> \
<title> Youtube JSON </title> \
<style> \
html, body { \
color: #e8e6e3; \
border-color: #181a1b; \
background-color: #181a1b; \
} \
.video { \
padding-bottom: 4%; \
padding-top: 4%; \
} \
</style> \
</head> \
<body> \
<h1 style='text-align:center'>Youtube JSON</h1>"
	fs=6;
	cf=0;
	n=1;
}

!/^$/ {
	if (cf < fs) {
		a[cf]=$0;
		cf++;
	}
	else {
		a[cf]=$0;
		cf=0;
		printf "<div class='video'> \
<a href='https://www.youtube.com/watch?v=%s'> \
<img src='file://%s/t%d.jpg'></a> \
<h3>%s - %s</h3> \
<a style='text-decoration=none' href='https://www.youtube.com/%s'> \
<img src='file://%s/c%d.jpg'></a> \
%s - %s - %s \
</div><hr/>", a[0], BASE, n, a[1], a[2], a[3], BASE, n, a[4], a[5], a[6];
		n++;
	}
}

END {
	print "</body></html>"
}
