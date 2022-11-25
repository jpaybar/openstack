## Inventarios Dinámicos de Ansible para Openstack (plugin)

By Juan Manuel Payán / jpaybar

st4rt.fr0m.scr4tch@gmail.com

Ansible admite dos formas de conectarse con el inventario externo: `plugins` y `scripts`. Ansible recomienda el uso de `plugins` en vez de `scripts`.

[openstack.cloud.openstack inventory – OpenStack inventory source — Ansible Documentation](https://docs.ansible.com/ansible/latest/collections/openstack/cloud/openstack_inventory.html)

```bash
ansible-doc -t inventory -l
```

```bash
ansible-doc -t inventory -l openstack
```

### Quickstart

Creamos un directorio donde tendremos los ficheros de inventario:

```bash
mkdir openstack-di
```

Creamos 2 ficheros, uno llamado `openstack.yml` que contendrá el `plugin` y la configuración del mismo y otro llamado `clouds.yaml`, este otro fichero incluirá la información de nuestros `clouds` y proyectos, asi como datos de la conexión a la API, auth_url, password, etc.

El fichero `clouds.yaml` lo podemos encontrar en la ruta `/etc/openstack/clouds.yaml` si tenemos acceso al nodo de computación.

#### Fichero `openstack.yml`

**IMPORTANTE:** 

No podemos nombrar este archivo de otra manera, debe ser `openstack.yml` u `openstack.yaml`.

```yml
################################################################################################
#
# https://docs.ansible.com/ansible/latest/collections/openstack/cloud/openstack_inventory.html
#
################################################################################################
# file must be named openstack.yaml or openstack.yml
# Make the plugin behave like the default behavior of the old script
################################################################################################
plugin: openstack.cloud.openstack
expand_hostvars: true
use_hostnames: True
fail_on_errors: true
clouds_yaml_path:
  - ./clouds.yaml
```

#### Fichero `clouds.yaml`

```yaml
#############################################################
# From /etc/openstack/clouds.yaml
#############################################################
clouds:
  devstack:
    auth:
      auth_url: http://192.168.56.15/identity
      password: openstack
      project_domain_id: default
      project_name: demo
      user_domain_id: default
      username: demo
    identity_api_version: '3'
    region_name: RegionOne
    volume_api_version: '3'
```

#### Estructura del directorio de Inventario `openstack-di`

```bash
vagrant@devstack:~/openstack-di$ tree
.
├── clouds.yaml
├── hostvars_print.yml
└── openstack.ymlyml
```

#### Requisitos previos:

Tenemos que instalar la libreria `shade` de Python y especificar que vamos a usar el `plugin de Openstack`

```bash
pip install shade
```

```bash
export ANSIBLE_INVENTORY_ENABLED=openstack
```

#### Verificamos el funcionamiento:

```bash
ansible-inventory -i openstack.yml --graph
```

```bash
vagrant@devstack:~/openstack-di$ ansible-inventory -i openstack.yml --graph
@all:
  |--@RegionOne:
  |  |--vm_prueba1
  |--@RegionOne_nova:
  |  |--vm_prueba1
  |--@devstack:
  |  |--vm_prueba1
  |--@devstack_RegionOne:
  |  |--vm_prueba1
  |--@devstack_RegionOne_nova:
  |  |--vm_prueba1
  |--@instance-32c37de9-dc14-4ca3-b394-1a39b3ea0ed2:
  |  |--vm_prueba1
  |--@nova:
  |  |--vm_prueba1
  |--@ungrouped:
```

También podremos probar nuestro inventario creando un `Playbook` que extraiga información de las variables de nuestros Hosts `hostvars` definidos en el inventario.

[Discovering variables: facts and magic variables &mdash; Ansible Documentation](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html)

#### Playbook

```yml
###################################################################################
#
# https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_vars_facts.html
#
###################################################################################
---
- name: Print Hostvars to get info
  hosts: all
  gather_facts: false
  vars:
    msg: '{{ hostvars[inventory_hostname] }}'

  tasks:
    - name: Print Vars Info
      debug: var=msg
```

Comprobación

```bash
ansible-playbook -i openstack.yml hostvars_print.yml
```

#### Filtrando información:

Como hemos visto anteriormente, para verificar el funcionamiento de nuestro inventario ejecutamos el comando:

```bash
ansible-inventory -i openstack.yml --graph
```

Podemos filtrar información usando el parametro `--list` y pasandolo al comando `grep` de la siguiente forma:

```bash
ansible-inventory -i openstack.yml --list | grep ansible_ssh_host
```

```bash
"ansible_ssh_host": "192.168.56.237",
```

Otra forma más cómoda es usar `jq` . `jq` es un lenguaje funcional de muy alto nivel con soporte para backtracking y gestión de flujos de datos JSON.

https://stedolan.github.io/jq/

Podemos instalar `jq` desde nuestro repositorio:

```bash
sudo apt-get install jq
```

**Ejemplos:**

Mostramos toda la información:

```bash
ansible-inventory -i openstack.yml --list | jq -r .
```

Filtramos la IP y el nombre de la instancia:

```bash
ansible-inventory -i openstack.yml --list | jq -r '._meta.hostvars[].ansible_ssh_host'
192.168.56.237
```

```bash
ansible-inventory -i openstack.yml --list | jq -r '._meta.hostvars[].openstack.name'
vm_prueba1
```

En el siguiente ejemplo, usamos `jq` para eliminar los datos asociados con la clave `_meta` para que podamos ver solo las listas de instancias.

```bash
ansible-inventory -i openstack.yml --list | jq -r '. | del(._meta)'
```

Author Information
Juan Manuel Payán Barea    (IT Technician) st4rt.fr0m.scr4tch@gmail.com

jpaybar (Juan M. Payán Barea) · GitHub

https://es.linkedin.com/in/juanmanuelpayan
