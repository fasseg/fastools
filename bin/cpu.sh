#!/bin/bash

ACTION="status"
CPUFREQ_BINARY=`which cpufreq-set`
SCRIPT_NAME=$(basename $0)


function print_error()
{
    >&2 echo "ERROR: $1"
}

function print_usage()
{
    echo -e "\nUsage: $SCRIPT_NAME <options> [status|toggle|list]"
    echo -e "\nOptions:"
    echo -e "\t-h\t\tShow this help"
}

function enumerate_cpus()
{
    cpus=$(find /sys/devices/system/cpu -type d -regextype sed -regex ".*cpu[0-9]\{1,2\}" -exec basename {} \;)
    echo $cpus
}

function check_error()
{
    if [[ $? -ne 0 ]];then
        print_error "$1"
        exit 1
    fi
}

function toggle_govenor()
{
    cpus=$(enumerate_cpus)
    for cpu in $cpus; do
        if [[ "$cpu" == "cpu0" ]];then
            gov=$(cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor)
            if [[ "$gov" == "powersave" ]];then
                next_gov="performance"
            else
                next_gov="powersafe"
            fi
        fi
        $CPUFREQ_BINARY -c ${cpu:3} -g $next_gov 
        check_error "Unable to switch govenor! Exiting"
    done
}

function get_status()
{
    cpus=$(enumerate_cpus)
    # Get the first govenor
    for cpu in $cpus;do
        gov=$(cat /sys/devices/system/cpu/$cpu/cpufreq/scaling_governor)
        printf "%s: %s\n" $cpu $gov
    done
}

# Check the options of the command line
while getopts ":h" opt;do
    case opt in
        h)
            print_usage
            exit 0
            ;;
        *)
            print_error "Invalid option: -$OPTARG"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

# Check the Action argument given on the command line
if [[ $# > 1 ]];then
    print_error "Unable to parse comman line options"
    print_usage
    exit 1
fi

if [[ $# -eq 1 ]];then
    ACTION=$1
fi

case $ACTION in
    status)
        get_status
        ;;
    toggle)
        toggle_govenor
        ;;
    list)
        enumerate_cpus
        ;;
    *)
        print_error "Invalid action: $ACTION"
        print_usage
        exit 1
        ;;
esac
