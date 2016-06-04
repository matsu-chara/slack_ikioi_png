# slack_hist_png

draw channel message count per day/wday/hour

![all.png](https://raw.githubusercontent.com/matsu-chara/slack_hist_png/images/all.png)

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
