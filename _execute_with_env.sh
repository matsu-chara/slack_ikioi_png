#!/bin/bash

# channel idは https://api.slack.com/methods/channels.list/test でTest Methodボタンを押すと取れる
export SLACK_IKIOI_CHANNEL_ID=""
export SLACK_IKIOI_CHANNEL_NAME=""
export SLACK_IKIOI_TOKEN=""

ruby slack_ikioi_png.rb
