#!/bin/bash

set -e

GREEN='\033[0;32m'
NC='\033[0m'

echo
echo -e "${GREEN}--- Configuración del host ---${NC}"
./host_config.sh

echo
echo -e "${GREEN}--- Despliegue de la máquina virtual para OpenStack ---${NC}"
./vm_deployment.sh

echo
echo -e "${GREEN}--- ENTORNO LISTO ---${NC}"