#!/usr/bin/env bash

# Copyright (c) 2010 - 2023 Nutanix Inc. All rights reserved.
# Author: era-dev@nutanix.com

ORACLE_DB="oracle_database"
POSTGRES_DB="postgres_database"
MARIA_DB="mariadb_database"
MYSQL_DB="mysql_database"
SAPHANA_DB="saphana_database"
MONGODB_DB="mongodb_database"

LINE="  ----------------------------------------------------------------------------------"

SUCCESS="success"
FAIL="fail"
YES="YES"
NO="NO"
N_A="N/A"
NA="NA"
FALSE="false"
TRUE="true"
SOFTWARE="software"
CONFIG="configuration"
SOFTWARE_DEP="software dependency"
CONFIG_DEP="configuration dependency"
package_manager="none"
global_status=$SUCCESS
indent_detail="     "

cluster_port="9440"

internal_message="Below information is for internal use only"
internal_debug_message="DEPENDENCY_CHECK DEBUG INFORMATION"
DEBUG_DELIM="##"

gcc="gcc"
readline="readline"
readline_ubuntu="libreadline"
readline_suse="libreadline"
unzip="unzip"
zip="zip"
libselinux_python="libselinux-python"
libselinux_python_rhel8="python3-libselinux"
libselinux_python_rhel="libselinux-python"
libselinux_python_ubuntu="python[3]*-selinux"
ifupdown_ubuntu="ifupdown"
net_tools_ubuntu="net-tools"
nftables_ubuntu="nftables"
tar_apt="^tar/"
tar_yum="tar"
tar_zypper="^tar-"
xfsprogs_mongodb_ubuntu_debian="xfsprogs"
libselinux_python_suse="libselinux"
lvcreate="lvcreate"
lvdisplay="lvdisplay"
lvscan="lvscan"
vgcreate="vgcreate"
vgdisplay="vgdisplay"
vgscan="vgscan"
pvcreate="pvcreate"
pvdisplay="pvdisplay"
pvscan="pvscan"
crontab="crontab"
lvm2="lvm2"
rsync="rsync"
bc="bc"
sshpass="sshpass"
ksh="ksh"
lsof="lsof"
era_sudo_script=""

usage() {
    echo "   Syntax: $ ./era_linux_prechecks.sh -t|--database_type <database_type> [-c|--cluster_ip <cluster_ip>] [-p|--cluster_port] [-d|--detailed] [-s|--restricted_sudo]"
    echo "   Database type can be: $ORACLE_DB, $POSTGRES_DB, $MARIA_DB, $MYSQL_DB, $SAPHANA_DB, $MONGODB_DB"
}

check_era_priv_cmd() {
    if [ ! -f "$era_sudo_script" ]; then
        echo "Error: era_priv_cmd.sh does not exist. Please copy the script at $HOME and provide execute permission."
        exit 1
    fi
}
while [ "$1" != "" ]; do
    case $1 in
        -t | --database_type )
            shift
            database_type=$1
            ;;
        -d | --detailed )
            show_detailed=$TRUE
            ;;
        -c | --cluster_ip )
            shift
            cluster_ip=$1
            ;;
        -p | --cluster_port )
            shift
            cluster_port=$1
            ;;
        -h | --help )
            usage
            exit
            ;;
        -e | --era_server )
            is_era_server_call=$TRUE
            ;;
        -s | --restricted_sudo )
            era_sudo_script=$HOME/era_priv_cmd.sh
            check_era_priv_cmd
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

if [ -z "$database_type" ]; then
    echo ""
    echo $LINE
    echo "   Error: Database type not specified"
    usage
    echo $LINE
    echo ""
    exit 1
fi

valid_database_type=$FALSE
if [ "$database_type" = "$ORACLE_DB" ]; then
    valid_database_type=$TRUE
elif [ "$database_type" = "$POSTGRES_DB" ]; then
    valid_database_type=$TRUE
elif [ "$database_type" = "$MARIA_DB" ]; then
    valid_database_type=$TRUE
elif [ "$database_type" = "$MYSQL_DB" ]; then
    valid_database_type=$TRUE
elif [ "$database_type" = "$SAPHANA_DB" ]; then
    valid_database_type=$TRUE
elif [ "$database_type" = "$MONGODB_DB" ]; then
    valid_database_type=$TRUE
fi

if [ "$valid_database_type" = $FALSE ]; then
    echo ""
    echo $LINE
    echo "   Error: Database '$database_type' is not supported by Era"
    echo "   Era supported database types: $ORACLE_DB, $POSTGRES_DB, $MARIA_DB, $MYSQL_DB, $SAPHANA_DB, $MONGODB_DB"
    echo $LINE
    echo ""
    exit 1
fi

check_error() {
	if [ $1 -ne 0 ]; then
        echo $NO
    else
        echo $YES
	fi
}

get_global_status() {
	if [ "$1" = $SUCCESS ]; then
	    if [ "$2" = $NO ]; then
            echo $FAIL
        else
            echo $SUCCESS
        fi
	else
	    echo $FAIL
	fi
}

global_temp_code=0

ten="          "
forty="$ten$ten$ten$ten"
indent1="    "
indent2="        "

print_function() {
    component=$1
    component="${component:0:20}${forty:0:$((20 - ${#component}))}"
    printf '%20s' "${component}"
    echo " : "$2
}

detect_package_manager() {
    declare -A osPackageInfo;
    osPackageInfo[/etc/redhat-release]=yum
    osPackageInfo[/etc/arch-release]=pacman
    osPackageInfo[/etc/gentoo-release]=emerge
    osPackageInfo[/etc/SuSE-release]=zypper
    osPackageInfo[/etc/debian_version]=apt-get
    for f in ${!osPackageInfo[@]}
    do
        if [ -f $f ];then
            echo ${osPackageInfo[$f]}
        fi
    done
}

detect_package_manager2() {
  which yum > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo yum
    return
  fi
  which apt-get > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo apt-get
    return
  fi
  which zypper > /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    echo zypper
    return
  fi
}

is_version8_os() {
  source /etc/os-release
  isValid=$(awk 'BEGIN{ print "'$VERSION_ID'" >= 8 }')
  if [ "$isValid" -eq 1 ];then
    echo $TRUE
  else
    echo $FALSE
  fi
}

search_for_package() {
    if [ "$package_manager" = "yum" ]; then
        sudo $era_sudo_script rpm -q $1 > /dev/null 2>&1
    elif [ "$package_manager" = "apt-get" ]; then
        sudo $era_sudo_script apt list --installed | grep $1 > /dev/null 2>&1
    elif [ "$package_manager" = "zypper" ]; then
        sudo $era_sudo_script rpm -qa | grep $1 > /dev/null 2>&1
    else
        eraerror > /dev/null 2>&1
    fi
    global_temp_code=$?
}

install_package_help() {
    if [ "$package_manager" = "yum" ]; then
        echo "$indent2$indent_detail  Tip: You can try 'sudo yum install $1 -y'"
    elif [ "$package_manager" = "apt-get" ]; then
        if [ ! -z $2 ]; then
            echo "$indent2$indent_detail  Tip: You can try 'sudo apt-get install $2 -y'"
        else
            echo "$indent2$indent_detail  Tip: You can try 'sudo apt-get install $1 -y'"
        fi
    else
        eraerror > /dev/null 2>&1
    fi
    global_temp_code=$?
}

user=`whoami`
package_manager=`detect_package_manager`
if [ -z "$package_manager" ]
then
# if package manager is null, use method 2 to detect package manager.
      package_manager=`detect_package_manager2`
fi
if [ "$package_manager" = 'yum' ]
then
  isVersion8=`is_version8_os`
fi
# configuration checks
# NOPASS check gets covered as part of sudo access
# Checking sudo NOPASS access through era_priv_cmd.sh script
sudo -n $era_sudo_script true > /dev/null 2>&1
sudo_access=`check_error $?`
global_status=`get_global_status $global_status $sudo_access`

if [ "$sudo_access" = $NO ]; then
echo ""
echo $LINE
echo "$indent2                  ** Error **"
echo "$indent2 Sudo access with NOPASS is not enabled on this machine"
echo "$indent2 Please enable sudo with NOPASS and re-run this script"
echo $LINE
echo ""
# Below block is for internal use only
if [ "$is_era_server_call" = $TRUE ]; then
    echo $internal_message
    echo $internal_debug_message
    echo "$CONFIG"$DEBUG_DELIM"sudo_access"$DEBUG_DELIM"$NO"$DEBUG_DELIM"Make sure the user '$user' has sudo access"
    echo "$CONFIG"$DEBUG_DELIM"sudo_nopass_access"$DEBUG_DELIM"$NO"$DEBUG_DELIM"Make sure the user '$user' has sudo NOPASS access"
    echo "=================================="
fi
exit 1
fi

(which crontab > /dev/null 2>&1) && ((crontab -l > /dev/null 2>&1) || (crontab -l 2>&1 | grep 'no crontab for' > /dev/null)) > /dev/null 2>&1
crontab_configured=`check_error $?`
global_status=`get_global_status $global_status $crontab_configured`

# check prism api connectivity
warn_curl=$FALSE
skip_cluster_check=$FALSE
if [ ! -z "$cluster_ip" ]; then
    which curl &>/dev/null
    if [ $? -ne 0 ]; then
        warn_curl=$TRUE

    else
        curl -k -X GET --header 'Accept: application/json' --connect-timeout 10 'https://'"$cluster_ip"':'"$cluster_port"'/PrismGateway/services/rest/v2.0/cluster/' &>/dev/null
        prism_connectivity=`check_error $?`
        global_status=`get_global_status $global_status $prism_connectivity`
    fi
else
   skip_cluster_check=$TRUE
fi

a=`sudo $era_sudo_script which lvdisplay`; a=${a%/*}; sudo $era_sudo_script cat /etc/sudoers | grep secure_path | grep Default | grep $a > /dev/null 2>&1
secure_paths_configured=`check_error $?`
global_status=`get_global_status $global_status $secure_paths_configured`

# software checks
xfsprogs_present=$N_A
if [ "$database_type" = "mongodb_database" ] && [ "$package_manager" = "apt-get" ]; then
    search_for_package $xfsprogs_mongodb_ubuntu_debian
    xfsprogs_present=`check_error $global_temp_code`
    global_status=`get_global_status $global_status $xfsprogs_present`
fi

nftables_present=$N_A
if [ "$database_type" = "postgres_database" ] && [ "$package_manager" = "apt-get" ]; then
    search_for_package $nftables_ubuntu
    nftables_present=`check_error $global_temp_code`
    global_status=`get_global_status $global_status $nftables_present`
fi

gcc_present=$N_A
if [ "$database_type" = "oracle_database" ]; then
    sudo $era_sudo_script gcc -v > /dev/null 2>&1
    gcc_present=`check_error $?`
    global_status=`get_global_status $global_status $gcc_present`
fi

bc_present=$N_A
if [ "$database_type" = "oracle_database" ]; then
    sudo $era_sudo_script bc -v > /dev/null 2>&1
    bc_present=`check_error $?`
    global_status=`get_global_status $global_status $bc_present`
fi

sshpass_present=$N_A
if [ "$database_type" = "oracle_database" ]; then
    sudo $era_sudo_script sshpass -V > /dev/null 2>&1
    sshpass_present=`check_error $?`
    global_status=`get_global_status $global_status $sshpass_present`
fi

ksh_present=$N_A
if [ "$database_type" = "oracle_database" ]; then
    search_for_package $ksh
    ksh_present=`check_error $global_temp_code`
    global_status=`get_global_status $global_status $ksh_present`

fi

ifupdown_present=$N_A
if [ "$package_manager" = "apt-get" ]; then
    search_for_package $ifupdown_ubuntu
    ifupdown_present=`check_error $global_temp_code`
    global_status=`get_global_status $global_status $ifupdown_present`
fi

net_tools_present=$N_A
if [ "$package_manager" = "apt-get" ]; then
    search_for_package $net_tools_ubuntu
    net_tools_present=`check_error $global_temp_code`
    global_status=`get_global_status $global_status $net_tools_present`
fi
# conditional check for readline
readline_present=$NO
if [ "$package_manager" = "yum" ]; then
    readline_present=$YES
elif [ "$package_manager" = "apt-get" ]; then
    search_for_package $readline_ubuntu
    readline_present=`check_error $global_temp_code`
elif [ "$package_manager" = "zypper" ]; then
    search_for_package $readline_suse
    readline_present=`check_error $global_temp_code`
fi
global_status=`get_global_status $global_status $readline_present`

# conditional check for tar
tar_present=$NO
if [ "$package_manager" = "yum" ]; then
    search_for_package $tar_yum
    tar_present=`check_error $global_temp_code`
elif [ "$package_manager" = "apt-get" ]; then
    search_for_package $tar_apt
    tar_present=`check_error $global_temp_code`
elif [ "$package_manager" = "zypper" ]; then
    search_for_package $tar_zypper
    tar_present=`check_error $global_temp_code`
fi
global_status=`get_global_status $global_status $tar_present`

# conditional check for libselinux-python
libselinux_present=$NO
if [ "$package_manager" = "yum" ]; then
     if [ "$isVersion8" = "true" ]; then
      search_for_package $libselinux_python_rhel8
      libselinux_present=`check_error $global_temp_code`
    else
      search_for_package $libselinux_python_rhel
      libselinux_present=`check_error $global_temp_code`
    fi
elif [ "$package_manager" = "apt-get" ]; then
    search_for_package $libselinux_python_ubuntu
    libselinux_present=`check_error $global_temp_code`
elif [ "$package_manager" = "zypper" ]; then
    search_for_package $libselinux_python_suse
    libselinux_present=`check_error $global_temp_code`
fi
global_status=`get_global_status $global_status $libselinux_present`

which unzip > /dev/null 2>&1
unzip_present=`check_error $?`
global_status=`get_global_status $global_status $unzip_present`

which zip > /dev/null 2>&1
zip_present=`check_error $?`
global_status=`get_global_status $global_status $zip_present`

sudo $era_sudo_script which crontab > /dev/null 2>&1
crontab_present=`check_error $?`
global_status=`get_global_status $global_status $crontab_present`

sudo $era_sudo_script which lvdisplay > /dev/null 2>&1
lvdisplay_present=`check_error $?`
global_status=`get_global_status $global_status $lvdisplay_present`

sudo $era_sudo_script which lvcreate > /dev/null 2>&1
lvcreate_present=`check_error $?`
global_status=`get_global_status $global_status $lvcreate_present`

sudo $era_sudo_script which lvscan > /dev/null 2>&1
lvscan_present=`check_error $?`
global_status=`get_global_status $global_status $lvscan_present`

sudo $era_sudo_script which pvdisplay > /dev/null 2>&1
pvdisplay_present=`check_error $?`
global_status=`get_global_status $global_status $pvdisplay_present`

sudo $era_sudo_script which pvcreate > /dev/null 2>&1
pvcreate_present=`check_error $?`
global_status=`get_global_status $global_status $pvcreate_present`

sudo $era_sudo_script which pvscan > /dev/null 2>&1
pvscan_present=`check_error $?`
global_status=`get_global_status $global_status $pvscan_present`

sudo $era_sudo_script which vgdisplay > /dev/null 2>&1
vgdisplay_present=`check_error $?`
global_status=`get_global_status $global_status $vgdisplay_present`

sudo $era_sudo_script which vgcreate > /dev/null 2>&1
vgcreate_present=`check_error $?`
global_status=`get_global_status $global_status $vgcreate_present`

sudo $era_sudo_script which vgscan > /dev/null 2>&1
vgscan_present=`check_error $?`
global_status=`get_global_status $global_status $vgscan_present`

which rsync > /dev/null 2>&1
rsync_present=`check_error $?`
global_status=`get_global_status $global_status $rsync_present`

sudo $era_sudo_script which lsof > /dev/null 2>&1
lsof_present=`check_error $?`
global_status=`get_global_status $global_status $lsof_present`

echo ""
echo ""
echo "--------------------------------------------------------------------"
echo "|              Era Pre-requirements Validation Report              |"
echo "--------------------------------------------------------------------"

echo ""
echo "$indent1 General Checks:"
echo "$indent1 ---------------"
echo "$indent2 1] Username           :" $user
echo "$indent2 2] Package manager    :" $package_manager
echo "$indent2 2] Database type      :" $database_type

echo ""
echo "$indent1 Era Configuration Dependencies:"
echo "$indent1 -------------------------------"
echo "$indent2 1] User has sudo access                         :" $sudo_access
echo "$indent2 2] User has sudo with NOPASS access             :" $sudo_access
echo "$indent2 3] Crontab configured for user                  :" $crontab_configured
echo "$indent2 4] Secure paths configured in /etc/sudoers file :" $secure_paths_configured
if [ ! -z "$prism_connectivity" ]; then
    echo "$indent2 5] Prism API connectivity                       :" $prism_connectivity
fi

echo ""
echo "$indent1 Era Software Dependencies:"
echo "$indent1 --------------------------"
echo "$indent2  1] GCC                  :" $gcc_present
echo "$indent2  2] readline             :" $readline_present
echo "$indent2  3] libselinux-python    :" $libselinux_present
echo "$indent2  4] crontab              :" $crontab_present
echo "$indent2  5] lvcreate             :" $lvcreate_present
echo "$indent2  6] lvscan               :" $lvscan_present
echo "$indent2  7] lvdisplay            :" $lvdisplay_present
echo "$indent2  8] vgcreate             :" $vgcreate_present
echo "$indent2  9] vgscan               :" $vgscan_present
echo "$indent2 10] vgdisplay            :" $vgdisplay_present
echo "$indent2 11] pvcreate             :" $pvcreate_present
echo "$indent2 12] pvscan               :" $pvscan_present
echo "$indent2 13] pvdisplay            :" $pvdisplay_present
echo "$indent2 14] zip                  :" $zip_present
echo "$indent2 15] unzip                :" $unzip_present
echo "$indent2 16] rsync                :" $rsync_present
echo "$indent2 17] bc                   :" $bc_present
echo "$indent2 18] sshpass              :" $sshpass_present
echo "$indent2 19] ksh                  :" $ksh_present
echo "$indent2 20] lsof                 :" $lsof_present
echo "$indent2 21] tar                  :" $tar_present
echo "$indent2 22] xfsprogs             :" $xfsprogs_present
echo "$indent2 23] ifupdown             :" $ifupdown_present
echo "$indent2 24] net-tools            :" $net_tools_present
echo "$indent2 25] nftables             :" $nftables_present
echo ""
echo "$indent1 Summary:"
echo "$indent1 --------"
if [ "$global_status" = $SUCCESS ]; then
    echo "$indent2 This machine satisfies dependencies required by Era, it can be onboarded."
else
    echo "$indent2 This machine does not satisfy all of the dependencies required by Era."
    echo "$indent2 It can not be onboarded to Era unless all of these are satisfied."
    if [ "$show_detailed" = $FALSE ]; then
        echo ""
        echo "$indent2 Note: You can run this script using '$DETAILS' option to know the complete details"
    fi
fi

if [ "$warn_curl" = "$TRUE" ]; then
    echo
    echo "$indent1 **WARNING: Curl was not found on the device. Couldn't go ahead with the Prism API connectivity check."
    echo "$indent1 Please ensure Prism APIs are callable from the host."
fi

if [ "$skip_cluster_check" = "$TRUE" ]; then
    echo
    echo "$indent1 **WARNING: Cluster API was not provided. Couldn't go ahead with the Prism API connectivity check."
    echo "$indent1 Please ensure Prism APIs are callable from the host."
fi

if [ "$global_status" = $FAIL ] && [ "$show_detailed" = $TRUE ]; then
    echo ""
    echo ""
    echo "$indent1 --------"
    echo "$indent1 Details:"
    echo "$indent1 --------"

    # configuration details
    if [ $sudo_access = $NO ]; then
        echo ""
        echo "$indent2  sudo access ($CONFIG_DEP):"
        echo "$indent2     - The Era user on dbserver VM needs to have sudo access enabled"
    fi

    # NOPASS is already covered as part of sudo access. This is a placeholder check
    if [ $sudo_access = $NO ]; then
        echo ""
        echo "$indent2  sudo with NOPASS access ($CONFIG_DEP):"
        echo "$indent2     - The Era user on dbserver VM needs to have sudo with NOPASS enabled"
    fi

    if [ $crontab_configured = $NO ]; then
        echo ""
        echo "$indent2  Crontab for user ($CONFIG_DEP):"
        echo "$indent2     - The crontab should be enabled for the Era user as the Era daemon gets"
        echo "$indent2       installed as a cronjob process."
    fi

    if [ $secure_paths_configured = $NO ]; then
        echo ""
        echo "$indent2  Secure paths in /etc/sudoers ($CONFIG_DEP):"
        echo "$indent2     - The binary source directory paths for all the Era dependencies (lvcreate,"
        echo "$indent2       pvcreate, lvsca, etc.) must be updated in the /etc/sudoers file so that"
        echo "$indent2       they can be accessed remotely"
    fi

    if [ $prism_connectivity = $NO ]; then
        echo ""
        echo "$indent2  Prism API connectivity ($CONFIG_DEP):"
        echo "$indent2     - Prism APIs must be reachable for era software to work."
    fi

    # software dependency details
    if [ $gcc_present = $NO ]; then
        echo ""
        echo "$indent2  GCC ($SOFTWARE_DEP):"
        echo "$indent2     - The GCC system package is required to build and install the cx_oracle pip "
        echo "$indent2       package in Era shippable stack (required only for $ORACLE_DB)"
        install_package_help $gcc
    fi

    if [ $bc_present = $NO ]; then
        echo ""
        echo "$indent2  $bc ($SOFTWARE_DEP):"
        echo "$indent2     - The $bc system package is required to support ansible execution of "
        echo "$indent2       Database Provisioning and Cloning (required only for $ORACLE_DB)"
        install_package_help $bc
    fi

    if [ $sshpass_present = $NO ]; then
        echo ""
        echo "$indent2  $sshpass ($SOFTWARE_DEP):"
        echo "$indent2     - The $sshpass system package is required to support ansible execution of "
        echo "$indent2       Cluster Database Patching and Creating Standby Database (required only for $ORACLE_DB)"
        install_package_help $sshpass
    fi

    if [ $ksh_present = $NO ]; then
        echo ""
        echo "$indent2  $ksh ($SOFTWARE_DEP):"
        echo "$indent2     - The $ksh system package is required to support ansible execution of "
        echo "$indent2       Cluster Database Provisioning (required only for $ORACLE_DB)"
        install_package_help $ksh
    fi

    if [ $readline_present = $NO ]; then
        echo ""
        echo "$indent2  $readline ($SOFTWARE_DEP):"
        echo "$indent2     - The $readline system package is required to support the auto-complete feature"
        echo "$indent2       of Era command line interface"
        install_package_help $readline
    fi

    if [ $tar_present = $NO ]; then
        echo ""
        echo "$indent2  tar ($SOFTWARE_DEP):"
        echo "$indent2     - The tar system package is required to untar packages"
        echo "$indent2       of Era command line interface"
        install_package_help "tar"
    fi

    if [ $xfsprogs_present = $NO ]; then
        echo ""
        echo "$indent2  xfsprogs ($SOFTWARE_DEP):"
        echo "$indent2     - The xfsprogs system package is required to support file creation for MongoDB for Ubuntu/Debian OS"
        echo "$indent2       of Era command line interface"
        install_package_help "xfsprogs"
    fi

    if [ $nftables_present = $NO ]; then
        echo ""
        echo "$indent2  nftables ($SOFTWARE_DEP):"
        echo "$indent2     - The nftables system package is required to enable postgres HA"
        echo "$indent2       of Era command line interface"
        install_package_help "nftables"
    fi

    if [ $ifupdown_present = $NO ]; then
        echo ""
        echo "$indent2  ifupdown ($SOFTWARE_DEP):"
        echo "$indent2     - The ifupdown system package is required to improve IP configuration for Ubuntu/Debian OS"
        echo "$indent2       of Era command line interface"
        install_package_help "ifupdown"
    fi

    if [ $net_tools_present = $NO ]; then
        echo ""
        echo "$indent2  net-tools ($SOFTWARE_DEP):"
        echo "$indent2     - The net-tools system package is required to improve IP configuration for Ubuntu/Debian OS"
        echo "$indent2       of Era command line interface"
        install_package_help "net-tools"
    fi

    if [ $libselinux_present = $NO ]; then
        echo ""
        echo "$indent2  $libselinux_python ($SOFTWARE_DEP):"
        echo "$indent2     - The $libselinux_python system package is required to support ansible execution"
        install_package_help $libselinux_python_rhel $libselinux_python_ubuntu
    fi

    if [ $crontab_present = $NO ]; then
        echo ""
        echo "$indent2  $crontab ($SOFTWARE_DEP):"
        echo "$indent2     - The $crontab system utility is required to start Era Agent daemon on dbserver"
        install_package_help $crontab
    fi

    if [ $lvcreate_present = $NO ]; then
        echo ""
        echo "$indent2  $lvcreate ($SOFTWARE_DEP):"
        echo "$indent2     - The $lvcreate system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $lvscan_present = $NO ]; then
        echo ""
        echo "$indent2  $lvscan ($SOFTWARE_DEP):"
        echo "$indent2     - The $lvscan system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $lvdisplay_present = $NO ]; then
        echo ""
        echo "$indent2  $lvdisplay ($SOFTWARE_DEP):"
        echo "$indent2     - The $lvdisplay system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $vgcreate_present = $NO ]; then
        echo ""
        echo "$indent2  $vgcreate ($SOFTWARE_DEP):"
        echo "$indent2     - The $vgcreate system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $vgscan_present = $NO ]; then
        echo ""
        echo "$indent2  $vgscan ($SOFTWARE_DEP):"
        echo "$indent2     - The $vgscan system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $vgdisplay_present = $NO ]; then
        echo ""
        echo "$indent2  $vgdisplay ($SOFTWARE_DEP):"
        echo "$indent2     - The $vgdisplay system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $pvcreate_present = $NO ]; then
        echo ""
        echo "$indent2  $pvcreate ($SOFTWARE_DEP):"
        echo "$indent2     - The $pvcreate system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $pvscan_present = $NO ]; then
        echo ""
        echo "$indent2  $pvscan ($SOFTWARE_DEP):"
        echo "$indent2     - The $pvscan system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $pvdisplay_present = $NO ]; then
        echo ""
        echo "$indent2  $pvdisplay ($SOFTWARE_DEP):"
        echo "$indent2     - The $pvdisplay system utility is required to manage Era related LVM setups on dbserver"
        install_package_help $lvm2
    fi

    if [ $unzip_present = $NO ]; then
        echo ""
        echo "$indent2  $unzip ($SOFTWARE_DEP):"
        echo "$indent2     - The $unzip system utility is required to unzip the Era installation bundles"
        install_package_help $unzip
    fi

    if [ $zip_present = $NO ]; then
        echo ""
        echo "$indent2  $zip ($SOFTWARE_DEP):"
        echo "$indent2     - The $zip system utility is required to zip the Era diagnostic bundles"
        install_package_help $unzip
    fi

    if [ $rsync_present = $NO ]; then
        echo ""
        echo "$indent2  $rsync ($SOFTWARE_DEP):"
        echo "$indent2     - The $rsync system utility is required to copy contents for Software Profile Creation"
        install_package_help $rsync
    fi
    echo ""

    if [ $lsof_present = $NO ]; then
        echo ""
        echo "$indent2  $lsof ($SOFTWARE_DEP):"
        echo "$indent2     - The $lsof system utility is required to list open-files on the mount-points created by ERA"
        install_package_help $lsof
    fi
    echo ""
    if [ $xfsprogs_present = $NO ]; then
        echo ""
        echo "$indent2  $xfsprogs_mongodb_ubuntu_debian ($SOFTWARE_DEP):"
        echo "$indent2     - The $xfsprogs_mongodb_ubuntu_debian system utility is required to mount file systems"
        install_package_help $xfsprogs_mongodb_ubuntu_debian
    fi
    echo ""
    if [ $ifupdown_present = $NO ]; then
        echo ""
        echo "$indent2  $ifupdown_ubuntu ($SOFTWARE_DEP):"
        echo "$indent2     - The $ifupdown_ubuntu system utility is required for network setup"
        install_package_help $ifupdown_ubuntu
    fi
    echo ""
    if [ $net_tools_present = $NO ]; then
        echo ""
        echo "$indent2  $net_tools_ubuntu ($SOFTWARE_DEP):"
        echo "$indent2     - The $net_tools_ubuntu system utility is required for network setup"
        install_package_help $net_tools_ubuntu
    fi
    echo ""
    if [ $nftables_present = $NO ]; then
        echo ""
        echo "$indent2  $nftables_ubuntu ($SOFTWARE_DEP):"
        echo "$indent2     - The $nftables_ubuntu system utility is required for filtering ingress and egress traffic to the VM"
        install_package_help $nftables_ubuntu
    fi
    echo ""
fi
echo "=================================="

# Below block is for internal use only
if [ "$is_era_server_call" = $TRUE ]; then
    echo $internal_message
    echo $internal_debug_message
    echo "$CONFIG"$DEBUG_DELIM"sudo_access"$DEBUG_DELIM"$sudo_access"$DEBUG_DELIM"Make sure the user '$user' has sudo access"
    echo "$CONFIG"$DEBUG_DELIM"sudo_nopass_access"$DEBUG_DELIM"$sudo_access"$DEBUG_DELIM"Make sure the user '$user' has sudo NOPASS access"
    echo "$CONFIG"$DEBUG_DELIM"crontab"$DEBUG_DELIM"$crontab_configured"$DEBUG_DELIM"Make sure crontab is configured for the user"
    echo "$CONFIG"$DEBUG_DELIM"secure_paths"$DEBUG_DELIM"$secure_paths_configured"$DEBUG_DELIM"Make sure the binary paths are configured as 'secure_paths' in the /etc/sudoers file"
    if [ ! -z "$prism_connectivity" ]; then
        echo "$CONFIG"$DEBUG_DELIM"prism_connectivity"$DEBUG_DELIM"$prism_connectivity"$DEBUG_DELIM"Make sure Prism APIs care callable from the VM"
    fi

    echo "$SOFTWARE"$DEBUG_DELIM"gcc"$DEBUG_DELIM"$gcc_present"$DEBUG_DELIM"Make sure gcc system package is installed on the VM. You can try 'sudo $package_manager install gcc -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"readline"$DEBUG_DELIM"$readline_present"$DEBUG_DELIM"Make sure readline system package is installed on the VM. You can try 'sudo $package_manager install readline -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"libselinux-python"$DEBUG_DELIM"$libselinux_present"$DEBUG_DELIM"Make sure libselinux_python is installed on the VM."
    echo "$SOFTWARE"$DEBUG_DELIM"unzip"$DEBUG_DELIM"$unzip_present"$DEBUG_DELIM"Make sure unzip system package is installed on the VM. You can try 'sudo $package_manager install unzip -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"zip"$DEBUG_DELIM"$zip_present"$DEBUG_DELIM"Make sure zip system package is installed on the VM. You can try 'sudo $package_manager install zip -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"crontab"$DEBUG_DELIM"$crontab_present"$DEBUG_DELIM"Make sure crontab system package is installed on the VM. You can try 'sudo $package_manager install crontab -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"lvcreate"$DEBUG_DELIM"$lvcreate_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"lvscan"$DEBUG_DELIM"$lvscan_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"lvdisplay"$DEBUG_DELIM"$lvdisplay_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"vgcreate"$DEBUG_DELIM"$vgcreate_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"vgscan"$DEBUG_DELIM"$vgscan_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"vgdisplay"$DEBUG_DELIM"$vgdisplay_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"pvcreate"$DEBUG_DELIM"$pvcreate_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"pvscan"$DEBUG_DELIM"$pvscan_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"pvdisplay"$DEBUG_DELIM"$pvdisplay_present"$DEBUG_DELIM"Make sure lvm system packages are installed on the VM. You can try 'sudo $package_manager install lvm2 -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"rsync"$DEBUG_DELIM"$rsync_present"$DEBUG_DELIM"Make sure rsync system packages are installed on the VM. You can try 'sudo $package_manager install rsync -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"bc"$DEBUG_DELIM"$bc_present"$DEBUG_DELIM"Make sure bc system package is installed on the VM. You can try 'sudo $package_manager install bc -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"sshpass"$DEBUG_DELIM"$sshpass_present"$DEBUG_DELIM"Make sure sshpass system package is installed on the VM. You can try 'sudo $package_manager install sshpass -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"ksh"$DEBUG_DELIM"$ksh_present"$DEBUG_DELIM"Make sure ksh system package is installed on the VM. You can try 'sudo $package_manager install ksh -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"lsof"$DEBUG_DELIM"$lsof_present"$DEBUG_DELIM"Make sure lsof system package is installed on the VM. You can try 'sudo $package_manager install lsof -y' to install it"
    echo "$SOFTWARE"$DEBUG_DELIM"xfsprogs"$DEBUG_DELIM"$xfsprogs_present"$DEBUG_DELIM"Make sure xfsprogs system package is installed on the VM. You can try 'sudo $package_manager install xfsprogs -y' to install it"$DEBUG_DELIM"Required"
    echo "$SOFTWARE"$DEBUG_DELIM"ifupdown"$DEBUG_DELIM"$ifupdown_present"$DEBUG_DELIM"Make sure ifupdown system package is installed on the VM. You can try 'sudo $package_manager install ifupdown -y' to install it"$DEBUG_DELIM"Required"
    echo "$SOFTWARE"$DEBUG_DELIM"net-tools"$DEBUG_DELIM"$net_tools_present"$DEBUG_DELIM"Make sure net-tools system package is installed on the VM. You can try 'sudo $package_manager install net-tools -y' to install it"$DEBUG_DELIM"Required"
    echo "$SOFTWARE"$DEBUG_DELIM"nftables"$DEBUG_DELIM"$nftables_present"$DEBUG_DELIM"Make sure nftables system package is installed on the VM. You can try 'sudo $package_manager install nftables -y' to install it"$DEBUG_DELIM"Required"
    echo "===================================================================="
fi

if [ "$database_type" != "oracle_database" ] && [ "$global_status" != $SUCCESS ]; then
    exit 1
fi
