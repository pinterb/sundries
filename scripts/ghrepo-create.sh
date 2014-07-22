#!/bin/bash

# vim: filetype=sh:tabstop=2:shiftwidth=2:expandtab

readonly PROGNAME=$(basename $0)
readonly PROGDIR="$( cd "$(dirname "$0")" ; pwd -P )"
readonly DEFAULT_PROGDIR=/home/pinter/projects/github
readonly GH_API_BASE_URI=https://api.github.com
readonly DEFAULT_GH_USERNAME=pinterb

# External commands and/or libraries
readonly CURL_CMD=`which curl`
readonly GIT_CMD=`which git`
readonly LABELS_CMD=`which ghlabels.sh`

# Default labels created when you create a new repo
readonly ISSUE_LABELS_GH_DEFAULTS=("bug" "duplicate" "enhancement" "help wanted" "invalid" "question" "wontfix")
# Labels that should be added to support AppDevVT workflow in Waffle.io
readonly ISSUE_LABELS_TO_ADD=("appdevvt:in progress" "appdevvt:ready" "api" "appdevvt:needs review" "backlog" "blocked" "customer requested" "design" "epic" "integration")
# Labels that are no longer needed 
readonly ISSUE_LABELS_TO_DELETE=()


# BOOLEAN CONSTANTS
declare -r TRUE=0
declare -r TRUE_LITERAL="true"
declare -r FALSE=1
declare -r FALSE_LITERAL="false"

# Get to where we need to be.
cd $PROGDIR

# Globals overridden as command line arguments
PROJECT_DIRECTORY=$DEFAULT_PROGDIR
GH_USER=$DEFAULT_GH_USERNAME
PRIVATE=$FALSE_LITERAL
ISSUES=$TRUE_LITERAL
WIKI=$TRUE_LITERAL
AUTO_INIT=$FALSE_LITERAL

usage()
{
  echo -e "\033[33mHere's how to create and initialize a GitHub repo and clone it (locally):"
  echo ""
  echo -e "\033[33mUsage: $PROGNAME [OPTION]"
  echo ""
  echo -e "\033[33mMandatory:"
  echo -e "\t\033[33m--name=NAME\t\t\tThe NAME of the repository."
  echo -e "\t\033[33m--user=USERNAME\t\t\tThe GitHub USERNAME. Default: $GH_USER"
  echo -e "\t\033[33m--dir=DIRECTORY\t\t\tDIRECTORY the newly created repository will be cloned into. Default: $PROJECT_DIRECTORY"
  echo ""
  echo -e "\033[33mOptional:"
  echo -e "\t\033[33m--desc=STRING\t\t\tA description of the repository."
  echo -e "\t\033[33m--private=BOOLEAN\t\tEither true to create a private repository, or false to create a public one. Default: $PRIVATE"
  echo -e "\t\033[33m--issues=BOOLEAN\t\tEither true to enable issues for this repository, false to disable them. Default: $ISSUES"
  echo -e "\t\033[33m--wiki=BOOLEAN\t\t\tEither true to enable the wiki for this repository, false to disable it. Default: $WIKI"
  echo -e "\t\033[33m--auto-init=BOOLEAN\t\tPass true to create an initial commit with empty README. Default: $AUTO_INIT"
  echo -e "\t\033[33m--team=NUMBER\t\t\tThe id of the team that will be granted access to this repository. This is only valid when creating a repository in an organization."
  echo -e "\t\033[33m--password=STRING\t\tThe GitHub user's password."
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
   
  if [ -z "$LABELS_CMD" ]; then
    echo -e "\t\033[33mThe the shell script to manage GitHub issue labels was not found."
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
      --desc)
        DESC=$VALUE
        ;;
      --user)
        GH_USER=$VALUE
        ;;
      --dir)
        PROJECT_DIRECTORY=$VALUE
        ;;
      --private)
        PRIVATE=$VALUE
        ;;
      --issues)
        ISSUES=$VALUE
        ;;
      --wiki)
        WIKI=$VALUE
        ;;
      --auto-init)
        AUTO_INIT=$VALUE
        ;;
      --team)
        TEAM=$VALUE
        ;;
      --password)
        GH_PASSWORD=$VALUE
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


parse_repo_url()
{

  local  __repo_url=$REPO_URL
  local repo_owner=`echo $__repo_url | awk  -F / '{print $4}'`
  local repo_git=`echo $__repo_url | awk  -F / '{print $5}'`
  local repo_name=`echo $repo_git | awk  -F . '{print $1}'`
  local repo_param=$repo_owner/$repo_name
  echo $repo_param
}


valid_args()
{

  # Check for required params
  if [[ -z "$NAME" ]]; then
    echo -e "\033[31mERROR: a repo name is required"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [ ! -d "$PROJECT_DIRECTORY" ]; then
    echo -e "\033[31mERROR: directory \"$PROJECT_DIRECTORY\" does not exist"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [ -d "$PROJECT_DIRECTORY/$NAME" ]; then
    echo -e "\033[31mERROR: clone directory \"$PROJECT_DIRECTORY/$NAME\" already exists"
    echo -e "\e[0m"
    usage
    exit 1
  fi

  if [[ -z "$GH_PASSWORD"  ]]; then
    echo -n "Enter GitHub password for user '$GH_USER': "
    read -s GH_PASSWORD
  fi
}


valid_user()
{
 
  local servername="$GH_API_BASE_URI/repos/$GH_USER/followers"
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $servername)
 
  if [[ "$response" == "401"  ]]; then
    echo -e "\e[0m"
    echo -e "\033[31mERROR: the GitHub authentication for \"$GH_USER\" failed."
    echo -e "\e[0m"
    usage
    exit 1
  fi
}
 
 
valid_repo()
{
 
  local servername="$GH_API_BASE_URI/repos/$GH_USER/$NAME/collaborators"
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $servername)
 
  if [[ ! "$response" == "404"  ]]; then
    echo -e "\e[0m"
    echo -e "\033[31mERROR: the GitHub repository url \"$GH_USER/$NAME\" is not valid.  Instead received $response."
    echo -e "\e[0m"
    usage
    exit 1
    fi
}


github_new_repo()
{

  local my_payload="{"
  my_payload+="\"name\":\"$NAME\""

  if [[ -n $DESC ]]; then
    my_payload+=", \"description\":\"$DESC\""
  fi                                                                                                                                                                                                         

  if [[ -n $PRIVATE ]]; then
    my_payload+=", \"private\":$PRIVATE"
  fi                                                                                                                                                                                                         

  if [[ -n $AUTO_INIT ]]; then
    my_payload+=", \"auto_init\":$AUTO_INIT"
  fi                                                                                                                                                                                                         

  if [[ -n $ISSUES ]]; then
    my_payload+=", \"has_issues\":$ISSUES"
  fi                                                                                                                                                                                                         

  if [[ -n $WIKI ]]; then
    my_payload+=", \"has_wiki\":$WIKI"
  fi                                                                                                                                                                                                         

  if [[ -n $TEAM ]]; then
    my_payload+=", \"team_id\":$TEAM"
  fi                                                                                                                                                                                                         

  my_payload+="}"

  echo "$CURL_CMD -u $GH_USER  --write-out %{http_code} --silent --output /dev/null $GH_API_BASE_URI/user/repos -d \"$my_payload\""
  local response=$($CURL_CMD --user "$GH_USER:$GH_PASSWORD" --write-out %{http_code} --silent --output /dev/null $GH_API_BASE_URI/user/repos -d "$my_payload")

  if [[ ! "$response" == "201" ]]; then
    echo -e "\033[31mERROR: Attempted to fork repo. Expecting a return code of 201.  Instead received $response"
    echo -e "\e[0m"
    usage
    exit 1
  fi
  
  # Some GitHub api calls are async...Wait a few seconds for this command to complete.
  sleep 5

  for i in "${ISSUE_LABELS_TO_ADD[@]}"; do
    $LABELS_CMD --create --name="$i" --repo=$NAME --user=$GH_USER --password=${GH_PASSWORD}
  done

}


clone_repo()
{
  #local repo=$(parse_repo_url)
  #local repo_name=`echo $repo | awk  -F / '{print $2}'`
  local clone_cmnd="$GIT_CMD clone https://github.com/$GH_USER/$NAME.git"
  cd $PROJECT_DIRECTORY && $clone_cmnd
  
  if [ ! -d "$PROJECT_DIRECTORY/$NAME" ]; then
    echo -e "\033[31mERROR: Attempted repo clone.  But clone directory \"$PROJECT_DIRECTORY/$NAME\" does not exist"
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

  # Create GitHub repo 
  github_new_repo 

  # Finally, clone forked repo 
  ##clone_repo

}


parse_args "$@"
main
