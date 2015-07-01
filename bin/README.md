I got tired of typing out the cloudformation commands so i wrote scripts to help me.

You will need to configure the BASE_DIR variable by editing the variables.sh file

build.sh        - Builds the cloudformation stack and requires a stackname as a command line parameter

update.sh       - Updates the cloudformation stack, also requires a stackname.

delete.sh       - Deletes the stack

packer-build.sh - Builds ami using nubis-builder
