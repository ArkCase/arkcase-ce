#!/bin/bash -e

usage() {
    echo "Usage: -i /path/to/iso/image -n vm-base-name -m memory (in MB) -s disk-space (in MB) -c cpu-count"
    exit 1
    
}

while getopts ":i:n:m:s:c:h" opt; do
    case ${opt} in
        i )
            ISO_FILE=$OPTARG
            ;;
        n )
            VM_BASE_NAME=$OPTARG
            ;;
        m )
            MEMORY=$OPTARG
            ;;
        s )
            HDD_SIZE=$OPTARG
            ;;
        c )
            CPUS=$OPTARG
            ;;
        h )
            usage
            ;;
        \? )
            echo "Unknown option: -$OPTARG" >&2 ; usage
            ;;
        : )
            echo "Missing argument for -$OPTARG" >&2 ; usage
            ;;
    esac
done

if [ "" == "$ISO_FILE" ] ||
       [ "" == "$VM_BASE_NAME" ] ||
       [ "" == "$MEMORY" ] ||
       [ "" == "$HDD_SIZE" ] ||
       [ "" == "$CPUS" ];
then
    usage
fi


# Get the working directory for a script, no matter where it's executed from!
_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

VM_NAME=$VM_BASE_NAME-$(date +%Y%m%d-%H%M%S)

OS_TYPE=RedHat_64
VIDEO_RAM=33
AUDIO=none

VM_MACHINE_BASE_PATH=$(VBoxManage list systemproperties | sed -n 's/Default machine folder: *//p')
VM_MACHINE_PATH=$VM_MACHINE_BASE_PATH/$VM_NAME

HDD_PATH=$VM_MACHINE_PATH/$VM_NAME.vdi

FIRST_HOST_NET=$(vboxmanage list hostonlyifs | grep ^Name | head -1 | sed -n 's/Name: *//p')

echo name: $VM_NAME
echo path: $VM_MACHINE_PATH
echo disk path: $HDD_PATH
echo iso: $ISO_FILE
echo RAM: $MEMORY
echo disk size: $HDD_SIZE
echo cpus: $CPUS
echo host-only net: $FIRST_HOST_NET

vboxmanage createvm --name "$VM_NAME" --ostype $OS_TYPE --basefolder "$VM_MACHINE_PATH" --register

# Set memory, vram, audio and vdre port range
vboxmanage modifyvm "$VM_NAME" --memory $MEMORY --vram $VIDEO_RAM --acpi on --ioapic on --cpus $CPUS --cpuexecutioncap 75 --rtcuseutc on --cpuhotplug on --pae on --hwvirtex on
vboxmanage modifyvm "$VM_NAME" --nic1 nat --cableconnected1 on
vboxmanage modifyvm "$VM_NAME" --nic2 hostonly --hostonlyadapter2 $FIRST_HOST_NET  --cableconnected2 on
vboxmanage modifyvm "$VM_NAME" --audio $AUDIO
vboxmanage modifyvm "$VM_NAME" --usb on
 
# Create and attach HDD and SATA controller
vboxmanage createmedium disk --filename "$HDD_PATH" --size $HDD_SIZE --format VDI 
vboxmanage storagectl "$VM_NAME" --name "SATA controller" --add sata
vboxmanage storageattach "$VM_NAME" --storagectl "SATA controller" --port 0 --device 0 --type hdd --medium "$HDD_PATH"

# clipboard
vboxmanage modifyvm "$VM_NAME" --clipboard bidirectional
 
# Create IDE controller and attach DVD
vboxmanage storagectl "$VM_NAME" --name "IDE controller" --add ide
vboxmanage storageattach "$VM_NAME" --storagectl "IDE controller"  --port 0 --device 0 --type dvddrive --medium "$ISO_FILE"






