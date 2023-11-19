#!/bin/bash
    echo "helloworld" > /tmp/test
    apt-get update
    apt-get install -y ca-certificates curl gnupg git-all net-tools make
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
    apt-get update -y
    apt-get install nodejs -y
    npm install --global yarn
    apt-get update -y
    apt-get install ca-certificates curl gnupg -y
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    git clone https://github.com/dangdh16/platform_eng_sdc.git
    cd platform_eng_sdc/backstage
    yarn install
    sed -i "s/<CHANGE_ME_IP>/$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')/g" app-config.yaml
    sed -i "s/<CHANGE_ME_PUBLIC>/$(curl -s ip.me)/g" app-config.yaml
    sed -i "s/<DATABASE_BACKSTAGE>/$(database_address)/g" app-config.yaml
    nohup yarn dev > /dev/null 2>&1 &
    echo "bye" >> /tmp/test