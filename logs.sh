#!/bin/sh

. ./.env

$CLI_COMMAND compose logs is-$1-server -f