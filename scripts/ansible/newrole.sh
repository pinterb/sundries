#!/usr/bin/env bash

MY_SCRIPT_DIR=`echo "$( cd "${BASH_SOURCE[0]%/*}" && pwd )"`
MY_SCRIPT_FILENAME="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
ME=$MY_SCRIPT_DIR/$MY_SCRIPT_FILENAME

ROLE_DIR=`pwd`
ROLE_NAME=samplerole

function usage()
{
    echo ""
    echo "This script creates an Ansible role directory structure that follows some best practices"
    echo ""
    echo "$ME"
    echo "    -h --help"
    echo "    --role-path=$ROLE_DIR"
    echo "    --name=$ROLE_NAME"
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
        --role-path)
            ROLE_DIR=$VALUE
            ;;
        --name)
            ROLE_NAME=$VALUE
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
if [ ! -d $ROLE_DIR ]; then
    mkdir -p $ROLE_DIR
fi

ROLE_LOCATION=$ROLE_DIR/$ROLE_NAME
# But also make sure role name directory does not exist (ie don't overwrite) 
if [ -d $ROLE_LOCATION ]; then
    echo "Error!  $ROLE_LOCATION already exists!!"
    echo "Move or rename this directory OR choose another role name."
    exit 1
fi

# Create baseline directories
mkdir -p $ROLE_LOCATION/defaults
mkdir -p $ROLE_LOCATION/files
mkdir -p $ROLE_LOCATION/templates
mkdir -p $ROLE_LOCATION/handlers
mkdir -p $ROLE_LOCATION/tasks
mkdir -p $ROLE_LOCATION/vars
mkdir -p $ROLE_LOCATION/meta

# Every role probably should have some default vars 

cat << EOF > $ROLE_LOCATION/defaults/README.md 
Role Name
========

A brief description of the role goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
-------------------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
        - { role: username.rolename, x: 42 }

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).


EOF

cat << EOF2 > $ROLE_LOCATION/defaults/main.yml
---
# file: roles/$ROLE_NAME/defaults/main.yml
EOF2

cat << EOF3 > $ROLE_LOCATION/vars/main.yml
---
# file: roles/$ROLE_NAME/vars/main.yml
EOF3

cat << EOF4 > $ROLE_LOCATION/tasks/main.yml
---
# file: roles/$ROLE_NAME/tasks/main.yml
EOF4

cat << EOF5 > $ROLE_LOCATION/handlers/main.yml
---
# file: roles/$ROLE_NAME/handlers/main.yml
EOF5

cat << EOF6 > $ROLE_LOCATION/meta/main.yml
---
# file: roles/$ROLE_NAME/meta/main.yml

dependencies: []
# List your role dependencies here, one per line.
# Be sure to remove the '[]' above if you add dependencies
# to this list.
EOF6
