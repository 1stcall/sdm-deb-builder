#!/usr/bin/env bash
#
# V0.01
#
# deb-builder Run from the bash command line:
#
#    curl -L https://raw.githubusercontent.com/1stcall/sdm-deb-builder/development/deb-builder.sh | bash
#
# $1: Release to install from (D:latest)
# $2: Target install directory (D:/usr/local/sdm)
# $3: Source GitHub repo (D:gitbls/sdm)
# $4: /path/to/local/sdm.tar.xz (D:"")
# $5: /path/to/builddir
# ** To use any of these arguments you must download this script to your system
#    and start it from the command line:
#    e.g., bash$ deb-builder                               # Install latest release to /usr/local/sdm
#          bash$ deb-builder "" /home/$(whoami)/sdm        # Install latest release to /home/$(whoami)/sdm
#
# Any/all required packages are installed via apt

#

#set -Eeuo pipefail
#trap 'error_handler $? $LINENO' ERR

function errexit() {
    echo "$1"
    exit 1
}

function error_handler() {
    errexit "Error: ($1) occurred on line $2"
}

#
# Check OS Distro and version
#
myscript="$0 $@"
[ "$(type -p apt)" == "" ] && errexit "? apt not found; cannot use this script to build sdm.deb on this system"
#
# Create directories and download sdm
#
[ "$1" == "" ] && release="latest" || release="$1"
[ "$5" == "" ] && workdir="$(pwd)/work" || workdir="$5"
[ "$2" != "" ] && dir="$2" || dir="${workdir}/usr/bin"
[ "$3" != "" ] && repo="$3" || repo="gitbls/sdm"
[ "$4" != "" ] && tarball="$4" || tarball=""

ver="13.12"
[ "${release}" == "latest" ] || ver="${release}"

sudo=""
if [ -d $dir ]
then
    [ ! -w $dir ] && sudo="sudo"      # Directory exists; do we have write access?
else
    [ ! -w ${dir%/*} ] && sudo="sudo" # Directory does not exist; do we have write access to where it will be created?
fi

if [ "$(type -p curl)" == "" ]
then
    echo "* Install curl"
    $sudo apt-get install --yes --no-install-recommends curl
fi

echo "* Make sdm install directory '$dir'"
$sudo mkdir -p $workdir/usr/share/{1piboot,plugins,local-plugins}
$sudo mkdir -p $workdir/DEBIAN
$sudo mkdir -p $dir

v="--verbose" # list files as they're extracted
if [ "$tarball" == "" ]
then
    src="https://github.com/$repo/releases/$release/download/sdm.tar.xz"
    echo "* Download sdm tarball from '$src' and install in '$dir'"
    curl --fail --silent --show-error -L $src | $sudo tar --extract --xz $v --file - --overwrite -C $dir   # || errexit "? Error ($?) downloading/untarring the sdm tarball"
else
    echo "* Extracting sdm from tarball '$tarball' to '$dir'"
    $sudo tar --extract --xz $v --file $tarball --overwrite -C $dir || errexit "? Error ($?) untarring sdm tarball '$tarball'"
fi
etc="${workdir}/etc"
#if [ "$dir" == "/usr/local/sdm" ]
#then
#    echo "* Create link for sdm: /usr/local/bin/sdm"
#    [ -L /usr/local/bin/sdm ] && $sudo rm -f /usr/local/bin/sdm
#    $sudo ln -s /usr/local/sdm/sdm /usr/local/bin/sdm
#fi

$sudo mkdir -p $v $etc/sdm/
$sudo rm -f $v $etc/sdm/sdm-readparams
$sudo cp -a $v $dir/sdm-readparams $etc/sdm

cat <<EOF | $sudo tee "${workdir}/DEBIAN/control" >/dev/null
Package: sdm
Version: $ver
Section: utils
Priority: optional
Architecture: all
Maintainer: gitbls <gitbls@outlook.com>
Depends: binfmt-support,gdisk,keyboard-configuration,parted,qemu-user-static,rsync,systemd-container,uuid,python3
Description: Raspberry Pi SSD/SD Card Image Manager
 sdm provides a quick and easy way to build consistent, ready-to-go SSDs and/or
 SD cards for the Raspberry Pi.  This command line management tool is especially 
 useful if you:
 .
    have multiple Raspberry Pi systems and you want them all to start from an 
    identical and consistent set of installed software packages, configuration
    scripts and settings, etc.
 .
    want to rebuild your Pi system in a consistent manner with all your favorite
    packages and customizations already installed. Every time.
 .
    want to be nice to your future self and make it super-easy to build fresh, 
    customized systems when that next release of RasPiOS comes out.
 .
    want to do the above repeatedly and a LOT more quickly and easily.
 .
    What does ready-to-go mean? It means that every one of your systems is fully
    configured with Keyboard mapping, Locale, Timezone, and WiFi set up as you
    want, all of your personal customizations and all desired RasPiOS packages
    and updates installed.
 .
 In other words, all ready to work on your next project.
 .
 With sdm you'll spend a lot less time rebuilding SSDs/SD Cards, configuring 
 your system, and installing packages, and more time on the things you really
 want to do with your Pi.
 .
 Have questions about sdm? Please don't hesitate to ask in the Issues section of 
 this github.  If you don't have a github account (so can't post an 
 issue/question here), please feel free to email me at: gitbls@outlook.com.
 .
 If you find sdm useful, please consider starring it to help me understand how
 many people are using it. Thanks!

EOF

#curl -L https://raw.githubusercontent.com/gitbls/sdm/master/CHANGELOG.md | $sudo tee ${workdir}/changelog >/dev/null
cat ./temp/changelog.Debian | $sudo tee ${workdir}/changelog #>/dev/null
$sudo gzip --best -n ${workdir}/changelog
$sudo mkdir -p $v ${workdir}/usr/share/doc/sdm/
$sudo mkdir -p $v ${workdir}/usr/share/sdm/
$sudo mv $v ${workdir}/changelog.gz ${workdir}/usr/share/doc/sdm/
$sudo mv $v ${workdir}/usr/bin/{1piboot,plugins} ${workdir}/usr/share/sdm/

cat <<EOF2 | $sudo tee ${workdir}//DEBIAN/conffiles >/dev/null
/etc/sdm/sdm-readparams
EOF2

cat <<EOF3 | $sudo tee ${workdir}/usr/share/doc/sdm/copyright >/dev/null
MIT License

Copyright (c) 2021-2025 gitbls

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
EOF3

cat <<EOF4 | $sudo tee ${workdir}//DEBIAN/postinst >/dev/null
#!/usr/bin/bash
set -e
chmod 755 $dir/*
chmod 644 $dir/{sdm-apps-example,sdm-xapps-example} /usr/share/sdm/1piboot/1piboot.conf
mkdir -p /etc/sdm/{0piboot,1piboot,xpiboot,assets,local-assets}
EOF4

$sudo chmod 555 ${workdir}//DEBIAN/postinst
$sudo chown -R $(whoami):$(whoami) ${workdir}//DEBIAN/postinst

dpkg-deb --root-owner-group --build work sdm.deb || errexit "? dpkg-deb failed"
lintian --tag-display-limit 0 sdm.deb
