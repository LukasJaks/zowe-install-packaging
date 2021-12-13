#!/bin/sh

#######################################################################
# This program and the accompanying materials are made available
# under the terms of the Eclipse Public License v2.0 which
# accompanies this distribution, and is available at
# https://www.eclipse.org/legal/epl-v20.html
#
# SPDX-License-Identifier: EPL-2.0
#
# Copyright Contributors to the Zowe Project.
#######################################################################

###############################
# Read JSON configuration from shell script
#
# Note: this is not a reliable way to read JSON file. The JSON file must be
#       properly formatted, each key/value pair takes one line.
#
# FIXME: we should have a language neutral JSON reading tool, not using shell script.
#
# @param string   JSON file name
# @param string   parent key to read after
# @param string   which key to read
# @param string   if this variable is required. If this is true and we cannot
#                 find the value of the key, an error will be displayed.
shell_read_json_config() {
  json_file=$1
  parent_key=$2
  key=$3
  required=$4

  val=$(cat "${json_file}" | awk "/\"${parent_key}\":/{x=NR+200}(NR<=x){print}" | grep "${key}" | head -n 1 | awk -F: '{print $2;}' | tr -d '[[:space:]]' | sed -e 's/,$//' | sed -e 's/^"//' -e 's/"$//')
  if [ -z "${val}" ]; then
    if [ "${required}" = "true" ]; then
      exit_with_error "cannot find ${parent_key}.${key} defined in $(basename $json_file)" "instance/bin/internal/utils.sh,shell_read_json_config:${LINENO}"
    fi
  else
    echo "${val}"
  fi
}

###############################
# Read YAML configuration from shell script
#
# Note: this is not a reliable way to read YAML file, but we need this to find
#       out ROOT_DIR to execute further functions.
#
# FIXME: we should have a language neutral YAML reading tool, not using shell script.
#
# @param string   YAML file name
# @param string   parent key to read after
# @param string   which key to read
# @param string   if this variable is required. If this is true and we cannot
#                 find the value of the key, an error will be displayed.
shell_read_yaml_config() {
  yaml_file=$1
  parent_key=$2
  key=$3
  required=$4

  val=$(cat "${yaml_file}" | awk "/${parent_key}:/{x=NR+2000;next}(NR<=x){print}" | grep "${key}" | head -n 1 | awk -F: '{print $2;}' | tr -d '[[:space:]]' | sed -e 's/^"//' -e 's/"$//')
  if [ -z "${val}" ]; then
    if [ "${required}" = "true" ]; then
      exit_with_error "cannot find ${parent_key}.${key} defined in $(basename $yaml_file)" "instance/bin/internal/utils.sh,shell_read_yaml_config:${LINENO}"
    fi
  else
    echo "${val}"
  fi
}

read_yaml() {
  file=$1
  key=$2

  utils_dir="${ZWE_zowe_runtimeDirectory}/bin/utils"
  fconv="${utils_dir}/fconv/src/index.js"
  jq="${utils_dir}/njq/src/index.js"

  print_trace "- read_yaml load content from ${file}"
  ZWE_PRIVATE_YAML_CACHE=$(node "${fconv}" --input-format=yaml "${file}" 2>&1)
  code=$?
  print_trace "  * Exit code: ${code}"
  if [ ${code} -ne 0 ]; then
    print_error "  * Output:"
    print_error "$(padding_left "${ZWE_PRIVATE_YAML_CACHE}" "    ")"
    return ${code}
  fi

  print_trace "- read_yaml ${key} from yaml content"
  result=$(echo "${ZWE_PRIVATE_YAML_CACHE}" | node "${jq}" -r "${key}" 2>&1)
  code=$?
  print_trace "  * Exit code: ${code}"
  print_trace "  * Output:"
  if [ -n "${result}" ]; then
    print_trace "$(padding_left "${result}" "    ")"
  fi

  if [ ${code} -eq 0 ]; then
    echo "${result}"
  fi

  return ${code}
}

read_json() {
  file=$1
  key=$2

  utils_dir="${ZWE_zowe_runtimeDirectory}/bin/utils"
  jq="${utils_dir}/njq/src/index.js"

  print_trace "- read_json ${key} from ${file}"
  result=$(cat "${file}" | node "${jq}" -r "${key}" 2>&1)
  code=$?
  print_trace "  * Exit code: ${code}"
  print_trace "  * Output:"
  if [ -n "${result}" ]; then
    print_trace "$(padding_left "${result}" "    ")"
  fi

  if [ ${code} -eq 0 ]; then
    echo "${result}"
  fi

  return ${code}
}