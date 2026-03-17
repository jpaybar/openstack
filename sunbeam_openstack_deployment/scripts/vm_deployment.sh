#!/bin/bash

# VARS
IMG_DIR="/var/lib/libvirt/user-images/openstack"
IMG_NAME="noble-server-cloudimg-amd64.img"
CURRENT_DIR=$(pwd)
VM_NAME="openstack-vm"
USER_DATA="${CURRENT_DIR}/user-data.yaml"
VM_IP="192.168.122.250"

BASE_IMG="/var/lib/libvirt/user-images/openstack/noble-server-cloudimg-amd64.img"
VM_DISK="/var/lib/libvirt/user-images/openstack/${VM_NAME}_root.qcow2"
STORAGE_DISK="/var/lib/libvirt/user-images/openstack/${VM_NAME}_storage.qcow2"

# Detectar interfaz de red automáticamente
HOST_IFACE=$(ip route | grep default | awk '{print $5}')

# Recursos de la VM
VM_RAM="20480"
VM_CPU="8"

# Definición de colores
GREEN='\033[0;32m'
NC='\033[0m'

# --- FUNCIÓN DE AYUDA ---
mostrar_ayuda() {
    echo "-----------------------------------------------------------------------"
    echo " USO: $0 [OPCIONES]"
    echo "-----------------------------------------------------------------------"
    echo " DESCRIPCIÓN:"
    echo "   Despliega una MV limpia sobre el hipervisor KVM para instalar OpenStack"
    echo "   con Sunbeam."
    echo ""
    echo " REQUISITOS:"
    echo "   - Imagen base: $IMG_NAME"
    echo "   - Directorio:  $IMG_DIR"
    echo "   - El archivo 'user-data.yaml' debe estar en este directorio."
    echo ""
    echo " OPCIONES:"
    echo "   -h, --help    Muestra esta ayuda y sale."
    echo ""
    echo " NOTAS:"
    echo "   - La IP fija asignada será: $VM_IP"
    echo "-----------------------------------------------------------------------"
}

# 0. MENU AYUDA
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo
    mostrar_ayuda
    exit 0
fi

# Verificar que existe user-data.yaml
if [[ ! -f "$USER_DATA" ]]; then
    echo
    echo "ERROR: No se encuentra el archivo user-data.yaml"
    echo
    echo "Debe ejecutar primero el script:"
    echo "   ./host_config.sh"
    echo
    echo "Ruta esperada:"
    echo "   $USER_DATA"
    echo
    exit 1
fi

# Verificar que existe la imagen base
if [[ ! -f "$BASE_IMG" ]]; then
    echo
    echo "ERROR: No se encuentra la imagen base:"
    echo "$BASE_IMG"
    echo
    exit 1
fi

# 1. LIMPIEZA
echo
echo -e "${GREEN}--- Limpiando instancias previas ---${NC}"
virsh destroy $VM_NAME 2>/dev/null
virsh undefine $VM_NAME --remove-all-storage 2>/dev/null
rm -f $VM_DISK $STORAGE_DISK &>/dev/null
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$VM_IP" &>/dev/null

# 2. CREACIÓN DE DISCOS DIFERENCIALES
echo -e "${GREEN}--- Preparando discos ---${NC}"
qemu-img create -f qcow2 -b "$BASE_IMG" -F qcow2 "$VM_DISK" 200G
qemu-img create -f qcow2 "$STORAGE_DISK" 200G
echo

# 3. LANZAMIENTO DE LA MV
echo -e "${GREEN}--- Lanzando MV, Cloud-init en curso... ---${NC}"
virt-install \
  --name $VM_NAME \
  --memory $VM_RAM \
  --vcpus $VM_CPU \
  --cpu host-passthrough \
  --network network=default,model=virtio \
  --network type=direct,source=$HOST_IFACE,source_mode=bridge,model=virtio \
  --disk path="$VM_DISK",format=qcow2,bus=virtio,discard=unmap \
  --disk path="$STORAGE_DISK",format=qcow2,bus=virtio,discard=unmap \
  --cloud-init user-data="$USER_DATA" \
  --os-variant ubuntu24.04 \
  --graphics vnc,listen=0.0.0.0 \
  --noautoconsole \
  --wait 0

# 4. ESPERAMOS A TENER CONEXION SSH
echo
echo -e "${GREEN}--- Esperando conexion SSH ($VM_IP) ---${NC}"
until nc -z -w5 $VM_IP 22 2>/dev/null; do
  echo -n "."
  sleep 5
done

# 5. VERIFICACIÓN CLOUD-INIT
echo -e "${GREEN}--- Verificando Cloud-init ---${NC}"
while ! ssh -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no ubuntu@$VM_IP "cloud-init status" 2>/dev/null | grep -q "status: done"; do
  echo -n "."
  sleep 5
done

# 6. COPIAR MANIFEST
echo
echo -e "${GREEN}--- Copiando manifest_deployment.yaml ---${NC}"
scp -o StrictHostKeyChecking=no manifest_deployment.yaml ubuntu@$VM_IP:/home/ubuntu/

# RETIRAR CDROM DE CLOUD-INIT
echo
echo -e "${GREEN}--- Retirando dispositivo CDROM de cloud-init ---${NC}"

echo -e "${GREEN}Apagando la VM...${NC}"
virsh shutdown $VM_NAME

echo -e "${GREEN}Esperando a que la VM se apague...${NC}"
while [ "$(virsh domstate $VM_NAME)" != "shut off" ]; do
    sleep 3
done

echo -e "${GREEN}Eliminando CDROM de cloud-init...${NC}"
virsh detach-disk $VM_NAME sda --config

echo -e "${GREEN}Arrancando nuevamente la VM...${NC}"
virsh start $VM_NAME

# 7. INFO FINAL
echo
echo -e "${GREEN}--- DESPLIEGUE FINALIZADO ---${NC}"
echo -e "${GREEN}IP de la MV: $VM_IP${NC}"
echo -e "${GREEN}Interfaz de salida del host: $HOST_IFACE${NC}"
echo