#!/bin/bash

TC_VERSION="1.0.0" # Dont edit!

# --- CONFIG: User can edit --- #
export TC_ROOT="$(pwd)"
export TC_MOUNTDIR="$TC_ROOT/mntpoint"
export TC_WORK_DIR="$TC_MOUNTDIR/.../.tc"
export TC_LOCALSTORAGE="$TC_WORK_DIR/localStorage"
export TC_BLOCKED_USERS_LIST="$TC_LOCALSTORAGE/blocked.users"
export TC_FRIENDS_LIST="$TC_LOCALSTORAGE/friends.users"
export TC_SERVER_LOCATION="$TC_LOCALSTORAGE/servers"
export TC_VDRIVE_NAME="tc_virtual"
export TC_SETUP_ACKNOWLEDGE="$TC_WORK_DIR/.tc_setup.ack"
export TC_COMMAND_DIR="$TC_LOCALSTORAGE/commands"
export TC_TMP="$TC_WORK_DIR/temp"
export TC_PROBE_ACKNOWLEDGE="$TC_WORK_DIR/.tc_noprobe.ack"
# --- End Config --- #

function post_error_actions {
    echo "EXEC: sudo umount $TC_MOUNTDIR"
    sudo umount $TC_MOUNTDIR
}

function error {
    echo -e "\n[TC_MAIN / ERROR]\n\tCalledBy: '$1'\n\tErrorReported: '$2'\nTermChat cannot continue."
    echo -e "\nRunning post_error_actions before an exit...\n"
    post_error_actions
    exit 1
}

function virtual_drive_create {
    if test -f "./$TC_VDRIVE_NAME"; then
        error "TC_VDRIVE_CREATE" "A virtual drive or a file of the same name exists."
    fi
    dd if=/dev/zero of=$TC_VDRIVE_NAME bs=1M count=2048 &> /dev/null || error "TC_VDRIVE_CREATE" "Fault on Command 1 of 2: 'DD' failed to create a disk."
    mkfs.ext4 tc_virtual &> /dev/null || error "TC_VDRIVE_CREATE" "Fault on Command 2 of 2: 'MKFS.EXT4' failed to format the virtual disk."
}

function TC_CONFIG {
    sudo chmod 777 -R $TC_MOUNTDIR/
    mkdir $TC_MOUNTDIR/...
    mkdir $TC_WORK_DIR
    mkdir $TC_TMP
    mkdir $TC_LOCALSTORAGE
    mkdir $TC_COMMAND_DIR
    touch $TC_BLOCKED_USERS_LIST
    touch $TC_FRIENDS_LIST
    mkdir $TC_SERVER_LOCATION
    touch $TC_SETUP_ACKNOWLEDGE
}

function TC_RAND {
    RAND=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-5} | head -n 1)
}

function downloadCommands {
    TC_RAND
    echo "Contacting Server: $1 ..."
    wget -q $1/termchat-$TC_VERSION/allcommands.tgz > $TC_TMP/$RAND.tgz || echo "[!] Could not contact server"; return
    echo "Extracting commands from $TC_TMP/$RAND.tgz..."
    tar -xvf $TC_TMP/$RAND -C $TC_COMMAND_DIR/
    echo "Commands seemed to have installed. If they are not present, most likely the server you contacted does not hosted the allcommands.tgz file and you just downloaded a 404 HTML page."
}

function PROMPT {
    read -p "tc > " COMMAND

    if [[ $COMMAND == "exit" || $COMMAND == "bye" ]]; then
        post_error_actions
        echo -e "\nBye!"
        exit 0
    fi

    if [[ $COMMAND == "dC" || $COMMAND == "downloadCommands" ]]; then
        read -p "Enter IP of server to retrieve commands from: " SERVER
        downloadCommands "$SERVER"
        PROMPT
    fi

    if [[ $(echo $COMMAND | head -n1) == "" ]]; then
        PROMPT
    fi

    if test -f "$TC_COMMAND_DIR/$(echo $COMMAND | head -n1 | awk '{print $1;}')"; then
        $TC_COMMAND_DIR/$COMMAND || error "TC_PROMPT" "Command Execution Error: Check for any errors above."
        PROMPT
    else
        echo "[!] Unknown command ($(echo $COMMAND | head -n1 | awk '{print $1;}'))."
        PROMPT
    fi
}

function TC_PROBE {
    wget --version &> /dev/null || error "TC_PROBE" "Please install 'wget'"
    curl --version &> /dev/null || error "TC_PROBE" "Please install 'curl'"
    whiptail --version &> /dev/null || error "TC_PROBE" "Please install 'whiptail'"
    touch $TC_PROBE_ACKNOWLEDGE
}

echo "TermChat (VERSION: $TC_VERSION). Starting..."
echo -e "\t[1]: Detect virtual drive..."

if test -f "./$TC_VDRIVE_NAME"; then
    echo -e "\t\tVirtual Drive Found!"
    mkdir -p $TC_MOUNTDIR
else
    echo -e "\t\tVirtual Drive not found, creating one..."
    echo -ne "\nCreating virtual drive ... working\\t"
    virtual_drive_create
    echo "Creating virtual drive ... successful"
    echo "Please restart TermChat to continue!"
    exit 0
fi

echo -e "\t[2]: Mount Virtual Drive"
echo -e "\t\tExec: sudo mount ./$TC_VDRIVE_NAME $TC_MOUNTDIR"
sudo mount ./$TC_VDRIVE_NAME $TC_MOUNTDIR || error "TC_MOUNT" "The command failed unexpectedly, likely a configuration issue."

echo -e "\t[3]: Check for installation acknowledgement"
if test -f "$TC_SETUP_ACKNOWLEDGE"; then
    echo -e "\t\tTermChat is setup! Running from config..."
else
    echo -e "\t\tTermChat is not setup! Running TC_CONFIG ..."
    TC_CONFIG || error "TC_BOOT" "The command 'TC_CONFIG' failed unexpectedly."
fi

echo -e "\t[4]: Probing modules..."
if test -f "$TC_PROBE_ACKNOWLEDGE"; then
    echo -e "\t\tProbing is skipped due to an acknowledgement file present. This is not an error."
else
    echo -e "\t\tProbing modules..."
    TC_PROBE || error "TC_BOOT" "The command 'TC_PROBE' failed unexpectedly."
    echo -e "\t\tDone!"
fi

echo -e "\nTermChat $TC_VERSION : Ready!"
PROMPT