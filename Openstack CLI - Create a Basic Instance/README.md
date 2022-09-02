# COMANDOS OPENSTACK / NOVA CLI

### 

### CONFIGURACIÓN DE LAS VARIABLES DE ENTORNO PARA LOS USUARIOS "admin" y "demo".

Cambiamos al usuario "stack" creado en la instalación de Devstack:

```bash
sudo su -l stack
cd devstack
```

Sino hemos establecido las variables de entorno con el comando `source openrc` al ejecutar cualquier comando nos devolverá el siguiente "Warning":

```
"Missing value auth-url required for auth plugin password"
```

Al ejecutar el comando `source openrc` la salida será similar a la siguiente:

```
"WARNING: setting legacy OS_TENANT_NAME to support cli tools."
```

Ahora podremos ejecutar comandos desde la CLI, por ejemplo listar las imagenes disponibles:

```bash
openstack image list
```

```bash
+--------------------------------------+--------------------------+--------+
| ID                                   | Name                     | Status |
+--------------------------------------+--------------------------+--------+
| 7069398d-4635-4d2b-b750-15580aaa9c79 | cirros-0.5.1-x86_64-disk | active |
+--------------------------------------+--------------------------+--------+
```

O listar los sabores:

```bash
nova flavor-list
```

```
+----+-----------+------------+------+-----------+------+-------+-------------+-----------+-------------+
| ID | Name      | Memory_MiB | Disk | Ephemeral | Swap | VCPUs | RXTX_Factor | Is_Public | Description |
+----+-----------+------------+------+-----------+------+-------+-------------+-----------+-------------+
| 1  | m1.tiny   | 512        | 1    | 0         | 0    | 1     | 1.0         | True      | -           |
| 2  | m1.small  | 2048       | 20   | 0         | 0    | 1     | 1.0         | True      | -           |
| 3  | m1.medium | 4096       | 40   | 0         | 0    | 2     | 1.0         | True      | -           |
| 4  | m1.large  | 8192       | 80   | 0         | 0    | 4     | 1.0         | True      | -           |
| 5  | m1.xlarge | 16384      | 160  | 0         | 0    | 8     | 1.0         | True      | -           |
| c1 | cirros256 | 256        | 1    | 0         | 0    | 1     | 1.0         | True      | -           |
| d1 | ds512M    | 512        | 5    | 0         | 0    | 1     | 1.0         | True      | -           |
| d2 | ds1G      | 1024       | 10   | 0         | 0    | 1     | 1.0         | True      | -           |
| d3 | ds2G      | 2048       | 10   | 0         | 0    | 2     | 1.0         | True      | -           |
| d4 | ds4G      | 4096       | 20   | 0         | 0    | 4     | 1.0         | True      | -           |
+----+-----------+------------+------+-----------+------+-------+-------------+-----------+-------------+
```

La otra opción es una vez dentro del Proyecto y habiendonos logado con la interfaz `Horizon`, hacemos click en "Acceso a la API" y después click en "Descargar fichero RC de OpenStack", de esta forma se descargará un script llamado `demo-openrc.sh` si nos hemos logado en el Proyecto `demo` o `admin-openrc.sh` en caso de logarnos como usuario "admin".

El procedimiento será igual que el anterior, ejecutaremos el comando para establecer las variables de entorno para el usuario "demo":

```bash
source demo-openrc.sh
```

Pero esta vez nos solicitará la contraseña para el Proyecto "demo" con usuario "demo"

```
Please enter your OpenStack Password for project demo as user demo:
```

Introducimos la contraseña que configuramos en nuestro fichero de respuesta `local.conf` a la hora de la instalación y listo.

##### Ejecutar el cliente Nova desde un equipo remoto

Para poder ejecutar commandos de Nova necesitamos instalar el cliente en nuestro equipo de control remoto. La instalación la podemos hacer desde repositorio según la distribución o con `pip`, de esta forma se instalará la última versión del cliente Nova.

```bash
sudo apt-get install python3-pip
```

```bash
sudo pip install python-novaclient
```

Ya tendríamos instalado el cliente Nova, previamente deberiamos haber descargado el fichero RC. Una vez logado en la interfaz web de Horizon, hacemos click en "Acceso a la API" y después click en "Descargar fichero RC de OpenStack", de esta forma se descargará un script llamado `demo-openrc.sh` si nos hemos logado en el Proyecto `demo` o `admin-openrc.sh` en caso de logarnos como usuario "admin".

Ejecutamos el fichero RC:

```bash
source demo-openrc.sh
```

y probamos el funcionamiento del cliente Nova, por ejemplo listando los sabores:

```bash
nova flavor-list
```

### GESTIÓN DE CLAVES "PÚBLICA/PRIVADA"

##### Crear par de claves pública/privada

```bash
openstack keypair create miclaveopenstack > miclaveopenstack.pem
```

¡¡Importante!!, antes de usar nuestra clave, debermos asignar los permisos adecuados o nuestro cliente `ssh` nos dará error:

```bash
chmod 600 miclaveopenstack.pem
```

##### Listar par de claves pública/privada

```bash
openstack keypair list
```

```
+------------------+-------------------------------------------------+
| Name             | Fingerprint                                     |
+------------------+-------------------------------------------------+
| miclaveopenstack | 40:9c:49:d7:1c:95:bd:5d:cd:25:21:d3:18:87:09:75 |
+------------------+-------------------------------------------------+
```

##### Importar una clave pública existente

Si ya hemos generado un par de claves en nuestro computador Linux o Mac, lo más probable es que la llave pública se llame `id_rsa.pub` y esté ubicada en el directorio: `~/.ssh/`.

Podemos importar nuestra clave pública al servidor de la siguiente forma:

```bash
openstack keypair create --public-key \
~/.ssh/id_rsa.pub miclavepublicalocal
```

```
+-------------+-------------------------------------------------+
| Field       | Value                                           |
+-------------+-------------------------------------------------+
| fingerprint | 43:ea:6d:c1:7e:1c:92:c2:20:70:65:41:95:5f:da:fd |
| name        | miclavepublicalocal                             |
| user_id     | acd4e77eadfd49778aa1a10cce08af18                |
+-------------+-------------------------------------------------+
```

Ahora si listamos de nuevo nuestras claves apareceran las 2

```bash
openstack keypair list
```

o 

```bash
nova keypair-list
```

```
+---------------------+------+-------------------------------------------------+
| Name                | Type | Fingerprint                                     |
+---------------------+------+-------------------------------------------------+
| miclaveopenstack    | ssh  | 40:9c:49:d7:1c:95:bd:5d:cd:25:21:d3:18:87:09:75 |
| miclavepublicalocal | ssh  | 43:ea:6d:c1:7e:1c:92:c2:20:70:65:41:95:5f:da:fd |
+---------------------+------+-------------------------------------------------+
```

##### Logarnos contra una instancia con nuestra clave

Para logarnos en una instancia creada con la imagen de pruebas `cirros` ejecutaríamos el siguiente comando:

```bash
ssh -i miclaveopenstack.pem cirros@192.168.56.248
```

### COMANDOS "Grupos de Seguridad", permitir PING y conexión SSH

##### Añadir regla ICMP al Grupo de Seguridad "default":

```bash
openstack security group rule create --proto icmp default
```

```bash
openstack security group rule create --proto icmp --dst-port 0 default
```

##### Añadir regla al Grupo de Seguridad "default" para permitir las conexiones SSH:

```bash
openstack security group rule create --proto tcp --dst-port 22 default
```

### COMANDOS BÁSICOS PARA PREPARAR UNA INSTANCIA

##### Listar sabores

```bash
openstack flavor list
```

##### Listar imágenes

```bash
openstack image list
```

```bash
openstack image list | grep -F cirros | cut -f3 -d ‘|’
```

##### Listar instancias / servidores

```bash
openstack server list
```

##### Listar redes

```bash
openstack network list
```

```bash
openstack network list | grep private | cut -f2 -d '|' | tr -d ' '
```

##### Listar IP's flotantes / Solicitar IP flotante / Asociar IP flotante

```bash
openstack floating ip list
```

```bash
openstack floating ip create public
```

```bash
openstack server add floating ip vm_prueba1 192.168.56.234
```

##### Listar par de claves

```bash
openstack keypair list
```

```bash
openstack keypair list | grep -iF miclaveopenstack | cut -f2 -d '|'
```

##### Crear una instancia

```bash
openstack server create --flavor cirros256 \
 --image $(openstack image list | grep cirros | cut -f3 -d '|') \
 --nic net-id=$(openstack network list | grep private | cut -f2 -d '|' | tr -d ' ') \
 --security-group default --key-name $(openstack keypair list | grep -iF miclaveopenstack | cut -f2 -d '|') vm_prueba1
```

Le asociamos un IP flotante previamente solicitada:

```bash
openstack server add floating ip vm_prueba1 192.168.56.234
```

Conectar a la instancia por SSH:

```bash
ssh -i miclaveopenstack.pem cirros@192.168.56.234
```

Mostrar la URL de la consola para conectar via web por VNC:

```bash
openstack console url show vm_prueba1
```

```
+-------+----------------------------------------------------------------------------------------------+
| Field | Value                                                                                        |
+-------+----------------------------------------------------------------------------------------------+
| type  | novnc                                                                                        |
| url   | http://192.168.56.15:6080/vnc_lite.html?path=%3Ftoken%3D336e5c38-7df2-41f0-9164-e84713354c13 |
+-------+----------------------------------------------------------------------------------------------+
```

### DESCARGAS DE IMÁGENES DESDE LA WEB DE "OpenStack"

```
https://docs.openstack.org/image-guide/obtain-images.html
```

### LISTAR CATALOGO DE SERVICIOS

```bash
openstack catalog list
```

```bash
+-------------+----------------+------------------------------------------------------------------------------+
| Name        | Type           | Endpoints                                                                    |
+-------------+----------------+------------------------------------------------------------------------------+
| cinderv2    | volumev2       | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15/volume/v2/9f0d6ceacecd4060b34061f63d17dff5    |
|             |                |                                                                              |
| cinderv3    | volumev3       | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15/volume/v3/9f0d6ceacecd4060b34061f63d17dff5    |
|             |                |                                                                              |
| keystone    | identity       | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15/identity                                      |
|             |                | RegionOne                                                                    |
|             |                |   admin: http://192.168.56.15/identity                                       |
|             |                |                                                                              |
| nova        | compute        | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15/compute/v2.1                                  |
|             |                |                                                                              |
| cinder      | block-storage  | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15/volume/v3/9f0d6ceacecd4060b34061f63d17dff5    |
|             |                |                                                                              |
| swift       | object-store   | RegionOne                                                                    |
|             |                |   public: http://192.168.56.15:8080/v1/AUTH_9f0d6ceacecd4060b34061f63d17dff5 |
|             |                | RegionOne                                                                    |
|             |                |   admin: http://192.168.56.15:8080                                           |
|             |                |                                                                              |
```
