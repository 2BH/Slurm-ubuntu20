#!/bin/bash

### BEGIN INFO
# Short-Description: script to clean up AFTER job terminates # Description:
# This script will remove job's $TMPDIR independently whether job # has finished or crashed. Processes that may still hang around and # block deletion with open files will be found by lsof and killed.
# Pseudo-Zombies will be spottet and killed. This is to prevent # draining of node due to "Epilog error". This part can be used # as a cron job to clean node regularly.
#
# In case of a VM host the OS will initiate reboot/shutdown # according to RebootProgram as configured in slurm.conf to allow # dynamic use of VM resources # # Author: AJG <gamel@uni-freiburg.de>
#         STST
# date :  2015/03/19
# last changes:
# 2015/03/21  AJG  commented VM reboot, OpenStack schedule not ready # 2015/03/24  AJG  minor changes/comments # 2015/03/24  AJG  added feature to delete inactive SLURM TMPDIRs # 2015/03/26  AJG  added loggers # 2019/04/03  STST adjusted for KISLURM # ### END INFO

#
# VARIABLES
#

VERSION=0.9.0

OPEN_PIDS=
BAD_PARENT_PID=
BAD_PIDS=
TMPDIRTODELETE=
export TMPDIRTODELETE="/tmp/slurm_${SLURM_JOB_ID}"

# Exit if not running on test node
#if [ $(hostname) != "metaex01" ] ; then
#    exit 0
#fi