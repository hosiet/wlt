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


WLT_CONFIG_FILE="/etc/wlt.conf"
WLT_CONFIG_FILE_LOCAL="$HOME/.config/wlt.conf"

# Strings

WLT_SCRIPT_VERSION="0.1.3"

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

print_ISP_info()
{
    printf '
 Here comes ISP Explanation:

 1: CERNET with public IP address
 2: China Telecom (NAT); routed to CERNET if visiting CERNET website
 3: China Unicom (NAT); routed to CERNET if visiting CERNET website
 4: China Telecom (NAT); routed to CERNET if visiting CERNET "free" address
 5: China Unicom (NAT); routed to CERNET if visiting CERNET "free" address
 6: China Telecom (NAT); routed to CERNET if visiting CERNET website; routed to China Unicom (NAT) if visiting China Unicom address
 7: China Unicom (NAT); routed to CERNET if visiting CERNET website; routed to China Telecom (NAT) if visiting China Telecom address
 8: CERNET; routed to China Telecom (NAT) or China Unicom (NAT) if visiting address within China
 9: China Mobile (NAT)

 Visit http://wlt.ustc.edu.cn/link.html for detailed explanation.'

    return
}

print_usage()
{
    echo "Usage: $0 [-ohd] (invalid)[upte]"
    print_ISP_info
    return 0
}

print_header()
{
    printf "USTC WLT Script ${WLT_SCRIPT_VERSION}\n"
    printf "Copyright (C) 2015 Boyuan Yang\n\n"
    printf "This is free software; see the source for copying conditions.  There is NO\n\
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n\n"
}

process_tool_check() {
    which nc > /dev/null 2>&1
    if [ ! "x$?" = "x0" ]; then
        printf "You need nc to run the script.\n"
        exit 1
    fi
    which iconv > /dev/null 2>&1
    if [ ! "x$?" = "x0" ]; then
        printf "You need iconv to run the script.\n"
        exit 1
    fi
    return 0
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

process_post_nc() {
    readonly WLT_POST_STR_SKEL='POST /cgi-bin/ip HTTP/1.0\r\nUser-Agent: Wlt-script 0.2\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: %s\r\n\r\nname=%s&password=%s&cmd=%s&type=%s&exp=%s'

    WLT_POST_STR=$(printf "$WLT_POST_STR_SKEL" "$(expr 31 + $(printf \"$WLT_USERNAME\"\"$WLT_PASSWORD\"\"set\"\"$WLT_ISP\"\"$WLT_TIME\" | wc -m))" "$WLT_USERNAME" "$WLT_PASSWORD" "set" "$WLT_ISP" "$WLT_TIME")

    response=$(printf "$WLT_POST_STR" | nc 202.38.64.59 80 | iconv -f GBK -t UTF-8)

    if [ "x$(echo \"$response\" | grep '请重新登录')" != "x" ]; then
        printf "Failed login. Possibly wrong username or password.\n"
        return 1
    fi
    if [ "x$(echo \"$response\" | grep '欢迎使用中国科学技术大学')" != "x" ]; then
        printf "Failed login. Possibly invalid username or password.\n"
        return 1
    fi

    if [ ! "x$(printf \"$response\" | grep '网络设置成功')" = "x" ]; then
        # Unrecognized info
        printf "ERR: Unrecognized information.\n"
        return 2
    else
        ISP=$(echo "$response" | grep "出口: ")
        RIGHT=$(echo "$response" | grep "权限: ")
        printf "Success!\n${ISP}\n${RIGHT}\n"
        return 0
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
        process_post_nc
    else
        exit 1
    fi

}

# Main

# TODO FIXME i18n support
# TODO FIXME getopt
# :oh means bash deal

print_header
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
            process_post_nc
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

main_function_default
exit 0

