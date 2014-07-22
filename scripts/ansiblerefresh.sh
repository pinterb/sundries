#!/usr/bin/env bash

################################################
echo "Pull latest, greatest Ansible from github"
################################################

export ANSIBLE_HOME=~/projects/github/ansible
git_cmd=`which git`

if [ ! -d $ANSIBLE_HOME ]; then
  echo "$ANSIBLE_HOME does not appear to be a valid directory."
  exit 1
fi

cd $ANSIBLE_HOME
$git_cmd pull; source ./hacking/env-setup
ansible --version
