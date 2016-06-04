#!/bin/bash

export SLACK_IKIOI_TOKEN=""

# channel idは https://api.slack.com/methods/channels.list/test でTest Methodボタンを押すと取れる
export SLACK_IKIOI_CHANNEL_ID=""
export SLACK_IKIOI_CHANNEL_NAME=""

ruby slack_ikioi_png.rb
