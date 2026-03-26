#!/bin/bash
# prep-openstack-env.sh
# Preparacion del entorno OpenStack tras restaurar snapshot KVM

# ─── Verificar que se ejecuta con source ────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo ""
  echo "Este script debe ejecutarse con source para aplicar las variables de entorno:"
  echo ""
  echo "      source ./$(basename "$0")"
  echo ""
  exit 1
fi

set -e

# ─── Colores ────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ─── Variables configurables ────────────────────────────
IMAGES_DIR="$PWD"
CLOUDS_YAML="$HOME/.config/openstack/clouds.yaml"
KEYPAIR_NAME="my_host_key"
PUBLIC_KEY="$HOME/.ssh/id_rsa.pub"

# ─── Variables clouds.yaml ──────────────────────────────
AUTH_URL="http://192.168.122.214/openstack-keystone/v3"
USERNAME="admin"
PROJECT_ID="21cb42aba25a4b6d81098bb6f8521dfc"
PROJECT_NAME="admin"
USER_DOMAIN_NAME="admin_domain"
REGION="RegionOne"
INTERFACE="public"

# ─── Activar cloud ──────────────────────────────────────
export OS_CLOUD=openstack

if ! grep -q 'export OS_CLOUD=openstack' ~/.bashrc; then
  echo 'export OS_CLOUD=openstack' >> ~/.bashrc
fi

# ─── Clouds.yaml ────────────────────────────────────────
if [ ! -f "$CLOUDS_YAML" ]; then
    echo -e "${GREEN}==> Creando directorio ~/.config/openstack/...${NC}"
    mkdir -p ~/.config/openstack

    echo -e "${GREEN}==> Creando clouds.yaml...${NC}"
    cat > "$CLOUDS_YAML" << EOF
clouds:
  openstack:
    auth:
      auth_url: $AUTH_URL
      username: "$USERNAME"
      password: ""
      project_id: $PROJECT_ID
      project_name: "$PROJECT_NAME"
      user_domain_name: "$USER_DOMAIN_NAME"
    regions:
    - $REGION
    interface: "$INTERFACE"
    identity_api_version: 3
EOF
else
    echo -e "${GREEN}==> clouds.yaml ya existe en $CLOUDS_YAML${NC}"
fi

# ─── Comprobacion password ──────────────────────────────
PASSWORD_VALUE=$(grep 'password:' "$CLOUDS_YAML" | awk -F'"' '{print $2}')

if [ -z "$PASSWORD_VALUE" ]; then
    echo ""
    echo -e "${YELLOW}ATENCION: El campo password esta vacio${NC}"
    read -s -p "Introduce la password de OpenStack: " PASSWORD_INPUT
    echo ""
    sed -i "s/password: \"\"/password: \"$PASSWORD_INPUT\"/" "$CLOUDS_YAML"
    echo -e "${GREEN}Password guardada en $CLOUDS_YAML${NC}"
else
    echo -e "${GREEN}==> Password ya configurada en clouds.yaml${NC}"
fi

# ─── Keypair ────────────────────────────────────────────
if openstack keypair show "$KEYPAIR_NAME" &>/dev/null; then
    echo -e "${GREEN}==> Keypair '$KEYPAIR_NAME' ya existe${NC}"
else
    echo -e "${GREEN}==> Importando keypair...${NC}"
    openstack keypair create --public-key "$PUBLIC_KEY" "$KEYPAIR_NAME"
    echo -e "${GREEN}==> Keypair '$KEYPAIR_NAME' importado correctamente${NC}"
fi

echo -e "${GREEN}==> Verificando keypair...${NC}"
openstack keypair list

# ─── Imagenes ───────────────────────────────────────────
echo ""
echo -e "${GREEN}==> Buscando imagenes en $IMAGES_DIR...${NC}"

# Busca ficheros .qcow2 e .img en el directorio
IMAGE_FILES=()
while IFS= read -r -d '' file; do
    IMAGE_FILES+=("$file")
done < <(find "$IMAGES_DIR" -maxdepth 1 \( -name "*.qcow2" -o -name "*.img" \) -print0)

if [ ${#IMAGE_FILES[@]} -eq 0 ]; then
    echo -e "${YELLOW}    No se encontraron imagenes .qcow2 o .img en $IMAGES_DIR${NC}"
else
    echo -e "${GREEN}    Se encontraron ${#IMAGE_FILES[@]} imagen(es)${NC}"
    echo ""

    for IMAGE_FILE in "${IMAGE_FILES[@]}"; do
        FILENAME=$(basename "$IMAGE_FILE")
        SUGGESTED_NAME="${FILENAME%.*}"

        read -p "    Subir '$FILENAME'? (s/n): " UPLOAD
        if [[ "$UPLOAD" =~ ^[Ss]$ ]]; then
            read -p "    Nombre en OpenStack [$SUGGESTED_NAME]: " IMAGE_NAME
            IMAGE_NAME="${IMAGE_NAME:-$SUGGESTED_NAME}"

            case "${FILENAME##*.}" in
                qcow2) DISK_FORMAT="qcow2" ;;
                img)   DISK_FORMAT="raw"   ;;
            esac

            # Comprueba si ya existe una imagen con ese fichero original
            EXISTING_ID=$(openstack image list --property original_filename="$FILENAME" -f value -c ID 2>/dev/null)

            if [ -n "$EXISTING_ID" ]; then
                echo -e "${YELLOW}    '$FILENAME' ya fue subida anteriormente, saltando...${NC}"
            else
                echo -e "${GREEN}==> Subiendo $FILENAME como '$IMAGE_NAME' (formato: $DISK_FORMAT)...${NC}"
                openstack image create "$IMAGE_NAME" \
                    --file "$IMAGE_FILE" \
                    --disk-format "$DISK_FORMAT" \
                    --container-format bare \
                    --property original_filename="$FILENAME" \
                    --public

                echo -e "${GREEN}    Imagen '$IMAGE_NAME' subida correctamente${NC}"
            fi
        else
            echo -e "${YELLOW}    Saltando $FILENAME${NC}"
        fi
        echo ""
    done
fi

echo -e "${GREEN}==> Verificando imagenes en OpenStack...${NC}"
openstack image list

echo ""
echo -e "${GREEN}==> Entorno listo, ya puedes lanzar terraform apply${NC}"