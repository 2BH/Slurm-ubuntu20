#!/bin/bash

### BEGIN INFO
# Short-Description: script creates TMPDIR # Description:
# This script will create job's $TMPDIR and chown # to SLURM_JOB_USERi. chown will NOT work w/o sssd !
# TMPDIR must be set on USER lvl in task_prolog.sh !
# or w/o LDAP. Cleaned up by epilog.sh
#
# Author: JES
# date :  2014/05/05
# Create TMPDIR directory for job.
# TMPDIR will be cleaned up automatically after the job finished

echo export TMOUT=3600
#source /etc/profile

if [ "X${SLURM_JOB_ID}" != "X" ]; then

    export SLURM_TMPDIR="/tmp/slurm_${SLURM_JOB_ID}"
    if [ ! -d $SLURM_TMPDIR ]; then
        mkdir $SLURM_TMPDIR || logger "$0 mkdir $SLURM_TMPDIR failed"
        #chown $SLURM_JOB_USER:root $SLURM_TMPDIR || logger "$0 chown $SLURM_TMPDIR failed"
    fi
    echo export TMPDIR=$SLURM_TMPDIR
fi