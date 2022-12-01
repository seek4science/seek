# SEEK Ansible

Ansible script to install SEEK and all its dependencies.

This script is meant for installation on a 'clean' machine. 
It updates and installs all the dependencies needed for SEEK, including rvm and the appropriate Ruby version.
It also configures mysql with the given user and password, using the default database.

Tested on fresh Ubuntu install version:
   - 18.04.6
   - 20.04.5
   - 22.04.1

## Ansible set up

You need to have Ansible installed in your computer to be able to use this installation script. You can install it with
```
sudo apt install ansible
```

### SSH access

You may need to have ssh access if you deploy to a remote machine. If so:
- Install sshpass:
```
sudo apt install sshpass
```
- Add host to known hosts (replace the ip with your hosts'):
```
ssh-keyscan -H 192.168.0.xx >> ~/.ssh/known_hosts
```

## Host, user and password set up

Set the ***host ip address*** in the *hosts* file.

Set the username (***user_var***) in the *group_vars/vars.yml* file.

Adjust the destination (***git_dest***) for the SEEK folder that will be generated in the *group_vars/vars.yml* file.

Set the ***local_vm_become_password*** variable in the *group_vars/sensitive_vars.yml* file, preferably encrypted (see [Ansible vault](https://docs.ansible.com/ansible/2.8/user_guide/vault.html#variable-level-encryption)). In summary:

 - Create a file *.vault-password.ignore* with the encryption password.
 ```
 echo myencryptionpassword > .vault-password.ignore
 ```
 - Create a file *group_vars/sensitive_vars.yml.ignore* with your passwords in plain text. 
 ```
 echo "local_vm_become_password: mysudopassword" > group_vars/sensitive_vars.yml.ignore
 ```
    -- Note: If you choose a different name, update the *ansible.cfg* file.
 - Encrypt your variables by running:
 ```
 ansible-vault encrypt group_vars/sensitive_vars.yml.ignore --output group_vars/sensitive_vars.yml
 ```

### Database configuration

The database default values are copied to *config/database.yml* and the username and password are configured for the values set in the variables ***sql_user*** and ***sql_password***.- Again, it is reccommended that the password is encrypted in the *group_vars/sensitive_vars.yml* file.
```
echo "sql_password: mysqlpassword" >> group_vars/sensitive_vars.yml.ignore
ansible-vault encrypt group_vars/sensitive_vars.yml.ignore --output group_vars/sensitive_vars.yml
```


## Deploy

Install SEEK and all its dependencies in the hosts by running
```
ansible-playbook Deploy-SEEK.yml
```

### Local deploy

If you are using this ansible to install SEEK on your local machine, the configuration has to be slightly different:
- Replace the first line of *Deploy-SEEK.yml* (`- hosts: [servers]`) with the lines:
```
- hosts: localhost
  connection: local 
```
(Make sure to keep the indentation as is!)
- Remove the last two lines of the *ansible.cfg* file (`[ssh_connection]` and `pipelining = true`).

- Add the option --ask-become-pass to the deploy command, like so:
```
ansible-playbook Deploy-SEEK.yml --ask-become-pass
```
This will prompt you for your sudo password at the begining of the ansible deploy.
Alternatively, you can rename the ***local_vm_become_password*** variable to ***ansible_become_password***, which should have your sudo password.

**Note:** Some steps in the ansible playbook require "reconnection", which would be the equivalent to closing the terminal and opening a new one. If the local ansible deploy fails, it is likely because of this. Close the terminal, open a new one, and re-run the deploy command.
