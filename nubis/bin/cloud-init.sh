#!/bin/bash

cat > /tmp/99-nubis-cloud-init.cfg << EOF
#cloud-config
packages:
    - htop

#vim:syntax=yaml
EOF

sudo mv /tmp/99-nubis-cloud-init.cfg /etc/cloud/cloud.cfg.d/99-nubis-cloud-init.cfg
