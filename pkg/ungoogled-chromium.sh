#!/usr/bin/sh

FORCE=false
case "$1" in
	'-f'|'--force')
		FORCE=true
		;;
	'-h'|'--help')
		echo "Usage:       ungoogled-chromium [-f|--force]"
		echo "Description: Queries and updates the \`ungoogled-chromium' package"
	exit 1
	;;
esac

DEST_PKG=@UNGOOGLED_CHROMIUM_DEST@
DEST_BIN=@UNGOOGLED_CHROMIUM_BIN@
PKG="/tmp/ungoogled-chromium.appimage"
PKG_ROOT="/tmp/squashfs-root"
CHROMIUM_HOME=@UNGOOGLED_CHROMIUM_HOME@
URL="https://raw.githubusercontent.com/ungoogled-software/ungoogled-chromium-binaries/master/feed.xml"
CURL="/usr/bin/curl"
XML=@UNGOOGLED_CHROMIUM_XML@
LAST_LOCAL_VERSION=$(cat "$CHROMIUM_HOME/Last Version")

echo "[ .. ] Starting update on ungoogled-chromium"

function update {
	read -p "[ ?? ] Proceed to update? [Y/n] " proceed
	if [[ ! "$proceed" ]] || [[ "$proceed" = [Yy] ]]
	then
		echo "[ .. ] Proceeding..."
		return 0
	else
		echo "[ !! ] Cancelling"
		exit 1
	fi
}

function check_update {
	LAST_REMOTE_VERSION=$(echo "$1" | cut -d '/' -f 8)

	if [[ "$LAST_REMOTE_VERSION" =~ "$LAST_LOCAL_VERSION" ]]
	then
		$FORCE || {
			echo "[ !! ] ungoogled-chromium.sh: ungoogled-chromium is up-to-date! (last remote: $LAST_REMOTE_VERSION, last local: $LAST_LOCAL_VERSION) Exiting..."
			exit 1
		}
	else
		echo "[ !! ] Last local version ($LAST_LOCAL_VERSION) mistaches last remote version ($LAST_REMOTE_VERSION)"
	fi
}

echo "[ .. ] Querying feed URL: $URL"
QUERY_URL=$($CURL $URL 2>/dev/null | $XML elements -v | grep -m 1 "feed/entry/link\[@href='.*'\]" | awk "BEGIN { FS = \"'\" } ; { print \$2 }")

echo "[ .. ] Checking if there are any updates available : check_update"
check_update "$QUERY_URL"

echo "[ .. ] Querying AppImage URL: $QUERY_URL"
APPIMAGE_URL=$($CURL $QUERY_URL 2>/dev/null | $XML elements -v | grep -m 1 "html/body/ul/li/a\[@href='.*\.AppImage'\]" | cut -d "'" -f 2)

update
echo "[ .. ] Downloading AppImage: $APPIMAGE_URL"
pushd /tmp
$CURL -L $APPIMAGE_URL >$PKG

echo "[ .. ] Extracting AppImage: $PKG"
chmod +x $PKG
$PKG --appimage-extract
echo "[ .. ] Making libraries : $DEST_PKG/ungoogled-chromium"
pushd $PKG_ROOT/opt/
cp -Truv ungoogled-chromium/ $DEST_PKG || exit 1
popd
echo "[ .. ] Removing $PKG and $PKG_ROOT"
rm $PKG
rm $PKG_ROOT -rf
popd

echo "[ .. ] Making executable script : $DEST_BIN"
cat >$DEST_BIN <<EOF
#!/usr/bin/env bash
XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\$HOME/.config}"
USER_FLAGS_FILE="\$XDG_CONFIG_HOME/browser-flags.conf"
if [[ -f \$USER_FLAGS_FILE ]]; then
   USER_FLAGS="\$(cat \$USER_FLAGS_FILE | sed 's/#.*//')"
fi
exec $DEST_PKG/chrome "\$@" \$USER_FLAGS --password-store=basic
EOF

chmod +x $DEST_BIN

echo "[ OK ] ungoogled-chromium.sh: Done!"

exit 0
