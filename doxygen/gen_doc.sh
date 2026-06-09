#!/usr/bin/env bash
# Version: 2.1
# Date: 2023-04-19
# This bash script generates Ethos-U documentation:
#
# Pre-requisites:
# - bash shell (for Windows: install git for Windows)
# - doxygen 1.13.2

set -o pipefail

# Set version of gen pack library
REQUIRED_GEN_PACK_LIB="0.13.0"

DIRNAME=$(dirname $(readlink -f $0))
DOXYGEN=$(which doxygen 2>/dev/null || true)

REQ_DXY_VERSION="1.13.2"

############ DO NOT EDIT BELOW ###########

function install_lib() {
  local URL="https://github.com/Open-CMSIS-Pack/gen-pack/archive/refs/tags/v$1.tar.gz"
  echo "Downloading gen-pack lib to '$2'"
  mkdir -p "$2"
  curl -L "${URL}" -s | tar -xzf - --strip-components 1 -C "$2" || exit 1
}

function load_lib() {
  if [[ -d ${GEN_PACK_LIB} ]]; then
    . "${GEN_PACK_LIB}/gen-pack"
    return 0
  fi
  local GLOBAL_LIB="/usr/local/share/gen-pack/${REQUIRED_GEN_PACK_LIB}"
  local USER_LIB="${HOME}/.local/share/gen-pack/${REQUIRED_GEN_PACK_LIB}"
  if [[ ! -d "${GLOBAL_LIB}" && ! -d "${USER_LIB}" ]]; then
    echo "Required gen-pack lib not found!" >&2
    install_lib "${REQUIRED_GEN_PACK_LIB}" "${USER_LIB}"
  fi

  if [[ -d "${GLOBAL_LIB}" ]]; then
    . "${GLOBAL_LIB}/gen-pack"
  elif [[ -d "${USER_LIB}" ]]; then
    . "${USER_LIB}/gen-pack"
  else
    echo "Required gen-pack lib is not installed!" >&2
    exit 1
  fi
}

load_lib

find_doxygen "${REQ_DXY_VERSION}" || true

if [[ -z "${UTILITY_DOXYGEN}" ]]; then
  UTILITY_DOXYGEN="$(type -p doxygen 2>/dev/null || true)"
fi
if [[ -z "${UTILITY_DOXYGEN}" ]]; then
  echo "Error: No doxygen executable found in PATH" >&2
  exit 1
fi

###############################################

REGEN=0
ALLPARTS=($(find ${DIRNAME} -mindepth 1 -maxdepth 1 -type d -exec basename {} \;))
PARTS=()

if [[ -z "$*" ]]; then
    REGEN=1
else
    for part in "$*"; do
        if [[ " ${ALLPARTS[@]} " =~ " $part " ]]; then
            PARTS+=($part)
        fi
    done
fi

function doxygen {
    partname=$(basename $(dirname $1))
    if [[ $REGEN != 0 ]] || [[ " ${PARTS[@]} " =~ " ${partname} " ]]; then
        pushd "$(dirname $1)" > /dev/null
        echo "${UTILITY_DOXYGEN} $1"
        "${UTILITY_DOXYGEN}" $(basename "$1")
        popd > /dev/null

    outdir="${DIRNAME}/../Documentation/${partname}/html"
    if [[ ! -d "${outdir}" ]]; then
      echo "Warning: Doxygen output directory not found: ${outdir}" >&2
      return
    fi

        if [[ $2 != 0 ]]; then
        #    mkdir -p "${DIRNAME}/../Documentation/${partname}/html/search/"
      cp -f "${DIRNAME}/Doxygen_Templates/navtree.js" "${outdir}/"
        fi

        projectName=$(awk -F= '/^PROJECT_NAME[[:space:]]*=/{gsub(/^[ \t"]+|[ \t"]+$/, "", $2); print $2; exit}' "$1")
        projectNumber=$(awk -F= '/^PROJECT_NUMBER[[:space:]]*=/{gsub(/^[ \t"]+|[ \t"]+$/, "", $2); print $2; exit}' "$1")
        datetime=$(date -u +'%a %b %e %Y %H:%M:%S')
        sed -e "s/{datetime}/${datetime}/" "${DIRNAME}/Doxygen_Templates/footer.js" \
          | sed -e "s/{projectName}/${projectName}/" \
          | sed -e "s/{projectNumber}/${projectNumber}/" \
          > "${outdir}/footer.js"
    fi
}

    mkdir -p "${DIRNAME}/../Documentation/"

if [[ $REGEN != 0 ]]; then
    echo "Cleaning existing documentation ..."
    find "${DIRNAME}/../Documentation/" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
fi

echo "Generating documentation ..."
doxygen "${DIRNAME}/general/general.dxy" 1
doxygen "${DIRNAME}/drivers/drivers.dxy" 1
doxygen "${DIRNAME}/integration/integration.dxy" 1

exit 0
