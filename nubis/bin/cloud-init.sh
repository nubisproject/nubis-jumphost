#!/bin/bash
# A way to get cloud init into our instance without having to muck
# too much with cloudformations cloud-init resource

cat << EOF | sudo tee /etc/cloud/cloud.cfg.d/99-nubis-cloud-init.cfg
#cloud-config
packages:
    - htop

#vim:syntax=yaml
EOF

