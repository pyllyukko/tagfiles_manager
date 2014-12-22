#!/bin/bash
################################################################################
# file:		tagfiles_manager.sh
# created:	29-09-2010
#
# the purpose of this script is to be able to produce more minimal slackware
# installations without all the multimedia libraries or server software
#
# to make a more customized installation that is
# ...without the need to handpick every single package.
#
# more information about tagfiles:
#   - http://www.slackware.com/install/setup.php
#   - http://www.slackbook.org/html/package-management-making-tags-and-tagfiles.html
#   - http://www.slackwiki.org/Tagfile_Install
#   - http://connie.slackware.com/~vbatts/minimal/
#   - http://www.microlinux.fr/slackware/tagfiles/
#   - https://github.com/chrisjs/slackware-13.34-tagfiles
#
# TODO:
#   - a switch to make use of maketags
#   * grep the required packages from maketag, for bare minimum installation
#   * copy the original to .original, so we can reference it later
#     * parameter to "reset" to original values
#   - check md5 of the original
#   * comma separated list as parameter
#     -> list supplied within quotes to each parameter
#   * only one function... not enable disable
#   - !!! if no categories specified to (at least) OPT & REC, disable from all categories !!!
#     - make keyword 'all' work in all functions
#   - rename to tagfiles bakery=)
#   - add a check_subcategory_packages_from_actual_categories() function
#     so we see if some subcaterory's packages are for instace REC in some category
#   - function to print a chart about current and original states
#   - verification that we enabled/disabled the right amount of packages,
#     simple grep -c from .original should do?
#   - sendmail & procmail might be required by cron?
#   - support downloading/using tagfiles from http://www.microlinux.fr/slackware/tagfiles/public-server/
#
################################################################################
[ ${BASH_VERSINFO[0]} -ne 4 ] && {
  echo -e "error: bash version != 4, this script might not work properly!" 1>&2
  echo    "       you can bypass this check by commenting out lines $[${LINENO}-2]-$[${LINENO}+2]." 1>&2
  exit 1
}
[ ${BASH_VERSINFO[0]} -eq 4 ] && shopt -s compat31
################################################################################
declare -r TAGFILES_DIR="/home/pyllyukko/work/slackware/tagfiles/14.1/tagfiles"
declare    SLACKWARE_DIR="/mnt/slackware/slackware"

# for x86:
#declare -r SLACKWARE_VERSION="slackware-14.1"
#declare -r FTP="ftp://ftp.slackware.com/pub/slackware/${SLACKWARE_VERSION}/slackware/"

# for x86_64:
declare -r SLACKWARE_VERSION="slackware64-14.1"
declare -r FTP="ftp://ftp.slackware.com/pub/slackware/${SLACKWARE_VERSION}/slackware64/"

# -A option declares associative array.
declare -A CAT_DESC=(
  ["a"]="The base system"
  ["ap"]="Various applications that do not require the X Window System"
  ["d"]="Program development tools"
  ["e"]="GNU Emacs"
  ["f"]="FAQs, HOWTOs, and other miscellaneous documentation"
  ["gnome"]="The GNOME desktop environment"
  ["k"]="The source code for the Linux kernel"
  ["kde"]="The K Desktop Environment"
  ["kdei"]="Language support for the K Desktop Environment"
  ["l"]="System libraries"
  ["n"]="Networking programs"
  ["t"]="teTeX document formatting system"
  ["tcl"]="The Tool Command Language"
  ["x"]="The base X Window System"
  ["xap"]="X applications"
  ["xfce"]="Xfce Desktop Environment"
  ["y"]="Games"
)
################################################################################

# here are some "subcategories" i defined

# 30.4.2011: added tcp_wrappers
# 19.6.2011: added icmpinfo
# 11.9.2011: added ca-certificates
networking_PACKAGES=(
  network-scripts
  net-tools
  iptables
  wget
  rsync
  openssl
  curl
  tcpdump
  openldap-client
  mailx
  procmail
  iputils
  biff+comsat
  iproute2
  ntp
  gnutls
  tcp_wrappers
  icmpinfo
  ca-certificates
  dhcpcd
)
ipv6_PACKAGES=(
  p11-kit
  nettle
)
# 30.4.2011: added cpio (to be used with mkinitrd)
# 13.6.2011: added utempter (required at least by screen, but probably
#            many others too)
# 16.6.2011: added lvm2 & kernel-generic-smp
# 29.7.2011: added acct (process accounting)
# 30.7.2011: added sysvinit-functions & sysstat
# 27.9.2011: TODO: lsof?
# 23.10.2011: added lm_sensors
# 12.10.2012: added gettext (do we need gettext-tools too?)
# 21.10.2012: added mcelog
# 27.3.2013: added hdparm
#
# TODO:
#   - gnupg2
#     - libassuan
essential_PACKAGES=(
  glibc-solibs
  kernel-huge-smp
  kernel-generic-smp
  lilo
  udev
  aaa_terminfo
  kbd
  man
  groff
  findutils
  sysklogd
  gnupg
  cyrus-sasl
  dialog
  which
  gawk
  ncurses
  vim
  slackpkg
  bzip2
  logrotate
  diffutils
  sqlite
  file
  man-pages
  sysstat
  mdadm
  cryptsetup
  mkinitrd
  cpio
  utempter
  lvm2
  acct
  sysstat
  sysvinit-functions
  lm_sensors
  gettext
  mcelog
  hdparm
  sudo
  lsof
  genpower
  bc
  ${networking_PACKAGES[*]}
)

if [ "${SLACKWARE_VERSION:0:11}" = "slackware64" ]
then
  # TODO: libx86?
  echo "adding few packages for the x86_64 arch..."
  essential_PACKAGES+=(kernel-generic kernel-huge)
fi

# 29.4.2011: added libmpc
# 15.5.2011: added libpcap
# 21.5.2011: added libnl, at least tcpdump requires this
# 11.6.2011: added pcre, db44 & neon (neon required by svn)
# 12.10.2012: added apr & apr-util, required at least by svn
# 20.10.2012: gd is required by apcupsd
libs_PACKAGES=(
  mpfr
  glibc
  libxml2
  libxslt
  zlib
  glib2
  libidn
  readline
  libgcrypt
  libgpg-error
  loudmouth
  mhash
  expat
  libmpc
  libpcap
  libnl
  pcre
  db44
  neon
  apr
  apr-util
  libnl3
  db48
  libyaml
  libarchive
  nettle
  lzo
)
# bison is required (at least) by aide
# flex is required (at least) by aide
# perl & python is needed by vim(!) on slack14.0
#
#
# 11.6.2011: added subversion
# 19.6.2011: added ruby
# 22.12.2011: added swig (required by audit)
# 12.10.2012: removed guile. not sure if it's necessary.
dev_PACKAGES=(
  patch
  make
  cmake
  gcc
  binutils
  kernel-headers
  git
  autoconf
  perl
  automake
  m4
  libtool
  pkg-config
  python
  'gcc-g++'
  strace
  bison
  flex
  #guile
  subversion
  ruby
  swig
  ${libs_PACKAGES[*]}
)
bluetooth_PACKAGES=(
  blueman
  bluez
  bluez-firmware
  bluez-hcidump
)
# TODO: other sound libraries, players and stuff...
alsa_PACKAGES=(
  alsa-lib
  alsa-oss
  alsa-utils
)
# this should be quite complete set (at least in slackware 13.1)
# 29.4.2011: added iwlwifi-100-ucode & iwlwifi-6xxx-ucode from 13.37
# 9.7.2012: added wicd
# 6.10.2012: added kernel-firmware (slack14.0)
wireless_PACKAGES=(
  wireless-tools
  rt2860-firmware
  rt2870-firmware
  rt61-firmware
  rt71w-firmware
  zd1211-firmware
  ipw2100-fw
  ipw2200-fw
  iwlwifi-1000-ucode
  iwlwifi-3945-ucode
  iwlwifi-4965-ucode
  iwlwifi-5000-ucode
  iwlwifi-5150-ucode
  iwlwifi-6000-ucode
  iwlwifi-100-ucode
  iwlwifi-6xxx-ucode
  iw
  wpa_supplicant
  wicd
  kernel-firmware
)
# php might need alpine... at least it is in .SlackBuild
# ...might also require gdbm, enchant, libjpeg, libpng, libXpm, libX11, lesstif(?), libxcb libXau libXdmcp, freetype, t1lib, gmp, aspell, mm, net-snmp(!!!)
apache_PACKAGES=(
  httpd
  php
  apr-util
  apr
  php
  libmcrypt
)
# most of the packages containing an rc script and a few others
server_PACKAGES=(
  sendmail
  sendmail-cf
  dnsmasq
  inetd
  nfs-utils
  portmap
  mysql
  httpd
  samba
  net-snmp
  cups
  yptools
  cyrus-sasl
  netatalk
  imapd
  netkit-rsh
  netkit-timed
  openssh
  pidentd
  popa3d
  proftpd
  telnet
  vsftpd
)
obex_PACKAGES=(
  obex-data-server
  obexfs
  obexftp
  openobex
)
# UNDER CONSTRUCTION!
#
# Qt                (a multi-platform C++ graphical user interface toolkit)
# PyQt              (Python bindings for Qt)
# qtscriptgenerator (Qt API Bindings for QtScript)
# QScintilla        (Qt port of the Scintilla C++ editor control)
# attica            (Qt Collaboration library)
# automoc4          (automatic moc for Qt4)
# qca               (Qt Cryptographic Architecture)
# qca-cyrus-sasl    (Cyrus SASL plugin for QCA)
# qca-gnupg         (GnuPG plugin for QCA)
# qca-ossl          (OpenSSL plugin for QCA)
# soprano           (C++/Qt4 framework for RDF data)
QT_PACKAGES=(
  qt
  PyQt
  qtscriptgenerator
  QScintilla
  attica
  automoc4
  qca
  qca-cyrus-sasl
  qca-gnupg
  qca-ossl
  soprano
)
# UNDER CONSTRUCTION!
#
# svgalib (A low level graphics library for Linux)
# libcaca (Colour AsCii Art library)
# aalib   (ASCII Art library)
GRAPHICS_PACKAGES=(
  gnome-icon-theme
  hicolor-icon-theme
  tango-icon-theme
  tango-icon-theme-extras
  icon-naming-utils
  svgalib
  aalib
  libcaca
  cairo
  exiv2
  gd
  gegl
  giflib
  glib
  glib2
  gtk+
  gtk+2
  gtkspell
  imlib
  libart_lgpl
  libexif
  libgphoto2
  libjpeg
  libmng
  libpng
  librsvg
  libtheora
  libtiff
  libwmf
  libwmf-docs
  netpbm
  openexr
  phonon
  pygtk
  qimageblitz
  v4l-utils
)
SOUND_PACKAGES=(
  audiofile
  esound
  gst-plugins-base
  gst-plugins-good
  gstreamer
  libao
  libcddb
  libdiscid
  libgpod
  libid3tag
  libkarma
  liblastfm
  libmad
  libogg
  libsamplerate
  libvisual
  libvisual-plugins
  libvorbis
  sdl
  taglib
  taglib-extras
  wavpack
)
# TODO: printing, other audio
peripherals_PACKAGES=(
  pilot-link
)
################################################################################
function verify_tagfile_checksums() {
  # $1 = category
  # UNDER CONSTRUCTION!
  # TODO: should we verify the CHECKSUMS.md5 with gpg?-)
  local    CHECKSUMS_FILE="${SLACKWARE_DIR}/CHECKSUMS.md5"
  local -a CHECKSUMS=()
  [ ! -f "${CHECKSUMS_FILE}" ] && {
    echo "${FUNCNAME}(): error: checksums file does not exist!" 1>&2
    return 1
  }
  CHECKSUMS[${#CHECKSUMS[*]}]=`awk '/\/'"${1}"'\/tagfile$/{print$1}' "${CHECKSUMS_FILE}"`

  #[ ${#CHECKSUMS[*]} -ne 2 -o \
  #  ${#CHECKSUMS[0]} -ne 32 -o \
  #  ${#CHECKSUMS[1]} -ne 32 ] && {
  #  ############################################################################
  #  # NOTE: OF COURSE THIS SHOULD NEVER HAPPEN!                                #
  #  ############################################################################
  #  echo "${FUNCNAME}(): error!" 1>&2
  #  return 1
  #}

  echo "${FUNCNAME}(): DEBUG: the checksum should be ${CHECKSUMS[0]}"
  return 0
} # verify_tagfile_checksums()
################################################################################
function copy_tagfiles() {
  local -a DIRS
  local    DIR
  local    CATEGORY
  [ ! -f "${1}/FILE_LIST" -o \
    ! -f "${1}/MANIFEST.bz2" -o \
    ! -f "${1}/a/tagfile" ] && {
    echo "${FUNCNAME}(): error: not a proper slackware directory!" 1>&2
    return 1
  }
  DIRS=(`find "${1}" \( ! -wholename "${1}" -a -type d \) -maxdepth 1`)

  for DIR in ${DIRS[*]}
  do
    CATEGORY="${DIR##*/}"
    echo "${FUNCNAME}: DEBUG: CATEGORY=${CATEGORY} DIR=${DIR}"

    verify_tagfile_checksums "${CATEGORY}"

    mkdir -p -v "${TAGFILES_DIR}/${CATEGORY}" || {
      echo "${FUNCNAME}(): error: couldn't create directory \`${TAGFILES_DIR}/${CATEGORY}'!" 1>&2
      return 1
    }
    cp -v "${DIR}/tagfile" "${TAGFILES_DIR}/${CATEGORY}"
    cp -v "${DIR}/tagfile" "${TAGFILES_DIR}/${CATEGORY}/tagfile.original"
    cp -v "${DIR}/maketag"* "${TAGFILES_DIR}/${CATEGORY}"
  done

  return 0
} # copy_tagfiles()
################################################################################
function get_tagfiles_from_net() {
  [ ! -d "${TAGFILES_DIR}" ] && mkdir -p -v "${TAGFILES_DIR}"
  pushd "${TAGFILES_DIR}" || return 1
  [ ! -f ".listing" ] && wget -nv --no-remove-listing "${FTP}"
  local -a CATEGORIES=(`awk '/^d.+[a-z]\r$/{sub(/\r$/, "", $9);print$9}' .listing`)
  local    CATEGORY
  local -a FILES=(maketag maketag.ez tagfile)
  local    FILE
  for CATEGORY in ${CATEGORIES[*]}
  do
    #pushd "${CATEGORY}"
    #echo "${FUNCNAME}(): category=${CATEGORY}"
    for FILE in ${FILES[*]}
    do
      wget -nv -P "${CATEGORY}" "${FTP}/${CATEGORY}/${FILE}"
      [ "${FILE}" = "tagfile" ] && cp -v "${CATEGORY}/${FILE}" "${CATEGORY}/${FILE}.original"
    done
    #echo "${FILES[*]/#/CATEGORY}"
    #popd
  done
  popd
  return 0
} # get_tagfiles_from_net()
################################################################################
function remove_tagfiles() {
  # DANGEROUS!!!
  [ ! -d "${1}" ] && {
    echo "${FUNCNAME}(): error!" 1>&2
    return 1
  }
  local -a DIRS=(`find "${1}" -type d -mindepth 1 -maxdepth 1`)
  local    DIR

  [ ${#DIRS[*]} -eq 0 ] && {
    echo "${FUNCNAME}(): error: no tagfile directories found!" 1>&2
    return 1
  }

  # print out the directories for the user
  echo "${FUNCNAME}(): this will remove the following directories:"
  for DIR in ${DIRS[*]}
  do
    echo "  ${DIR}"
  done
  echo -n $'\n'

  # prompt the user
  until [ "x${REPLY}" = "xy" -o "x${REPLY}" = "xn" ]
  do
    read -p "are you sure? y/n: " -n 1 REPLY
    case "${REPLY}" in
      "y")
        # go ahead and delete
        echo "es"
        for DIR in ${DIRS[*]}
        do
  	  rm -frv "${DIR}"
        done
      ;;
      "n") echo "o"      ;;
      *)   echo -n $'\n' ;;
    esac
  done
  unset -v REPLY

  return 0
} # remove_tagfiles()
################################################################################
function copy_tagfiles_to_destination() {
  # TODO: obsolete?
  # $1 = src dir
  # $2 = dst dir
  local -a DIRS=(`find "${1}" -type d -mindepth 1 -maxdepth 1`)
  local CATEGORY
  local DIRECTORY

  if [ ! -d "${1}" ]
  then
    echo "${FUNCNAME}(): error: source directory \`${1}' does not exist!" 1>&2
    return 1
  elif [ ! -d "${2}" ]
  then
    echo "${FUNCNAME}(): error: destination directory \`${1}' does not exist!" 1>&2
    return 1
  fi

  # create the directory if it doesn't exist
  mkdir -pv "${2}/tagfiles"
  for DIRECTORY in ${DIRS[*]}
  do
    CATEGORY="${DIRECTORY##*/}"
    #echo "${FUNCNAME}(): DEBUG: DIRECTORY=${DIRECTORY} CATEGORY=${CATEGORY}"
    [ ! -f "${CATEGORY}/tagfile" ] && {
      echo "error: tagfile \`${CATEGORY}/tagfile' does not exist!" 1>&2
      continue
    }
    #echo "${CATEGORY}"
    #sed -i 's/\(^.\+\):[A-Z]\+/\1:SKP/' "${CATEGORY}/tagfile"
    cp -R -v "${CATEGORY}" "${DEST}/tagfiles"
  done

  return 0
} # copy_tagfiles_to_destination()
################################################################################
function grep_all_statuses() {
  [ "${#}" -ne 1 -o ! -d "${1}" ] && {
    echo "${FUNCNAME}(): ERROR!" 1>&2
    return 1
  }
  echo "${FUNCNAME}(): package count:"
  find "${1}" -name tagfile -exec grep -o ":.\+$" '{}' \; | sort | uniq -c
  return ${PIPESTATUS[0]}
} # grep_all_statuses()
################################################################################
function usage() {
  cat <<-EOF
	usage: ${0##*/} <option>

	options:
	  -b		revert back to original tagfiles (copy tagfile.original -> tagfile)
	  -f		get tagfiles from FTP
	  -t dir	copy tagfiles from source
	  		(eg. /mnt/dvd/slackware)
	  -T		delete (local) tagfiles from destination
	        	(default: ${TAGFILES_DIR})
	  -g		grep all (current) statuses
	  -h		this help

	  NOTE: remember the quotes, we use getopts here.

	  -o "a ap"		include OPTional packages in categories a & ap
	  -O "a ap"		exclude OPTional packages in categories a & ap

	  -q			enable all REQUIRED packages

	  -r "a ap"		include RECommended packages in categories a & ap
	  -R "a ap"		exclude RECommended packages in categories a & ap

	  -s "bluetooth alsa"	include subcategories bluetooth & alsa
	  -S "bluetooth alsa"	exclude subcategories bluetooth & alsa

	  -c "a ap"		include all packages in categories a & ap
	  -C "a ap"		exclude all packages in categories a & ap
	  (NOTE: you can also use the keyword "all")

	categories in slackware 14.0:
	(see the current ones from: http://www.slackware.com/install/softwaresets.php)
	  a	- The base system
	  ap	- Various applications that do not require the X Window System
	  d	- Program development tools
	  e	- GNU Emacs
	  f	- FAQs, HOWTOs, and other miscellaneous documentation
	  k	- The source code for the Linux kernel
	  kde	- The K Desktop Environment
	  kdei	- Language support for the K Desktop Environment
	  l	- System libraries
	  n	- Networking programs
	  t	- teTeX document formatting system
	  tcl	- The Tool Command Language, Tk, TclX, and TkDesk
	  x	- The base X Window System
	  xap	- X applications
	  xfce	- Xfce Desktop Environment
	  y	- Games

	subcategories (defined in this script):
	  bluetooth
	  alsa
	  wireless
	  server
	  obex
	  libs
	  essential (use this with -q)
	  dev

	examples:

	  plan:
	    disable categories: e, f, k, kde, kdei, t, tcl, x, xap & y
	    we'll have: a, ap, d, l & n
	    disable all OPT packages in these categories
	    enable all REC packages in these categories
	    disable all packages in the following subcategories: bluetooth alsa wireless server obex

	  command:
	    ${0##*/} -C "e f k kde kdei t tcl x xap y" -r "a ap d l n" -O "a ap d l n" -S "bluetooth alsa wireless server obex"

	  plan:
	    bare minimum installation

	  command:
	    ${0##*/} -C all -q -s essential
EOF
  return ${?}
} # usage()
################################################################################
function print_package_descriptions() {
  awk '/^PACKAGE DESCRIPTION:$/{getline;print}' "${SLACKWARE_DIR}/PACKAGES.TXT"
  return ${?}
} # print_package_descriptions()
################################################################################
function modify_packages_from_reference() {
  # this function modifies OPT/REC packages in category $1
  # $1 = category
  # $2 = reference (OPT, REC...)
  # $3 = ADD|SKP
  local    CATEGORIES="${1}"
  local    CATEGORY
  local -a PACKAGES
  local    PACKAGE
  local    MESSAGE
  local -i PKGS_MODIFIED
  local -i CAT_REF_COUNT

  [[ ! "${3}" =~ "^(ADD|SKP)$" ]] && {
    echo "${FUNCNAME}(): ERROR!" 1>&2
    return 1
  }

  for CATEGORY in ${CATEGORIES}
  do
    [ ! -d "${TAGFILES_DIR}/${CATEGORY}" ] && {
      echo "${FUNCNAME}(): ERROR: directory for category \`${CATEGORY}' does not exist!" 1>&2
      continue
    }

    # what message to print
    case "${2}:${3}" in
      "OPT:ADD") MESSAGE="enabling all OPTional"	;;
      "OPT:SKP") MESSAGE="disabling all OPTional"	;;
      "REC:ADD") MESSAGE="enabling all RECommended"	;;
      "REC:SKP") MESSAGE="disabling all RECommended"	;;
    esac

    # this way we can check that we enabled/disabled the right amount of packages
    CAT_REF_COUNT=`grep -c ":${2}$" "${TAGFILES_DIR}/${CATEGORY}/tagfile.original"`
    PKGS_MODIFIED=0

    echo "${FUNCNAME}(): ${MESSAGE} packages in category ${CATEGORY} (${CAT_REF_COUNT} packages)"

    # TODO: add md5sum check for .original here!

    # check the packages from the .original tagfile
    PACKAGES=(`sed -n '/:'"${2}"'$/s/^\(.\+\):'"${2}"'$/\1/p' "${TAGFILES_DIR}/${CATEGORY}/tagfile.original"`)

    # search every package from our reference array and change it's state to $3
    # we could optimize this by not doing one sed / package, but what the hell...
    for PACKAGE in ${PACKAGES[*]}
    do
      #echo "${FUNCNAME}(): DEBUG: OPT package ${PACKAGE}"
      #echo "-e '/${PACKAGE}/p'"
      #echo "${PACKAGE}"
      #sed -n '/^'"${PACKAGE}"':'"${2}"'$/p' "${TAGFILES_DIR}/${CATEGORY}/tagfile"

      sed -i 's/^\('"${PACKAGE}"'\):[A-Z]\+/\1:'"${3}"'/' "${TAGFILES_DIR}/${CATEGORY}/tagfile" && ((PKGS_MODIFIED++))
    done
    echo "${FUNCNAME}(): done. state of ${PKGS_MODIFIED} packages modified."
    #done | xargs -I '{}' echo "sed -n '{}' \"${TAGFILES_DIR}/${CATEGORY}/tagfile\""
  done # for CATEGORY in ${CATEGORIES}
  return 0
} # modify_packages_from_reference()
################################################################################
function modify_category() {
  # this function modifies packages in category $1 to state -> $2
  # $1 = category
  # $2 = ADD|SKP
  local CATEGORIES="${1}"
  local CATEGORY
  local -a PACKAGES
  local    PACKAGE
  local    TAGFILE

  # some sanity checks
  [[ ! "${2}" =~ "^(ADD|SKP)$" ]] && {
    echo "${FUNCNAME}(): ERROR!" 1>&2
    return 1
  }

  [ "${CATEGORIES}" = "all" ] && {
    # this lists all the categories
    CATEGORIES="` \
      find "${TAGFILES_DIR}" \( ! -wholename "${TAGFILES_DIR}" -a -type d \) -maxdepth 1 | \
      awk -F'/' '{print$NF}'
    `"
    #echo "${FUNCNAME}(): DEBUG: ${CATEGORIES}"
  }

  # go through all the categories defined by $1
  for CATEGORY in ${CATEGORIES}
  do
    [ ! -d "${TAGFILES_DIR}/${CATEGORY}" ] && {
      echo "${FUNCNAME}(): ERROR: directory for category \`${CATEGORY}' does not exist!" 1>&2
      continue
    }
    TAGFILE="${TAGFILES_DIR}/${CATEGORY}/tagfile"
    [ ! -f "${TAGFILE}" ] && {
      echo "${FUNCNAME}(): ERROR: tagfile for category \`${CATEGORY}' does not exist!" 1>&2
      continue
    }
    case "${2}" in
      "ADD") echo "${FUNCNAME}(): enabling all packages in category \`${CATEGORY}'" ;;
      "SKP") echo "${FUNCNAME}(): disabling all packages in category \`${CATEGORY}'" ;;
    esac

    # modify all packages in the category, no matter what the previous state to -> $2
    sed -i 's/\(^.\+\):[A-Z]\+$/\1:'"${2}"'/' "${TAGFILE}"
  done
  return 0
} # modify_category()
################################################################################
function modify_subcategories() {
  # TODO: under construction
  # $1 = subcategory
  # $2 = ADD|SKP
  local SUBCATEGORIES="${1}"
  local SUBCATEGORY
  local PACKAGES
  local PACKAGE
  for SUBCATEGORY in ${SUBCATEGORIES}
  do
    echo "${FUNCNAME}(): DEBUG: SUBCATEGORY=${SUBCATEGORY}"

    # here we use some indirect variable referencing, so we don't need to
    # "hardcode" the accepted subcategory parameters
    # ...so as long as there is such an array defined, we're good to go!
    PACKAGES="${SUBCATEGORY}_PACKAGES[*]"
    [ -z "${!PACKAGES}" ] && {
      echo "${FUNCNAME}: warning: no such subcategory \`${SUBCATEGORY}'!"
      continue
    }
    for PACKAGE in ${!PACKAGES}
    do
      #echo "${PACKAGE}"
      modify_packages "${PACKAGE}" "${2}"
    done
  done
  return 0
} # modify_subcategories()
################################################################################
function check_opt_rec_packages() {
  local -a CATEGORIES
  local    CATEGORY
  #local -a TAGFILES=(`find "${TAGFILES_DIR}" -name tagfile`)
  local    TAGFILE

  # find all directories (categories) inside $TAGFILES_DIR
  # and print the last directory (field)
  [ ! -d "${TAGFILES_DIR}" ] && {
    echo "${FUNCNAME}(): error: tagfiles directory (\`${TAGFILES_DIR}') does not exist!" 1>&2
    return 1
  }
  local -a CATEGORY_DIRS=(` \
    find "${TAGFILES_DIR}" \( ! -wholename "${TAGFILES_DIR}" -a -type d \) -maxdepth 1 | \
    awk -F'/' '{print$NF}'
  `)
  [ ${#CATEGORY_DIRS[*]} -eq 0 ] && {
    echo "${FUNCNAME}(): warning: no tagfiles found!" 1>&2
    return 1
  }
  for CATEGORY in ${CATEGORY_DIRS[*]}
  do
    #echo "${FUNCNAME}(): DEBUG: checking ${CATEGORY}"

    # grep for any OPT or REC packages
    grep -q ":\(OPT\|REC\)$" "${TAGFILES_DIR}/${CATEGORY}/tagfile" && {
      #echo "${FUNCNAME}(): DEBUG: ${CATEGORY}"
      CATEGORIES[${#CATEGORIES[*]}]="${CATEGORY}"
    }
  done
  [ ${#CATEGORIES[*]} -ne 0 ] && {
    echo "${FUNCNAME}(): warning: there are still OPT or REC packages inside the following categories: ${CATEGORIES[*]}"
  }
  return 0
} # check_opt_rec_packages()
################################################################################
function modify_packages() {
  # $1 = package
  # $2 = ADD || SKP
  local -a CATEGORIES=()
  local    PACKAGE
  local    TAGFILE
  local    ORIGINAL_STATE
  if [ ${#} -ne 2 ]
  then
    echo "${FUNCNAME}(): error: wrong amount of parameters!" 1>&2
    return 1
  elif [ "${2}" != "ADD" -a "${2}" != "SKP" ]
  then
    echo "${FUNCNAME}(): error: parameter \$2 is not ADD or SKP!" 1>&2
    return 1
  fi
  for PACKAGE in "${1}"
  do
    # find out which category the package is in
    CATEGORIES=(`find "${TAGFILES_DIR}" -name tagfile -exec grep -H "^${1}:[A-Z]\+$" '{}' \; | awk -F'/' '{print$(NF-1)}'`)
    if [ ${#CATEGORIES[*]} -eq 0 ]
    then
      echo "${FUNCNAME}(): error: package \`${1}' not found in any of the categories!" 1>&2
      return 1
    elif [ ${#CATEGORIES[*]} -gt 1 ]
    then
      echo "${FUNCNAME}(): error: package \`${1}' found in more than one category! this should not happen." 1>&2
      return 1
    else
      TAGFILE="${TAGFILES_DIR}/${CATEGORIES[0]}/tagfile"
      ORIGINAL_STATE=`awk -F':' '/^'"${PACKAGE}"':/{print$2}' "${TAGFILE}.original"`
      # ${#CATEGORIES[*]} must be 1 then...
      case "${2}" in
	"SKP") echo "${FUNCNAME}(): disabling package \`${1}' in category ${CATEGORIES[0]} (original state: ${ORIGINAL_STATE})" ;;
	"ADD") echo "${FUNCNAME}(): enabling package \`${1}' in category ${CATEGORIES[0]} (original state: ${ORIGINAL_STATE})" ;;
      esac
      sed -i 's/\(^'"${PACKAGE}"'\):[A-Z]\+/\1:'"${2}"'/' "${TAGFILE}"
      return 0
    fi
  done
  return 0
} # disable_packages()
################################################################################
function revert_tagfiles_from_original() {
  # TODO: this function is somewhat of a duplicate effort... replace all copying
  #       with one function.
  local -a DIRS=(`find "${TAGFILES_DIR}" \( ! -wholename "${1}" -a -type d \) -maxdepth 1`)
  local    DIR
  for DIR in ${DIRS[*]}
  do
    cp -v "${DIR}/tagfile.original" "${DIR}/tagfile"
  done
  return 0
}
################################################################################
function enable_required_packages() {
  # this function enables only the packages which are marked as REQUIRED in the
  # maketag scripts. in slackware 13.1, this makes 31 packages total.

  local -a PACKAGES=(`find "${TAGFILES_DIR}" -name 'maketag' -exec awk -F'"' '/REQUIRED.+on/{print$2}' '{}' \;`)
  local    PACKAGE

  echo "${FUNCNAME}(): enabling all REQUIRED packages"

  for PACKAGE in ${PACKAGES[*]}
  do
    modify_packages "${PACKAGE}" ADD
  done
  return 0
} # enable_required_packages()
################################################################################

# NOTE: we could use $* and shift to go through all the provided parameters,
#       that way the packages/categories defined with each parameter wouldn't
#       need to be quoted. but as for now, we'll go with getopts and quotes.
while getopts "bc:C:fgho:O:qr:R:s:S:t:T" OPTION
do
  case "${OPTION}" in
    "b") revert_tagfiles_from_original ;;
    # include category
    "c")
      CATEGORIES="${OPTARG}"
      modify_category "${CATEGORIES}" ADD
    ;;
    # exclude category
    "C")
      CATEGORIES="${OPTARG}"
      modify_category "${CATEGORIES}" SKP
    ;;
    "f") get_tagfiles_from_net			;;
    "g") grep_all_statuses "${TAGFILES_DIR}"	;;
    "h") usage					;;
    "o")
      CATEGORIES="${OPTARG}"
      modify_packages_from_reference "${CATEGORIES}" OPT ADD
    ;;
    "O")
      CATEGORIES="${OPTARG}"
      modify_packages_from_reference "${CATEGORIES}" OPT SKP
    ;;
    "q") enable_required_packages ;;
    "r")
      CATEGORIES="${OPTARG}"
      modify_packages_from_reference "${CATEGORIES}" REC ADD
    ;;
    "R")
      CATEGORIES="${OPTARG}"
      modify_packages_from_reference "${CATEGORIES}" REC SKP
    ;;
    # include subcategories
    "s")
      SUBCATEGORIES="${OPTARG}"
      modify_subcategories "${SUBCATEGORIES}" ADD
    ;;
    # exclude subcategories
    "S")
      SUBCATEGORIES="${OPTARG}"
      modify_subcategories "${SUBCATEGORIES}" SKP
    ;;
    "t")
      SLACKWARE_DIR="${OPTARG}"
      copy_tagfiles "${SLACKWARE_DIR}"
    ;;
    "T") remove_tagfiles   "${TAGFILES_DIR}" 	;;
  esac
done

echo -n $'\n'
# final check to see if there's still some OPT or REC packages left
check_opt_rec_packages

exit 0

