case $1 in
  '--help'|'-h')
    echo "Usage:       git-index.sh [OPTIONS]"
    echo "Description: Writes the tree of the index into a proper object"
    echo "Options:
  -w: write
  -r: read" ;;
  '-w')
    ref=$(git write-tree)
    echo "[ .. ] Writing $ref" 1>&2
    echo $ref > /tmp/.gitidx ;;
  '-r')
    cat /tmp/.gitidx 2>/dev/null ;;
esac
