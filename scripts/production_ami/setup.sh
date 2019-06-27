#!/bin/bash
sudo chown -R ec2-user /srv/app
cd /srv/app/
echo "Pull Repo"
git clone https://github.com/kelthuzadx/hosts.git
