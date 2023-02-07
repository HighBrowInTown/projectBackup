#!/bin/bash
#To use this script you are required to instantiate your 

PROJECT_LOCATION=""
PROJECT_FILE=""
BACKUP_TIME="$(date)"

GIT_COMMITS () {

    git add "${PROJECT_LOCATION}/*"
    git commit -m "Performing backup: ${BACKUP_TIME}"
    git push 

}

PERFORM_BACKUP () {

    inotifywait -e close_write -m "${PROJECT_FILE}"
}