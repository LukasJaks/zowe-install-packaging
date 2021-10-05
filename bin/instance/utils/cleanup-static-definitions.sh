#!/bin/sh

################################################################################
# This program and the accompanying materials are made available under the terms of the
# Eclipse Public License v2.0 which accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.
################################################################################

################################################################################
# This utility script will validate component instances defined in static
# definitions. If the instance is not presented any more, the static definition
# will be removed.
#
# Note: this utility requires node.js.
################################################################################

################################################################################
# Functions
check_instance() {
  result=$(node "${ROOT_DIR}"/bin/utils/curl.js "$1" -k 2>&1 | grep -E '(ENOTFOUND|EHOSTUNREACH)')
  if [ -n "${result}" ]; then
    echo "    - ${result}"
    return 1
  fi
}

################################################################################
# Constants and variables
ROOT_DIR=/home/zowe/runtime
INSTANCE_DIR=/home/zowe/instance
WORKSPACE_DIR=${INSTANCE_DIR}/workspace
STATIC_DEF_CONFIG_DIR=${WORKSPACE_DIR}/api-mediation/api-defs
# dns resolution cool down minutes
POD_DNS_COOL_DOWN=15

# import instance configuration
. ${INSTANCE_DIR}/bin/internal/utils.sh
. ${ROOT_DIR}/bin/utils/utils.sh

# check static definitions
modified=
for one in $(find "${STATIC_DEF_CONFIG_DIR}" -type f -mmin "+${POD_DNS_COOL_DOWN}"); do
  echo "Validating ${one}"
  instance_urls=$(read_yaml "${one}" ".services[].instanceBaseUrls[]" 2>/dev/null)
  if [ -n "${instance_urls}" ]; then
    for url in ${instance_urls}; do
      echo "  - ${url}"
      check_instance "${url}"
      if [ $? -gt 0 ]; then
        rm -f "${one}"
        echo "    * invalid and removed"
        modified=true
      else
        echo "    * valid"
      fi
    done
  fi
  echo
done

# refresh static definition services
if [ "${modified}" = "true" ]; then
  echo "Refreshing static definitions"
  node ${ROOT_DIR}/bin/utils/curl.js -k https://${GATEWAY_HOST}:${GATEWAY_PORT}/api/v1/apicatalog/static-api/refresh -X POST --key ${KEYSTORE_DIRECTORY}/keystore.key --cert ${KEYSTORE_DIRECTORY}/keystore.cert --cacert ${KEYSTORE_DIRECTORY}/localca.cert
fi

echo
echo "done"
