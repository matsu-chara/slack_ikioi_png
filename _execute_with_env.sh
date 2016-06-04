#!/bin/bash

# slack token from https://api.slack.com/docs/oauth-test-tokens
export SLACK_IKIOI_TOKEN=""

# channel name without '#'
export SLACK_IKIOI_CHANNEL_NAME="general"

ruby slack_ikioi_png.rb
