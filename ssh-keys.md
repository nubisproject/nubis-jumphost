#### SSH keys
For now we have been deploying SSH keys manually to all our jumphost instances.

In order to get all the SSH keys we need into our jumphost we use a helper [script](https://github.com/Nubisproject/nubis-junkheap/blob/master/keys.sh) to dump out our SSH keys from LDAP

NOTE: You will need to have VPN enabled to be able to connect to LDAP

Example usage:
```bash
./keys.sh someone@mozilla.com > keys.pub

or

for i in person1@mozilla.com person2@mozilla.com; do ./keys.sh ${i}; done > keys.pub
```

Once we get this all done we copy the data into the jumphost by running the following command

```bash
cat keys.pub | ssh ec2-user@jumphost.stage.us-east-1.plan-b-<project-name>.nubis.allzom.org 'cat >> .ssh/authorized_keys'
```

For now we are only doing this for admins if there is a need for additional people we will actually create an account for them without sudo access so that they can have access to their instance


#### Adding users on jumphost

For ubuntu (Assuming you are ssh'ed into the jumphost):

```bash
sudo adduser nubis
```

For Amazon Linux (Assuming you are ssh'ed into the jumphost):

```bash
sudo adduser nubis
```
