# Deploy N instances automatically

###### By Juan Manuel Payán / jpaybar

[st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)



This Playbook displays `N` instances, where `N` is the number of instances collected in the `"count"` variable. It also adds the instances to Ansible's `in-memory inventory` so that we can then connect and provision them.
Finally, it gives us the possibility to leave these instances running or destroy them.



#### Vars

```yml
vars:
    image: "Ubuntu 20.04"
    instance_name_vm: "Ubuntu_20.04_VM"
    network: "private"
    key_name: "miclaveopenstack"
    flavor: "ds1G"
    security_groups: "default"
    count: 2
```

#### In-memory Inventory

```yml
- name: Create in-memory Ansible inventory
      add_host:
        name: "{{ item.server.public_v4 }}"
        groups: ubuntu_group
        ansible_user: ubuntu
        instance_name: "{{ item.server.name }}"
      loop: "{{ new_instances.results }}"
```

#### Wait for SSH service ready to provision them

```yml
- name: Wait for SSH service to become available
      wait_for_connection:
        delay: 5
        timeout: 300
```

#### Continue working with the instances or tear down them

```yml
- name: Continue working with the instances or tear down them
      pause:
        prompt: "Playbook paused... press <enter> to tear down the instances or <ctrl-c> to Continue the Playbook and hit 'A' to save Instances"
```



#### **NOTE:**

The bash script just deploys the instances.



## Author Information

Juan Manuel Payán Barea    (IT Technician) [st4rt.fr0m.scr4tch@gmail.com](mailto:st4rt.fr0m.scr4tch@gmail.com)
[jpaybar (Juan M. Payán Barea) · GitHub](https://github.com/jpaybar)
https://es.linkedin.com/in/juanmanuelpayan


