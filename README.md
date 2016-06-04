# slack_hist_png

draw channel message count per day/wday/hour

![all.png](https://raw.githubusercontent.com/matsu-chara/slack_hist_png/images/all.png)

count upper limit(per day) is 1000, because of slack api limitation.

# INSTALLATION

```bash
brew install imagemagick
bundle install

cp _execute_with_env.sh execute_with_env.sh

# write your token to execute_with_env.sh
vim execute_with_env.sh
```

# USAGE

```bash
./execute_with_env.sh && open all.png
```
