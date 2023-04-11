#!/usr/bin/env bash
# author: jtt9340 (https://github.com/jtt9340)
#
# test negative ignore update
# returns 1 in case of error
#

## start-cookie
set -e
cur=$(cd "$(dirname "${0}")" && pwd)
ddpath="${cur}/../"
export PYTHONPATH="${ddpath}:${PYTHONPATH}"
altbin="python3 -m dotdrop.dotdrop"
if hash coverage 2>/dev/null; then
  altbin="coverage run -p --source=dotdrop -m dotdrop.dotdrop"
fi
bin="${DT_BIN:-${altbin}}"
# shellcheck source=tests-ng/helpers
source "${cur}"/helpers
echo -e "$(tput setaf 6)==> RUNNING $(basename "${BASH_SOURCE[0]}") <==$(tput sgr0)"
## end-cookie

################################################################
# this is the test
################################################################

# $1 pattern
# $2 path
grep_or_fail()
{
  grep "${1}" "${2}" >/dev/null 2>&1 || (echo "pattern not found in ${2}" && exit 1)
}

# dotdrop directory
basedir=$(mktemp -d --suffix='-dotdrop-tests' 2>/dev/null || mktemp -d)
echo "[+] dotdrop dir: ${basedir}"
echo "[+] dotpath dir: ${basedir}/dotfiles"
mkdir -p "${basedir}"/dotfiles/a/{b,c}
echo 'a' > "${basedir}"/dotfiles/a/b/abfile1
echo 'a' > "${basedir}"/dotfiles/a/b/abfile2
echo 'a' > "${basedir}"/dotfiles/a/b/abfile3
echo 'a' > "${basedir}"/dotfiles/a/c/acfile

# the dotfile to be updated
tmpd=$(mktemp -d --suffix='-dotdrop-tests' 2>/dev/null || mktemp -d)

clear_on_exit "${basedir}"
clear_on_exit "${tmpd}"

cp -r "${basedir}"/dotfiles/a "${tmpd}"/

# create the config file
cfg="${basedir}/config.yaml"
cat > "${cfg}" << _EOF
config:
  backup: false
  create: true
  dotpath: dotfiles
dotfiles:
  f_abc:
    dst: ${tmpd}/a
    src: a
    upignore:
    - "*/newdir/b/*"
    - "!*/newdir/b/d"
    - "*/abfile?"
    - "!*/abfile3"
profiles:
  p1:
    dotfiles:
    - f_abc
_EOF

# edit/add files
echo "[+] edit/add files"
mkdir -p "${tmpd}"/a/newdir/b
echo 'b' > "${tmpd}"/a/b/abfile1
echo 'b' > "${tmpd}"/a/b/abfile2
echo 'b' > "${tmpd}"/a/b/abfile3
echo 'b' > "${tmpd}"/a/b/abfile4
touch "${tmpd}"/a/newdir/b/{c,d}

# update
echo "[+] update"
cd "${ddpath}" | ${bin} update -f -c "${cfg}" --verbose --profile=p1 --key f_abc

# check files haven't been updated
grep_or_fail a "${basedir}"/dotfiles/a/b/abfile1
grep_or_fail a "${basedir}"/dotfiles/a/b/abfile2
grep_or_fail b "${basedir}"/dotfiles/a/b/abfile3
[ -e "${basedir}"/dotfiles/a/b/abfile4 ] && echo "abfile4 should not have been updated" && exit 1
[ -e "${basedir}"/dotfiles/a/newdir/b/c ] && echo "newdir/b/c should not have been updated" && exit 1
[ ! -e "${basedir}"/dotfiles/a/newdir/b/d ] && echo "newdir/b/d should have been updated" && exit 1

echo "OK"
exit 0
