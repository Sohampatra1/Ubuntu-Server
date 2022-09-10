#!/usr/bin/env bash

BASE_PATH=$(
  cd $(dirname "$0");
  pwd
)

COLOR_INFO='\033[0;34m'
COLOR_ERR='\033[0;35m'
NOCOLOR='\033[0m'

PDFM_DIR="/Applications/Parallels Desktop.app"
PDFM_LOC="/Library/Preferences/Parallels/parallels-desktop.loc"
PDFM_VER="18.0.1-53056"

PDFM_DISP_CRACK="${BASE_PATH}/prl_disp_service"
PDFM_DISP_DST="${PDFM_DIR}/Contents/MacOS/Parallels Service.app/Contents/MacOS/prl_disp_service"
PDFM_DISP_ENT="${BASE_PATH}/ParallelsService.entitlements"

LICENSE_FILE="${BASE_PATH}/licenses.json"
LICENSE_DST="/Library/Preferences/Parallels/licenses.json"

PDFM_DISP_ORIGINAL_HASH="70b92c64c81c7992e901c2e23a2c2a08547e0d82f3b4fa28cc5f7e8bbac04cb6"
PDFM_DISP_HASH="a0975389fb97f54c831d4db896d9b6983000b05dad4c8db88c3f2aced35a6dd9"
LICENSE_HASH="ac735f3ee7ac815539f07e68561baceda858cf7ac5887feae863f10a60db3d79"

# read location from parallels-desktop.loc
if [ -f "${PDFM_LOC}" ]; then
  PDFM_DIR=$(cat "${PDFM_LOC}")
fi

# check parallels desktop install
if [ ! -d "${PDFM_DIR}" ]; then
  echo -e "${COLOR_ERR}[-] Not found ${PDFM_DIR}, are you installed Parallels Desktop ${PDFM_VER}?${NOCOLOR}"
  echo "    Download from here: https://download.parallels.com/desktop/v18/${PDFM_VER}/ParallelsDesktop-${PDFM_VER}.dmg"
  exit 1
fi

# check parallels desktop version
VERSION_1=$(defaults read "${PDFM_DIR}/Contents/Info.plist" CFBundleShortVersionString)
VERSION_2=$(defaults read "${PDFM_DIR}/Contents/Info.plist" CFBundleVersion)
INSTALL_VER="${VERSION_1}-${VERSION_2}"
if [ "${PDFM_VER}" != "${VERSION_1}-${VERSION_2}" ]; then
  echo -e "${COLOR_ERR}[-] This crack is for ${PDFM_VER}, but you installed is ${INSTALL_VER}.${NOCOLOR}"
  echo "    Download from here: https://download.parallels.com/desktop/v18/${PDFM_VER}/ParallelsDesktop-${PDFM_VER}.dmg"
  exit 2
fi

# check prl_disp_service hash
FILE_HASH=$(shasum -a 256 -b "${PDFM_DISP_CRACK}" | awk '{print $1}')
if [ "${FILE_HASH}" != "${PDFM_DISP_HASH}" ]; then
  echo -e "${COLOR_ERR}[-] ${FILE_HASH} != ${PDFM_DISP_HASH}${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] verify crack file (prl_disp_service) hash error.${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] please re-download crack files.${NOCOLOR}"
  exit 4
fi

# check licenses.json hash
FILE_HASH=$(shasum -a 256 -b "${LICENSE_FILE}" | awk '{print $1}')
if [ "${FILE_HASH}" != "${LICENSE_HASH}" ]; then
  echo -e "${COLOR_ERR}[-] ${FILE_HASH} != ${LICENSE_HASH}${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] verify crack file (licenses.json) hash error.${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] please re-download crack files.${NOCOLOR}"
  exit 4
fi

# check run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${COLOR_ERR}[-] Please run as root.${NOCOLOR}"
  echo -e "${COLOR_INFO}    eg. sudo ${NOCOLOR}$0"
  exit 3
fi

echo -e "${COLOR_INFO}[*] Exit Parallels Desktop${NOCOLOR}"
"${PDFM_DIR}/Contents/MacOS/Parallels Service" service_stop
killall prl_client_app 2>/dev/null

echo -e "${COLOR_INFO}[*] Start Parallels Service${NOCOLOR}"
"${PDFM_DIR}/Contents/MacOS/Parallels Service" service_start

echo -e "${COLOR_INFO}[*] Exit Parallels Desktop account ...${NOCOLOR}"
"${PDFM_DIR}/Contents/MacOS/prlsrvctl" web-portal signout 2>/dev/null

echo -e "${COLOR_INFO}[*] Disable CEP ...${NOCOLOR}"
"${PDFM_DIR}/Contents/MacOS/prlsrvctl" --cep off 2>/dev/null
"${PDFM_DIR}/Contents/MacOS/prlsrvctl" --allow-attach-screenshots off 2>/dev/null

echo -e "${COLOR_INFO}[*] Stop Parallels Service${NOCOLOR}"
"${PDFM_DIR}/Contents/MacOS/Parallels Service" service_stop

echo -e "${COLOR_INFO}[*] Copy prl_disp_service${NOCOLOR}"

rm -f "${PDFM_DISP_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
cp -X "${PDFM_DISP_CRACK}" "${PDFM_DISP_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chown root:wheel "${PDFM_DISP_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chmod 755 "${PDFM_DISP_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }

# check hash
FILE_HASH=$(shasum -a 256 -b "${PDFM_DISP_DST}" | awk '{print $1}')
if [ "${FILE_HASH}" != "${PDFM_DISP_HASH}" ]; then
  echo -e "${COLOR_ERR}[-] ${FILE_HASH} != ${PDFM_DISP_HASH}${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] verify target file (prl_disp_service) hash error.${NOCOLOR}"
  exit 4
fi

echo -e "${COLOR_INFO}[*] Sign prl_disp_service${NOCOLOR}"

codesign -f -s - --timestamp=none --all-architectures --entitlements "${PDFM_DISP_ENT}" "${PDFM_DISP_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }

echo -e "${COLOR_INFO}[*] Copy fake licenses.json${NOCOLOR}"

if [ -f "${LICENSE_DST}" ]; then
  chflags -R 0 "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
  rm -f "${LICENSE_DST}" > /dev/null || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
fi

cp -X "${LICENSE_FILE}" "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chown root:wheel "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chmod 444 "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chflags uchg "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }
chflags schg "${LICENSE_DST}" || { echo -e "${COLOR_ERR}error $? at line $LINENO.${NOCOLOR}"; exit $?; }

# check hash
FILE_HASH=$(shasum -a 256 -b "${LICENSE_DST}" | awk '{print $1}')
if [ "${FILE_HASH}" != "${LICENSE_HASH}" ]; then
  echo -e "${COLOR_ERR}[-] ${FILE_HASH} != ${LICENSE_HASH}${NOCOLOR}"
  echo -e "${COLOR_ERR}[-] verify target file (${LICENSE_DST}) hash error.${NOCOLOR}"
  exit 1
fi

echo -e "${COLOR_INFO}[*] Crack over${NOCOLOR}"
