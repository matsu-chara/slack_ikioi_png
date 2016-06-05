# frozen_string_literal: true

require 'slack'
require 'date'
require 'fileutils'
require 'gruff'

TOKEN = ENV['SLACK_IKIOI_TOKEN']
CHANNEL_NAMES = ENV['SLACK_IKIOI_CHANNEL_NAMES'].split(',')

FETCH_LENGTH = 30
START_DATE = Date.today - FETCH_LENGTH

# チャンネル名 => チャンネルIDのハッシュを取得する
def fetch_channel_id_hash(client)
  client.channels_list(
    exclude_archived: 1
  )['channels'].reduce({}) { |a, e| a.merge(e['name'] => e['id']) }
end

# slackから指定チャンネル・指定日(0~23:59)の発言タイムスタンプを取ってくる
def _fetch_message_timestamps_in_a_day(client, channel_id, date)
  stamps = client.channels_history(
    channel: channel_id,
    oldest:  date.to_time.to_i,
    latest:  (date + 1).to_time.to_i,
    count:   1000
  )['messages'].map { |m| Time.at(m['ts'].to_f) }

  # API上限で1000件しか取れないため1日に1000件以上の発言があるといくつか取りこぼす。
  # その場合、ある程度欠損した結果を出力するので警告を出しておく。
  if stamps.length >= 1000
    puts "warn: channel_id = #{channel_id} has over 1000 msg in a day"
  end
  stamps
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
def wday_label_and_data(timestamps, start_date, length)
  end_date = (start_date + length - 1)

  label = {
    0 => 'Sun', 1 => 'Mon', 2 => 'Tue', 3 => 'Wed',
    4 => 'Thu', 5 => 'Fri', 6 => 'Sat'
  }
  message_sizes = _make_timestamp_sizes(timestamps, 0..6, :wday)

  # ある曜日における発言量の合計を、ある曜日の平均発言量に変換する
  message_sizes_in_a_day = message_sizes.map.with_index do |e, i|
    # 集計期間にi曜日が含まれる回数で割る
    e.to_f / ((start_date..end_date).count { |x| x.wday == i })
  end

  raise '曜日の長さがおかしい' if message_sizes_in_a_day.length != 7 && label.length != 7

  [label, message_sizes_in_a_day]
end

# メッセージのタイムスタンプ配列を時間ごとに集計
def hour_label_and_data(timestamps, fetch_length)
  label = (0..23).each_with_index.reduce({}) do |acc, (e, index)|
    acc.merge(index => e)
  end

  message_sizes = _make_timestamp_sizes(timestamps, 0..23, :hour)

  # ある時間における発言量の合計を、ある時間の平均発言量に変換する
  message_sizes_in_a_day = message_sizes.map { |e| e.to_f / fetch_length }

  raise '時の長さがおかしい' if message_sizes_in_a_day.length != 24 && label.length != 24

  [label, message_sizes_in_a_day]
end

# make result directory if not exists
FileUtils.mkdir_p 'result'

client = Slack::Client.new token: TOKEN
channel_id_hash = fetch_channel_id_hash(client)

CHANNEL_NAMES.each do |channel_name|
  p channel_name
  message_times = fetch_message_timestamps(
    client, channel_id_hash[channel_name], START_DATE, FETCH_LENGTH
  )

  # render each_day
  labels, data = day_label_and_data(message_times, START_DATE, FETCH_LENGTH)
  g = Gruff::Bar.new(800)
  g.title = "ikioi #{channel_name} per day"
  g.labels = labels.select { |k, _| k % 4 == 0 }
  g.data(channel_name, data)
  g.write("result/#{channel_name}_day.png")

  # render each wday
  labels, data = wday_label_and_data(message_times, START_DATE, FETCH_LENGTH)
  g = Gruff::Bar.new(800)
  g.title = "ikioi #{channel_name} per wday"
  g.labels = labels
  g.data(channel_name, data)
  g.write("result/#{channel_name}_wday.png")

  # render each wday
  labels, data = hour_label_and_data(message_times, FETCH_LENGTH)
  g = Gruff::Bar.new(800)
  g.title = "ikioi #{channel_name} per hour"
  g.labels = labels
  g.data(channel_name, data)
  g.write("result/#{channel_name}_hour.png")

  system(
    "convert -append \
    result/#{channel_name}_day.png \
    result/#{channel_name}_wday.png \
    result/#{channel_name}_hour.png \
    result/#{channel_name}_all.png"
  )
end

p 'summary'
all_pngs = CHANNEL_NAMES.map { |c| "result/#{c}_all.png" }.join(' ')
system(
  "convert +append \
  #{all_pngs} \
  result/summary.png"
)
