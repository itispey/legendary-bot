# legendary-bot
An advanced Telegram group manager bot (Persian Language).

This bot has been forked from [Group Butler](https://github.com/group-butler/GroupButler) in 2015 and continued development until 2020.

The codes are not well-optimized. Some of them have been deprecated due to the Telegram API updates.

Also I can't update the codes since I'm busy these days so if you want to update them, feel free to create a new pull request.

# features
This bot has many cool features including:
- Delete media (gif, sticker, videos, etc.)
- Delete Ads
- Auto-lock group
- Anti pornographic
- Logs channel
- Filter words
- Anti-spam

# installation
First of all, create your bot in BotFather and disable the privacy. After that, create an `.env` file inside /Bots/Alpha.

The `.env` file should be like this:
```env
TG_TOKEN=123456789:ABCDefGhw3gUmZOq36-D_46_AMwGBsfefbcQ
SUPERADMINS=[12345678]
LOG_CHAT=12345678
LOG_ADMIN=12345678
```
The `TG_TOKEN` is your bot's token.

```
# Tested on Ubuntu 14.04, 15.04 and 16.04, Debian 7, Linux Mint 17.2

$ sudo apt-get update
$ sudo apt-get upgrade
$ sudo apt-get install libreadline-dev libssl-dev lua5.2 liblua5.2-dev git make unzip redis-server curl libcurl4-gnutls-dev

# We are going now to install LuaRocks and the required Lua modules

$ wget http://luarocks.org/releases/luarocks-2.2.2.tar.gz
$ tar zxpf luarocks-2.2.2.tar.gz
$ cd luarocks-2.2.2
$ ./configure; sudo make bootstrap
$ sudo luarocks install luasec
$ sudo luarocks install luasocket
$ sudo luarocks install redis-lua
$ sudo luarocks install lua-term
$ sudo luarocks install serpent
$ sudo luarocks install dkjson
$ sudo luarocks install lua-cjson
$ sudo luarocks install Lua-cURL
$ cd ..

$ git clone https://github.com/itispey/legendary-bot.git
$ cd legendary-bot/Bots/Alpha
$ sudo chmod +x launch.sh
$ sudo chmod +x polling.lua
```

Before start your bot make sure Redis (which is your database) is started.
```
$ sudo service redis-server start
```

For start the bot, type `./launch.sh` in terminal and press <kbd>CTRL</kbd>+<kbd>C</kbd> twice to shutdown the bot.

For adding multiple bots, copy Alpha folder and rename it to whatever you want. Then add the folder path to `launchbots.sh` and run all the bots with one command.

# enable anti pornographic
The anti pornographic feature is using [eugencepoi/nsfw_api](https://hub.docker.com/r/eugencepoi/nsfw_api/).
Follow the installation guide to enable anti pornographic feature.
