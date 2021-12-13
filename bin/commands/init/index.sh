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

print_level0_message "Configure Zowe"

zwecli_inline_execute_command init mvs
zwecli_inline_execute_command init certificate
zwecli_inline_execute_command init vsam
if [ "${ZWE_CLI_PARAMETER_SKIP_SECURITY_SETUP}" != "true" ]; then
  zwecli_inline_execute_command init apfauth
  zwecli_inline_execute_command init security
fi
zwecli_inline_execute_command init stc

print_level1_message "Zowe is configured successfully."