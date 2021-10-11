#!/bin/bash


function main() {
    local cur_time
    local results_dir
    local generic_file="generic.txt"

    if ! command -v ipmitool &> /dev/null
    then
	>&2 echo "ipmitool is required"
	exit
    fi

    cur_time="$(date --utc --iso-8601=minutes)"
    results_dir=tiusb_"${cur_time}"

    if ! mkdir "${results_dir}" 2>/dev/null
    then
	>&2 echo "unable to create ${results_dir}"
	exit
    fi

    if ! pushd "${results_dir}"
    then
	>&2 echo "cant change dir into ${results_dir}"
	exit
    fi

    echo "---Uptime--" > "${generic_file}"
    uptime >> "${generic_file}"

    echo -e "\n---ipmi lan port---" >> "${generic_file}"
    # shellcheck disable=SC2024
    if ! sudo ipmitool lan print 1 >> "${generic_file}"
    then
	>&2 echo "can't run ipmitool"
	exit
    fi

    # shellcheck disable=SC2024
    if ! sudo lsusb -tvv > lsusb_tree.txt
    then
	>&2 echo "can't collect lsusb data"
	exit
    fi

    # shellcheck disable=SC2024
    if ! sudo lsusb -vvv > lsusb_verbose.txt 2>&1
    then
	>&2 echo "can't collect lsusb data"
	exit
    fi

    ls -la /sys/bus/usb/devices > usb_devices_symlinks.txt

    # shellcheck disable=SC2024
    if ! sudo lspci -xxx > lspci.dump
    then
	>&2 echo "can't collect lspci data"
	exit
    fi

    # shellcheck disable=SC2024
    if ! sudo lspci -tvv > lspci_tree.txt
    then
	>&2 echo "can't collect lspci data"
	exit
    fi

    # shellcheck disable=SC2024
    if ! sudo dmidecode > dmidecode.txt
    then
	>&2 echo "can't collect dmidecode data"
	exit
    fi

    # shellcheck disable=SC2024
    sudo dmesg > dmesg.txt
    # shellcheck disable=SC2024
    sudo ipmitool sel list > sel.txt

    if ! popd
    then
	>&2 echo "failed to return to original folder"
	exit
    fi

    if ! tar -cz "${results_dir}" -f "${results_dir}".tar.gz --force-local
    then
	>&2 echo "can't compress results into a tarball"
	exit
    fi
}

main "$@"
