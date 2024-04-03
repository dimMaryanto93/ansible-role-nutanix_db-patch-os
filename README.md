`dimmaryanto93.nutanix_db-patch-os`
=========

Provision VM image for Nutanix Database especily hardening

- Create user and grour (era drive)
- Install commons requiremment packages such as `nfs`, `curl`, `pip package manager` etc.
- Install test script to validate/verify software match the requirement of Nutanix Database (NDB) formally ERA

Platform support 

- CentOS 7
- OracleLinux 8.7
- Ubuntu 20.04

for more please checkout the [documentation](https://portal.nutanix.com/page/documents/details?targetId=Release-Notes-Nutanix-NDB-v2_5_4:v25-ndb-compatibility-general-ndb-2_5_3-r.html)

Requirements
------------

Untuk menggunakan role ini, kita membutuhkan package/collection

- [ansible.posix](https://github.com/ansible-collections/ansible.posix)

Temen-temen bisa install, dengan cara

```bash
ansible-galaxy collection install ansible.posix
```

Atau temen-temen bisa menggunakan `requirement.yaml` file and install menggunakan `ansible-galaxy collection install -r requirement.yaml`, dengan format seperti berikut:

```yaml
---
collections:
  - ansible.posix
```

Role Variables
--------------

Ada beberapa variable yang temen-temen bisa gunakan untuk setting docker daemon, diantaranya seperti berikut:

| Variable name                           | Example value | Description |
| :---                                    | :---          | :---        |


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  become: true
  roles:
      - { role: dimmaryanto93.nutanix_db-patch-os }
```

License
-------

MIT

