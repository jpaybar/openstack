#!/bin/bash

set -e

echo
echo "Preparando entorno del host para laboratorio OpenStack..."

VM_IP="192.168.122.250"
FLOATING_NET="172.20.0.0/24"
VM_HOST="openstack-vm"
VM_SCRIPT="vm_deployment.sh"

SSH_KEY="$HOME/.ssh/id_rsa"
SSH_PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"
SSH_CONFIG="$HOME/.ssh/config"

TEMPLATE="user-data.template.yaml"
CLOUD_INIT="user-data.yaml"

HOOK_FILE="/etc/libvirt/hooks/network"

echo
echo "-----------------------------"
echo "1. Comprobando claves SSH"
echo "-----------------------------"

if [ ! -f "$SSH_KEY" ]; then
    echo "Generando clave SSH..."
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" -C "jpaybar@SysOps"
else
    echo "La clave SSH ya existe"
fi

echo
echo "-----------------------------"
echo "1.1 Generando user-data.yaml"
echo "-----------------------------"

SSH_KEY_CONTENT=$(cat "$SSH_PUBLIC_KEY")
sed "s|__SSH_KEY__|$SSH_KEY_CONTENT|" "$TEMPLATE" > "$CLOUD_INIT"

echo "user-data.yaml generado correctamente"

echo
echo "-----------------------------"
echo "2. Configurando ~/.ssh/config"
echo "-----------------------------"

touch "$SSH_CONFIG"

if ! grep -q "Host $VM_HOST" "$SSH_CONFIG"; then

cat <<EOF >> "$SSH_CONFIG"

Host $VM_HOST
    HostName $VM_IP
    User ubuntu
    IdentityFile $SSH_KEY
    StrictHostKeyChecking no
EOF

echo "Entrada añadida a ~/.ssh/config"

else
    echo "La entrada ya existe en ~/.ssh/config"
fi

chmod 600 "$SSH_CONFIG"

echo
echo "-----------------------------"
echo "3. Instalando hook de red libvirt"
echo "-----------------------------"

sudo mkdir -p /etc/libvirt/hooks

sudo tee "$HOOK_FILE" > /dev/null <<'EOF'
#!/bin/bash

NET_NAME="default"
INSTANCES_SUBNET="172.20.0.0/24"
VM_GATEWAY="192.168.122.250"

NETWORK="$1"
EVENT="$2"

if [ "$NETWORK" = "$NET_NAME" ]; then

    if [ "$EVENT" = "started" ] || [ "$EVENT" = "restarted" ]; then

        if ! ip route show "$INSTANCES_SUBNET" | grep -q "$VM_GATEWAY"; then
            ip route add "$INSTANCES_SUBNET" via "$VM_GATEWAY"
            logger "Libvirt Hook: Ruta a instancias OpenStack ($INSTANCES_SUBNET) ACTIVADA."
        fi

    elif [ "$EVENT" = "stopped" ]; then

        ip route del "$INSTANCES_SUBNET" via "$VM_GATEWAY" 2>/dev/null
        logger "Libvirt Hook: Ruta a instancias OpenStack DESACTIVADA."

    fi

fi
EOF

sudo chmod +x "$HOOK_FILE"

echo "Hook de libvirt instalado correctamente en $HOOK_FILE"

echo
echo "-----------------------------"
echo "Entorno preparado"
echo "-----------------------------"
echo