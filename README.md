`dimmaryanto93.ndb_postgres_image`
=========

Support platform

- CentOS

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
| `containerd.architecture`               | `amd64`       |             |


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- hosts: servers
  become: true
  roles:
      - { role: dimmaryanto93.ndb_postgres_image }
```

License
-------

MIT

