#!/bin/bash

# slack token from https://api.slack.com/docs/oauth-test-tokens
export SLACK_IKIOI_TOKEN=""

# channel name without '#' separated by ','
export SLACK_IKIOI_CHANNEL_NAMES="general,random,times_matsu_chara"

ruby slack_ikioi_png.rb
