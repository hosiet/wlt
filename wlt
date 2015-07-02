#!/bin/sh
#
#   Copyright (C) 2015 Boyuan Yang <073plan@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along
#   with this program; if not, write to the Free Software Fondation, Inc.,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
#
##########################################################################

HAVE_ICONV=""
WLT_CONFIG_FILE="/etc/wlt.conf"
WLT_CONFIG_FILE_LOCAL="~/.config/wlt.conf"

# Strings

WLT_SCRIPT_VERSION="0.1.1"

WLT_NO_CURL_WARN="Sorry, it seems that you haven't install curl tool.\n\
Please install curl first."
WLT_SANITY_CHECK_FAILED="Sanity check failed, Invalid wlt parameter encountered."
WLT_ISP_USEDEFAULT="No valid value found. Using 0 as default."
WLT_TIME_USEDEFAULT="No valid value found. Using 14400 as default."

# Functions

reset_user_credential()
{
    WLT_USERNAME=""
    WLT_PASSWORD=""
    WLT_ISP=""
    WLT_TIME=""
}

read_user_credential()
{
    # load global config file
    if [ -f $WLT_CONFIG_FILE ]; then
        . ${WLT_CONFIG_FILE}
    fi
    # load user config file (preferred)
    if [ -f $WLT_CONFIG_FILE_LOCAL ]; then
        . ${WLT_CONFIG_FILE_LOCAL}
    fi
    if [ ! "x${EnableDefaultWltCredential}" = "x1" ]; then
        reset_user_credential
    fi
}

print_usage()
{
    echo "Usage: $0 [-ohd] (invalid)[upte]"
    return 0
}

print_header()
{
    echo "USTC WLT Script ${WLT_SCRIPT_VERSION}"
    echo "Copyright (C) 2015 Boyuan Yang\n"
    echo "This is free software; see the source for copying conditions.  There is NO\n\
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n"
}

print_no_curl()
{
    echo "${WLT_NO_CURL_WARN}"
}

print_ISP_info()
{
    # FIXME
    return
}

params_init()
{
    which "iconv" > /dev/null 2>&1
    if [ "x$?" = "x0" ]; then
        HAVE_ICONV="Y"
    else
        HAVE_ICONV=""
    fi
}


process_abort()
{
    echo "\nOperation aborted."
    exit 1
}

##
# 检查当前参数是否有效
#
process_sanity_check()
{
    if [ "x${WLT_USERNAME} = "x" -o "x${WLT_PASSWORD} = "x" ]; then
        echo "${WLT_SANITY_CHECK_FAILED}"
        process_abort
    fi
    if [ "x${WLT_ISP}" = "x" -o "x${WLT_TIME}" = "x" ]; then
        echo "${WLT_SANITY_CHECK_FAILED}"
        process_abort
    fi
}

##
# 分析结果是否正确
# FIXME
process_analyze_result()
{
    return 0
}

process_print_success()
{
    echo "Operation success.\n"
    return 0
}

process_post_curl()
{
    if [ "x${HAVE_ICONV}" = "xY" ]; then
        curl --data "name=${WLT_USERNAME}&password=${WLT_PASSWORD}&cmd=set&type=${WLT_ISP}&exp=${WLT_TIME}" http://wlt.ustc.edu.cn/cgi-bin/ip | iconv -f GBK -t UTF-8
    else
        curl --data "name=${WLT_USERNAME}&password=${WLT_PASSWORD}&cmd=set&type=${WLT_ISP}&exp=${WLT_TIME}" http://wlt.ustc.edu.cn/cgi-bin/ip
    fi
    if [ ! "x$?" = "x0" ]; then
        process_abort
    else
        process_print_success
    fi
}

main_function_default()
{
    echo -n "  * input your wlt username: "
    read WLT_USERNAME
    echo -n "  * input your wlt password: "
    stty -echo
    read WLT_PASSWORD
    stty echo
    echo ""
    echo -n "  * select your preferred ISP [0-8]: "
    print_ISP_info
    read WLT_ISP
    if [ "x${WLT_ISP}" = "x" ]; then
        echo "${WLT_ISP_USEDEFAULT}"
        WLT_ISP="0"
    fi
    echo -n "  * select wlt activation duration [0/3600/14400/39600/50400]: "
    read WLT_TIME
    if [ "x${WLT_TIME}" = "x" ]; then
        echo "${WLT_TIME_USEDEFAULT}"
        WLT_TIME="14400"
    fi
    echo -n "\nProcess now? [y/n]"
    USERINPUT="n"
    read USERINPUT
    if [ "x${USERINPUT}" = "x" -o "x${USERINPUT}" = "xy" ]; then
        process_sanity_check
        process_post_curl
    else
        process_abort
    fi

}

# Main

# TODO FIXME i18n support
# TODO FIXME getopt
# :oh means bash deal

print_header
params_init
reset_user_credential

while getopts ohdu:p:t:e: OPTION
do
    case ${OPTION} in
        h)
            # print help message
            print_usage
            exit 1
            ;;
        d)
            # use default section
            read_user_credential
            process_sanity_check
            process_post_curl
            exit 0
            ;;
        o)
            ;;
        \?)
            # cannot be recognized
            print_usage
            exit 1
            ;;
    esac
done


which "curl" > /dev/null 2>&1
if [ ! "x$?" = "x0" ]; then
    print_no_curl
    exit 1
fi

main_function_default
exit 0

