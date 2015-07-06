# nubis-jumphost

### Overview
Builds out a nubis jumphost and associates an elastic IP for the ec2 instance

#### How to build project
    1. Build AMI
    ```bash
    $ vim ./nubis/builder/project.json
    $ ./bin/packer-build.sh
    ```
    2. Edit cloudformation parameters.json file
    ```bash
    $ cp ./nubis/cloudformation/parameters.json-dist ./nubis/cloudformation/parameters.json
    ```
    3. Build cloudformation stack
    ```bash
    $ ./bin/build.sh nubis-jumphost
    ```
    4. Update Consul
    ```bash
    nubis-consul --settings nubis/cloudformation/parameters.json --stack-name nubis-jumphost get-and-update
    ```

#### Notes
```bash
git clone git://github.com/limed/nubis-jumphost.git
git submodule update --init --recursive
```

#### TODO
* Currently the stack provisions an ELB as well, we don't need an ELB when creating a bastion host.

