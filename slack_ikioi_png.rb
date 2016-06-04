# frozen_string_literal: true

require 'slack'
require 'date'
require 'json'
require 'gruff'

CHANNEL_ID = ENV["SLACK_IKIOI_CHANNEL_ID"]
CHANNEL_NAME = ENV["SLACK_IKIOI_CHANNEL_NAME"]
TOKEN = ENV["SLACK_IKIOI_TOKEN"]

FETCH_LENGTH = 30
START_DATE = Date.today - FETCH_LENGTH

# slackから指定チャンネル・指定日(0~23:59)の発言タイムスタンプを取ってくる
def _fetch_message_timestamps_in_a_day(client, channel_id, date)
  client.channels_history(
    channel: channel_id,
    oldest:  date.to_time.to_i,
    latest:  (date + 1).to_time.to_i,
    count:   1000
  )['messages'].map { |m| Time.at(m['ts'].to_f) }
end

# 指定日からdate_length日間のtimestampの配列を返す
# '5月28日', 7日間を渡す => 5月28日 ~ 6月3日の発言を取得する
def fetch_message_timestamps(client, channel_id, start_date, length)
  end_date = (start_date + length - 1)
  (start_date..end_date).reduce([]) do |acc, date|
    stamps = _fetch_message_timestamps_in_a_day(client, channel_id, date)
    acc.concat(stamps)
  end
end

# 指定間隔ごとの発言数が入った配列
def _make_timestamp_sizes(timestamps, range, group_hash)
  empty_sizes = range.reduce({}) { |a, e| a.merge(e => 0) }
  raw_sizes = timestamps.group_by(&group_hash).reduce({}) do |a, (k, v)|
    a.merge(k => v.length)
  end
  empty_sizes.merge(raw_sizes).values
end

# メッセージのタイムスタンプ配列を日ごとに集計
def day_label_and_data(timestamps, start_date, length)
  end_date = (start_date + length - 1)
  label = (start_date..end_date).each_with_index.reduce({}) do |acc, (e, index)|
    acc.merge(index => e.strftime('%m/%d'))
  end
  message_sizes = _make_timestamp_sizes(timestamps,
                                        (start_date..end_date).map(&:day),
                                        :day)

  raise '日の長さがおかしい' if message_sizes.length != length && label.length != length

  [label, message_sizes]
end

# メッセージのタイムスタンプ配列を曜日ごとに集計
def wday_label_and_data(timestamps)
  label = {
    0 => 'Sun', 1 => 'Mon', 2 => 'Tue', 3 => 'Wed',
    4 => 'Thu', 5 => 'Fri', 6 => 'Sat'
  }
  message_sizes = _make_timestamp_sizes(timestamps, 0..6, :wday)
  raise '曜日の長さがおかしい' if message_sizes.length != 7 && label.length != 7

  [label, message_sizes]
end

# メッセージのタイムスタンプ配列を時間ごとに集計
def hour_label_and_data(timestamps)
  label = (0..23).each_with_index.reduce({}) do |acc, (e, index)|
    acc.merge(index => e)
  end

  message_sizes = _make_timestamp_sizes(timestamps, 0..23, :hour)

  raise '日時の長さがおかしい' if message_sizes.length != 24 && label.length != 24

  [label, message_sizes]
end

client = Slack::Client.new token: TOKEN
message_times = fetch_message_timestamps(
  client, CHANNEL_ID, START_DATE, FETCH_LENGTH
)

# render each_day
g = Gruff::Bar.new(800)
g.title = "ikioi #{CHANNEL_NAME} per day"
labels, data = day_label_and_data(message_times, START_DATE, FETCH_LENGTH)
g.labels = labels.select { |k, _| k % 4 == 0 }
g.data(CHANNEL_NAME, data)
g.write('day.png')

# render each wday
g = Gruff::Bar.new(800)
g.title = "ikioi #{CHANNEL_NAME} per wday"
labels, data = wday_label_and_data(message_times)
g.labels = labels
g.data(CHANNEL_NAME, data)
g.write('wday.png')

# render each wday
g = Gruff::Bar.new(800)
g.title = "ikioi #{CHANNEL_NAME} per hour"
labels, data = hour_label_and_data(message_times)
g.labels = labels
g.data(CHANNEL_NAME, data)
g.write('hour.png')

exec("convert -append day.png wday.png hour.png all.png")
