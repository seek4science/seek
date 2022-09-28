# SEEK Ansible

Ansible script to install SEEK and all its dependencies.

This script is meant for installation on a 'clean' machine. 
It updates and installs all the dependencies needed for SEEK, including rvm and the appropriate Ruby version.
It also configures mysql with the given user and password, using the default database.

Tested on fresh Ubuntu install version:
   - 22.04.1


## Host, user and password set up

Set the host ip address in the *hosts* file.

Set the username (***user_var***) in the *group_vars/vars.yml* file.

Adjust the destination (***git_dest***) for the SEEK folder that will be generated in the *group_vars/vars.yml* file.

Set the ***local_vm_become_password*** variable in the *group_vars/sensitive_vars.yml* file, preferably encrypted (see [Ansible vault](https://docs.ansible.com/ansible/2.8/user_guide/vault.html#variable-level-encryption)). In summary:

 - Create a file *.vault-password.ignore* with the encryption password.
 - Create a file *group_vars/sensitive_vars.yml.ignore* with your passwords in plain text. 
    -- Note: If you choose a different name, update the *ansible.cfg* file.
 - Encrypt your variables by running:
 ```
 ansible-vault encrypt group_vars/sensitive_vars.yml.ignore --output group_vars/sensitive_vars.yml
 ```

### Database configuration

The database default values are copied to *config/database.yml* and the username and password are configured for the values set in the variables ***sql_user*** and ***sql_password***.- Again, it is reccommended that the password is encrypted in the *group_vars/sensitive_vars.yml* file.


## Installation

You need to have Ansible installed in your computer to be able to use this installation script. You can install it with
```
sudo apt install ansible
```


Install SEEK and all its dependencies by running
```
ansible-playbook Deploy-SEEK.yml
```