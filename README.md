# SEEK Ansible

Ansible script to install SEEK and all its dependencies.

Tested on fresh ubuntu install. 

Set the host ip address in the *hosts* file.

Set the username in the *group_vars/vars.yml* file.

Set the ***local_vm_become_password*** variable in the *sensitive_vars.yml* file, preferably encrypted (see [Ansible vault](https://docs.ansible.com/ansible/2.8/user_guide/vault.html#variable-level-encryption)).

Install SEEK and all its dependencies by running
```
ansible-playbook Deploy-SEEK.yml
```

The current version does not generate the docs for Ruby 2.7.5, you may want to do so by running
```
rvm docs generate-ri
```
