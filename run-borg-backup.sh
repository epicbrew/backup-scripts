#!/bin/bash
# Backup a folder to a remote address using borg.
# Usage: run-borg-backup.sh
# To restore: borg extract $BORG_REPO::computer-and-date
#
# Required. Set these in user environment via bashrc or other file
#
# export BORG_REPO='username@remote.host.address:borg/repo/path'
# export BORG_PASSPHRASE='your password'
# export BORG_REMOTE_PATH=borg1 # Correct for rsync.net
#
# Adapted from Jeff Stafford's blog post:
# https://jstaf.github.io/2018/03/12/backups-with-borg-rsync.html

# Exit if any commands fail or any undefined variables are referenced
set -e

logfile="/var/log/borg-backup.log"

function log {
  printf "%s %s %s %s\n" "$(date -Iseconds)" "$(hostname)" "$1" "$2" >>${logfile}
}

function info {
  log "INFO " "$1"
}

function error {
  log "ERROR " "$1"
  exit 1
}

# Rotate log
if [ -f "${logfile}" ]; then
  mv "${logfile}" "${logfile}.1"
fi

#
# Verify required environment variables are set
#
if [ -z "${BORG_REPO}" ]; then
  error "BORG_REPO not set, aborting"
fi

if [ -z "${BORG_PASSPHRASE}" ]; then
  error "BORG_PASSPHRASE not set, aborting"
fi

if [ -z "${BORG_REMOTE_PATH}" ]; then
  error "BORG_REMOTE_PATH not set, aborting"
fi

#
# Do backup
#
cd /mnt/nas &> ${logfile}

info "performing backup to ${BORG_REPO}"
/usr/bin/borg create -v -C zlib "::$(hostname)-$(date -I)" ./storage >>${logfile} 2>&1

info "pruning old backups"
/usr/bin/borg prune "::$(hostname)-$(date -I)" --keep-daily=7 --keep-monthly=3 >>${logfile} 2>&1

info "backup complete"
