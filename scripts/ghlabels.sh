#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly DEFAULT_PROGDIR=/home/pinter/projects/github
readonly GH_API_BASE_URI=https://api.github.com
readonly DEFAULT_GH_USERNAME=pinterb
readonly CURL_CMD=`which curl`
readonly GIT_CMD=`which git`
readonly SHUF_CMD=`which shuf`

# We want some sample label colors
declare -a DEFAULT_LABEL_COLORS=("e74c3c" "9b59b6" "3498db" "95a5a6" "f1c40f" "e11d21" "eb6420" "fbca04" "009800" "006b75" "207de5" "0052cc" "5319e7")
# The number of elements in the array above 
readonly NUM_OF_COLOR_OPTIONS=13
readonly DEFAULT_COLOR_NDX=`$SHUF_CMD -i 0-12 -n 1`

# BOOLEAN CONSTANTS
declare -r TRUE=0
declare -r TRUE_LITERAL="true"
declare -r FALSE=1
declare -r FALSE_LITERAL="false"

# Get to where we need to be.
cd $PROGDIR

# Globals overridden as command line arguments
GH_USER=$DEFAULT_GH_USERNAME
#COLOR=${DEFAULT_LABEL_COLORS[${DEFAULT_COLOR_NDX}]}
COLOR=${DEFAULT_LABEL_COLORS[@]:$DEFAULT_COLOR_NDX:1}

usage()
{
  echo -e "\033[33mHere's how to maintain GitHub issue labels:"
  echo ""
  echo -e "\033[33mUsage: $PROGNAME [OPTION]"
  echo ""
  echo -e "\033[33mMandatory:"
  echo -e "\t\033[33m--repo=REPO\t\t\tThe name of the GitHub repository."
  echo -e "\t\033[33m--name=NAME\t\t\tThe NAME of the label."
  echo -e "\t\033[33m--user=USERNAME\t\t\tThe GitHub USERNAME. Default: $GH_USER"
  echo ""
  echo -e "\033[33mAnd set one of the following flags:"
  echo -e "\t\033[33m--create\t\t\tCreate the label"
  echo -e "\t\033[33m--delete\t\t\tDelete the label"
  echo ""
  echo -e "\033[33mOptional:"
  echo -e "\t\033[33m--password=STRING\t\tThe GitHub user's password."
  echo -e "\t\033[33m--color=STRING\t\t\tColor to use on new label. Default: $COLOR"
  echo ""
  echo -e "\t\033[33m-h --help\t\t\tDisplay this message."
  echo -e "\033[0m"
}


prerequisites()
{
  if [ -z "$GIT_CMD" ]; then
    echo -e "\t\033[33mGit does not appear to be installed. Please install and re-run this script."
    exit 1
  fi
  
  if [ -z "$CURL_CMD" ]; then
    echo -e "\t\033[33mcurl does not appear to be installed. Please install and re-run this script."
    exit 1
  fi
}


parse_args()
{
  while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
      -h | --help)
        usage
        exit
        ;;
      --name)
        NAME=$VALUE
        ;;
      --repo)
        REPO=$VALUE
        ;;
      --user)
        GH_USER=$VALUE
        ;;
      --color)
        COLOR=$VALUE
        ;;
      --password)
        GH_PASSWORD=$VALUE
        ;;
      --create)
        CREATE_LABEL=TRUE_LITERAL
        ;;
      --delete)
        DELETE_LABEL=TRUE_LITERAL
        ;;
      *)
        echo -e "\033[31mERROR: unknown parameter \"$PARAM\""
        echo -e "\e[0m"
        usage
        exit 1
        ;;
    esac
    shift
  done

}


valid_args()
{

  # Check for required params
  if [[ -z "$REPO" ]]; then
    echo -e "\033[31mERROR: a repo name is required"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
  if [[ -z "$NAME" ]]; then
    echo -e "\033[31mERROR: a label name is required"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [[ -z "$CREATE_LABEL" && -z "$DELETE_LABEL" ]] ; then
    echo -e "\033[31mERROR: either --create or --delete flag must be set"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [[ -n "$CREATE_LABEL" && -n "$DELETE_LABEL" ]] ; then
    echo -e "\033[31mERROR: either --create or --delete flag must be set. BUT not both!"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [[ -z "$GH_PASSWORD" ]]; then
    echo -n "Enter GitHub password for user '$GH_USER': "
    read -s GH_PASSWORD
  fi
}


valid_user()
{

  local servername="$GH_API_BASE_URI/repos/$GH_USER/followers"
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ "$response" == "401" ]]; then
    echo -e "\e[0m"
    echo -e "\033[31mERROR: the GitHub authentication for \"$GH_USER\" failed."
    echo -e "\e[0m"
    usage
    exit 1
  fi
}


valid_repo()
{

  local servername="$GH_API_BASE_URI/repos/$GH_USER/$REPO/collaborators"
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $servername)

  if [[ "$response" == "404" ]]; then
    echo -e "\e[0m"
    echo -e "\033[31mERROR: the GitHub repository url \"$GH_USER/$REPO\" is not valid."
    echo -e "\e[0m"
    usage
    exit 1
  fi
}


create_label()
{

  local servername="$GH_API_BASE_URI/repos/$GH_USER/$REPO/labels"

  local my_payload="{"
  my_payload+="\"name\":\"$NAME\""

  if [[ -n $COLOR ]]; then
    my_payload+=", \"color\":\"$COLOR\""
  fi

  my_payload+="}"

  echo "$CURL_CMD --user $GH_USER:$GH_PASSWORD --write-out %{http_code} --silent --output /dev/null $servername -d \"$my_payload\""
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $servername -d "$my_payload")

  if [[ ! "$response" == "201" ]]; then
    echo -e "\033[31mERROR: Attempted to create label. Expecting a return code of 201.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
}

delete_label()
{

  local servername="$GH_API_BASE_URI/repos/$GH_USER/$REPO/labels/$NAME"

  echo "$CURL_CMD --user $GH_USER:$GH_PASSWORD --write-out %{http_code} --silent --output /dev/null --include --request DELETE $servername)"
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null --include --request DELETE $servername)

  if [[ ! "$response" == "204" ]]; then
    echo -e "\033[31mERROR: Attempted to delete label. Expecting a return code of 201.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
}


main()
{
  # There are some third-party packages that required to run this script 
  prerequisites 

  # Perform sanity check on command line arguments
  valid_args

  # Validate user's GitHub credentials 
  valid_user

  # Validate repo url against GitHub API
  valid_repo

  # Create a label 
  if [[ -n "$CREATE_LABEL"  ]] ; then
    create_label
  fi
 
  # Delete a label 
  if [[ -n "$DELETE_LABEL"  ]] ; then
    delete_label
  fi

}


parse_args "$@"
main
