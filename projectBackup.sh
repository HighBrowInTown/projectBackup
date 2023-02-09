#!/bin/bash -x
#Use this script once you have initalized your project folder.
#Project Variables
PROJECT_NAME="projectBackup_Test"
DIR="/usr/local/src"
PROJECT_DIR="${DIR}/${PROJECT_NAME}"
BACKUP_TIME="$(date)"
#Log Variables
GET_LOG="/var/log/projectBackups.log"
LOG_TIME=$(date "+%Y %m %d %T.%3N")
#Git Variables
GIT_SSH_KEY="/root/.ssh/github"
USERNAME="Po-Pratik"
USEREMAIL="pratik@safesquid.net"
GIT_USERNAME=$(git config user.name)
GIT_USEREMAIL=$(git config user.email)
GIT_URL="git@github.com"
GIT_REPO="${PROJECT_NAME}"
GIT_PROJECT_URL="${GIT_URL}:${USERNAME}/${GIT_REPO}"

GIT_SET_SSH () {

	[ "x$(pidof ssh-agent)" != "x" ] && killall ssh-agent
	eval "$(ssh-agent -s)"
	ssh-add "${GIT_SSH_KEY}"
	ssh -T git@github.com &>> /dev/null; SSH_CONN="${?}"
}

GIT_CONN_CHECK () {
	
	GIT_SET_SSH

	[ -d "${PROJECT_DIR}" ] && cd "${PROJECT_DIR}" || return

	if [ "x${USERNAME}" == "x" ] && [ "${USEREMAIL}" == "x" ]
	then 
		echo "${LOG_TIME} Programme Error: Username and Email Unknown!" >> "${GET_LOG}"
		exit 1
	elif [ "x${GIT_USERNAME}" == "x" ] && [ "x${GIT_USEREMAIL}" == "x" ]
	then
		echo "${LOG_TIME} Programme Info: Setting Username and Email" >> "${GET_LOG}"
		git config user.name "${USERNAME}"
		git config user.email "${USEREMAIL}"
	fi

	GIT_INIT_DIR="$(git rev-parse --is-inside-work-tree)"
	if [ "x${GIT_INIT_DIR}" != "xtrue" ]
	then 
		echo "${LOG_TIME} Programme Info: Initializing Repo" >> "${GET_LOG}"
		git init
	fi

	if [ "${SSH_CONN}" == "255" ]
	then
		echo "${LOG_TIME} Programme Error: SSH Permission denied (publickey)." >> "${GET_LOG}"
		exit 1
	else
		git remote add origin "${GIT_PROJECT_URL}"	
	fi
	
}

GIT_COMMITS () {

	GIT_CONN_CHECK
    git add "${1}"
	git commit -m "Performing backup: ${1} - ${BACKUP_TIME}"
	git push -u origin master

}

GIT_MODIFIED_CHECK () {

	while read -r M_FILES
	do
		GIT_COMMITS "${M_FILES}"
	done < <(git status | awk '/modified:/{print $2}')
}

PERFORM_BACKUP () {

	while read -r FILE EVENT
	do
		echo "${FILE}"
		echo "${LOG_TIME} Programme Info: Watch File: ${FILE}: ${EVENT}" >> "${GET_LOG}"
		GIT_MODIFIED_CHECK
		GIT_COMMITS "${FILE}"
	done < <(inotifywait -q -e close_write -m "${PROJECT_DIR}"/*)

}

PERFORM_BACKUP