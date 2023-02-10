#!/bin/bash -x
#Use this script once you have created a new repo in github and using ssh you have cloned it in your local machine.

#Settings ini
source settings.ini
# source /opt/projectBackups/settings.ini
#Project Variables
PROJECT_DIR="${DIR}/${PROJECT_NAME}"
#Log Variables
LOG_TIME=$(date "+%Y %m %d %T.%3N")
#Git Variables
GIT_USERNAME=$(git config user.name)
GIT_USEREMAIL=$(git config user.email)
GIT_URL="git@github.com"
GIT_REPO="${PROJECT_NAME}"
GIT_PROJECT_URL="${GIT_URL}:${USERNAME}/${GIT_REPO}.git"

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
		echo "${LOG_TIME} Programme Error: Username and Email Unknown!" >> "${LOG}"
		exit 1
	elif [ "x${GIT_USERNAME}" == "x" ] && [ "x${GIT_USEREMAIL}" == "x" ]
	then
		echo "${LOG_TIME} Programme Info: Setting Username and Email" >> "${LOG}"
		git config user.name "${USERNAME}"
		git config user.email "${USEREMAIL}"
	fi

	GIT_INIT_DIR="$(git rev-parse --is-inside-work-tree)"
	if [ "x${GIT_INIT_DIR}" != "xtrue" ]
	then 
		echo "${LOG_TIME} Programme Info: Initializing Repo" >> "${LOG}"
		git init
	fi

	if [ "${SSH_CONN}" == "255" ]
	then
		echo "${LOG_TIME} Programme Error: SSH Permission denied (publickey)." >> "${LOG}"
		exit 1
	fi

	GIT_REMOTE=$(git remote -v 2> /dev/null)
	if  [ "x${GIT_REMOTE}" == "x0"  ]
	then
		git remote add origin "${GIT_PROJECT_URL}"
	fi
}

GIT_COMMITS () {

	GIT_CONN_CHECK
    git add "${1}"
	git commit -m "${GIT_COMMIT_MSG}"
	git push -u origin main

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
		echo "${LOG_TIME} Programme Info: Watch File: ${FILE}: ${EVENT}" >> "${LOG}"
		GIT_MODIFIED_CHECK
		GIT_COMMITS "${FILE}"
	done < <(inotifywait -q -e close_write -m "${PROJECT_DIR}"/*)

}

PERFORM_BACKUP