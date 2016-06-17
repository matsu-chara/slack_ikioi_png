#!/bin/bash

# slack token from https://api.slack.com/docs/oauth-test-tokens
export SLACK_IKIOI_TOKEN=""

# fetch days
export SLACK_IKIOI_FETCH_LENGTH="30"

# channel name without '#' separated by ','
export SLACK_IKIOI_CHANNEL_NAMES="general,random,times_matsu_chara"
#export SLACK_IKIOI_CHANNEL_NAMES="times_.*"

ruby slack_ikioi_png.rb
