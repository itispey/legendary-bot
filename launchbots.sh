#!/usr/bin/env bash

echo "Running bots !"
sleep 0.5

cd /root/l/Bots/Alpha
screen -AmdS alpha ./launch.sh

echo "All Bots Running Successfully"
