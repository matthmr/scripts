#!/usr/bin/awk -f

BEGIN { FS=":" }

/^([0-9]+:|>> 0:) <[^mcQ]/ {
	line=""
	split($2, splitter, "/")
	lim=length(splitter)
	for (i = 0; i < lim; i++) {
		sub(/^([ \n]*<|.*<)/, "", splitter[i])
		line=(line splitter[i])
	}
	print line
}
