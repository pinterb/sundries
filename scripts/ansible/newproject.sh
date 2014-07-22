#!/usr/bin/env bash

MY_SCRIPT_DIR=`echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd )"`
MY_SCRIPT_FILENAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$MY_SCRIPT_DIR/$MY_SCRIPT_FILENAME

PROJECT_DIR=`pwd`
PROJECT_NAME=sampleproject

function usage()
{
    echo ""
    echo "This script creates an Ansible project directory structure that follows some best practices"
    echo ""
    echo "$ME"
    echo "    -h --help"
    echo "    --project-path=$PROJECT_DIR"
    echo "    --name=$PROJECT_NAME"
    echo ""
}
 
while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit
            ;;
        --project-path)
            PROJECT_DIR=$VALUE
            ;;
        --name)
            PROJECT_NAME=$VALUE
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

# Make sure the role's path indeed exists 
if [ ! -d $PROJECT_DIR ]; then
    mkdir -p $PROJECT_DIR
fi

PROJECT_LOCATION=$PROJECT_DIR/$PROJECT_NAME
# But also make sure role name directory does not exist (ie don't overwrite) 
if [ -d $PROJECT_LOCATION ]; then
    echo "Error!  $PROJECT_LOCATION already exists!!"
    echo "Move or rename this directory OR choose another role name."
    exit 1
fi

# Create baseline directories
mkdir -p $PROJECT_LOCATION/docs
mkdir -p $PROJECT_LOCATION/bin
mkdir -p $PROJECT_LOCATION/provision
mkdir -p $PROJECT_LOCATION/provision/roles
mkdir -p $PROJECT_LOCATION/provision/group_vars
mkdir -p $PROJECT_LOCATION/provision/host_vars

cat << EOF > $PROJECT_LOCATION/README.md 
Ansible Project Name
========

A brief description of the project goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself should be mentioned here.

License
-------

BSD

Author Information
------------------

An optional section for the project authors to include contact information, or a website (HTML is not allowed).

EOF

cat << EOF2 > $PROJECT_LOCATION/docs/README.md
Project Docs 
========

Whatever additional documentation should be outlined here

EOF2

cat << EOF3 > $PROJECT_LOCATION/bin/README.md
Project Shell Scripts 
========

This directory contains executable scripts. Bootstrap scripts and wrappers around Ansible scripts themselves are examples
of the scripts that might go into this directory.
EOF3

cat << EOF4 > $PROJECT_LOCATION/provision/README.md
Ansible playbooks 
========

This directory contains the Ansible playbooks, variables, roles, and inventory for provisioning your environment.

The directory layout was created to follow [best practices](http://docs.ansible.com/playbooks_best_practices.html#directory-layout).
EOF4

cat << EOF5 > $PROJECT_LOCATION/provision/roles/README.md
Ansible roles 
========

This directory contains the Ansible roles for provisioning your environment.

To learn more about roles you should start with Ansible's [documentation](http://docs.ansible.com/playbooks_roles.html#playbook-roles-and-include-statements).
EOF5

cat << EOF6 > $PROJECT_LOCATION/provision/group_vars/README.md
Ansible group variables 
========

This directory contains your group variables.

To learn more about group variables you should start with Ansible's [documentation](http://docs.ansible.com/playbooks_best_practices.html#group-and-host-variables).
EOF6

cat << EOF7 > $PROJECT_LOCATION/provision/host_vars/README.md
Ansible host variables 
========

This directory contains your host variables.

To learn more about group variables you should start with Ansible's [documentation](http://docs.ansible.com/playbooks_best_practices.html#group-and-host-variables).
EOF7
