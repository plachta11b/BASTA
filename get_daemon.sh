#!/bin/bash

COMMAND_DOCKER="${COMMAND_DOCKER:-docker}"
COMMAND_SINGULARITY="${COMMAND_SINGULARITY:-singularity}"

$COMMAND_DOCKER -v > /dev/null 2>&1

if [ $? -eq 0 ];
then
	echo "daemon=\"docker\"; daemon_command=\"$COMMAND_DOCKER\""
	exit 0
fi

$COMMAND_SINGULARITY --version > /dev/null 2>&1

if [ $? -eq 0 ];
then
	echo "daemon=\"singularity\"; daemon_command=\"$COMMAND_SINGULARITY\""
	exit 0
fi

echo "daemon=\"error\"; daemon_command=\"echo "invalid daemon command"; exit 1;\""
exit 1
