#!/usr/bin/env bash
set -e

BACKUPS_DIR=${BACKUPS_DIR:-./var}
BACKUPS_DIR=$(realpath "$BACKUPS_DIR")

__log() {
    printf "$*\n"
}

__take_backup() {
    if [ -z "$GITHUB_USER" ]; then
        printf "ERROR! Missing \$GITHUB_USER\n"
        exit 1
    fi
    if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
        printf "ERROR! Missing \$GITHUB_ACCESS_TOKEN\n"
        exit 1
    fi

    for USER in $(echo $GITHUB_USER | tr "," "\n"); do
        printf "Taking backup of github user \"$USER\"\n"
        github-backup ${USER} --token=$GITHUB_ACCESS_TOKEN --all --output-directory=$BACKUPS_DIR/${USER} \
            --private --gists --lfs --starred-gists
    done
}

__upload_backup() {
    if [ -z "$S3_URL$S3_BUCKET" ]; then
        printf "ERROR! None of \$S3_BUCKET, \$S3_URL is specified\n"
        exit 1
    fi
    if [ -z "$S3_ACCESS_KEY" ]; then
        printf "ERROR! Missing \$S3_ACCESS_KEY\n"
        exit 1
    fi
    if [ -z "$S3_SECRET_KEY" ]; then
        printf "ERROR! Missing \$S3_SECRET_KEY\n"
        exit 1
    fi

    printf "Dropping old local archives\n"
    rm -rf $BACKUPS_DIR/*.tar.gz

    for DIR in $(ls -d $BACKUPS_DIR/*/); do
        NAME=$(basename $DIR)
        FILENAME="$BACKUPS_DIR/$NAME-$(date "+%Y%m%d-%H%M%S").tar.gz"
        printf "Compressing backup of \"$NAME\" into \"$FILENAME\"\n"
        tar -zcf $FILENAME $DIR
    done

    for FILE in $(ls $BACKUPS_DIR/*.tar.gz); do
        BACKUP_FILE_PATH=$(realpath $FILE)
        ./upload.py $BACKUP_FILE_PATH
    done
}

__clean_backups() {
    printf "Removing old backups from S3\n"

    if [ -z "$S3_URL$S3_BUCKET" ]; then
        printf "ERROR! None of \$S3_BUCKET, \$S3_URL is specified\n"
        exit 1
    fi
    if [ -z "$S3_ACCESS_KEY" ]; then
        printf "ERROR! Missing \$S3_ACCESS_KEY\n"
        exit 1
    fi
    if [ -z "$S3_SECRET_KEY" ]; then
        printf "ERROR! Missing \$S3_SECRET_KEY\n"
        exit 1
    fi

    for USER in $(echo $GITHUB_USER | tr "," "\n"); do
        printf "Removing old backups of github user \"$USER\" from S3\n"
        S3_FILE_MASK="${USER}-"
        if [ ! -z "$S3_PREFIX" ]; then
            S3_FILE_MASK="$S3_PREFIX/$S3_FILE_MASK"
        fi
        ./clean.py $S3_FILE_MASK
    done
}

backup_routine() {
    __take_backup
    __upload_backup
    __clean_backups
}

run_scheduler() {
    printf "Starting backup scheduler\n"
    while :; do
        backup_routine
        printf "Sleep for 1 day\n"
    done
}

print_help() {
    printf "\n"
    printf "COMMANDS:\n"
    printf "  ./entypoint.sh backup   - run backup routine once and exit\n"
    printf "  ./entypoint.sh run      - run backup scheduler\n"
    printf "\n"
    printf "OPTIONS: \n"
    printf "  -h, --help              - print help and exit\n"
    printf "\n"
    printf "ENV VARIABLES: \n"
    printf "  GITHUB_USER             - (required) Comma-separated list of GitHub user names\n"
    printf "  GITHUB_ACCESS_TOKEN     - (required) GitHub access token\n"
    printf "  S3_ACCESS_KEY           - (required) Access key for S3\n"
    printf "  S3_SECRET_KEY           - (required) Secret key for S3\n"
    printf "  S3_BUCKET               - (required) S3 bucket name\n"
    printf "  S3_URL                  - (optional) S3 service URL (not needed for AWS S3)\n"
    printf "  S3_PREFIX               - (optional) S3 filename prefix (e.g. \"backups/github/\")\n"
    printf "  BACKUP_KEEP_DAYS        - (optional, default \"30\") S3 filename prefix (e.g. \"backups/github/\")\n"
}

while [ "$1" != "" ]; do
    case "$1" in
    backup)
        backup_routine
        exit
        ;;
    run)
        run_scheduler
        exit
        ;;
    -h | --help | help)
        print_help
        exit
        ;;
    *)
        printf "Unknown command: \"$1\"\n"
        exit 1
        ;;
    esac
    shift
done

printf "No command specified\n"
exit 1
