#!/usr/bin/env bash

#!/bin/bash
set -e

# Set correct permissions for mount Windows drive
sudo tee /etc/wsl.conf > /dev/null <<'EOF'
[boot]
systemd=true
[automount]
enabled = true
options = "metadata,umask=0077,fmask=0077"
EOF


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mUpdate apt\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstall core packages\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install \
  apt-transport-https \
  ca-certificates \
  lsb-release \
  systemd-timesyncd \
  gnupg \
  curl \
  wget \
  software-properties-common \
  build-essential \
  make \
  procps \
  file \
  gcc \
  git \
  gettext \
  unzip \
  jq \
  bash \
  bash-completion \
  tldr \
  nano \
  xclip \
  openssl \
  gnupg-agent \
  inetutils-traceroute \
  tcpdump \
  openssh-client \
  xdg-utils

# Fix time sync issues in WSL
# https://github.com/microsoft/WSL/issues/8204#issuecomment-1338334154
sudo mkdir -p /etc/systemd/system/systemd-timesyncd.service.d
sudo tee /etc/systemd/system/systemd-timesyncd.service.d/override.conf > /dev/null <<'EOF'
[Unit]
ConditionVirtualization=
EOF
sudo systemctl start systemd-timesyncd



# Fix landscape-sysinfo.cache error in WSL
# https://askubuntu.com/questions/1414483/landscape-sysinfo-cache-permission-denied-when-i-start-ubuntu-22-04-in-wsl
sudo DEBIAN_FRONTEND=noninteractive apt-get --assume-yes remove landscape-common
rm -f ~/.motd_shown

echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mAdding PPA for WSLU \e[0m"
sudo add-apt-repository -y ppa:wslutilities/wslu

echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstall Microsoft Packages source\e[0m"
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm -f packages-microsoft-prod.deb

sudo tee /etc/apt/preferences > /dev/null <<'EOF'
Package: dotnet-sdk-7.0
Pin: origin "packages.microsoft.com"
Pin-Priority: 999
EOF

sudo tee /usr/lib/binfmt.d/WSLInterop.conf > /dev/null <<'EOF'
:WSLInterop:M::MZ::/init:PF
EOF


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstall docker GPG keys\e[0m"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstall python deadsnakes PPA\e[0m"
sudo add-apt-repository -y ppa:deadsnakes/ppa


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstall Hashicorp GPG keys\e[0m"
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo DEBIAN_FRONTEND=noninteractive apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mUpdate apt based on new repos\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq update

echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstalling common tools via apt\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yq install \
  dotnet-sdk-7.0 \
  powershell \
  python3.11 \
  python3.11-venv \
  python3-pip \
  python3-crcmod \
  virtualenv \
  packer \
  wslu


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mUpgrade packages from apt\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
echo ''

sudo pwsh -NoProfile -Command - <<'EOF'
Install-Module -Name PowerShellGet -RequiredVersion 3.0.21-beta21 -Force -AllowPrerelease -Scope AllUsers
Set-PSResourceRepository -Name PSGallery -Trusted

Install-Module AWS.Tools.Installer -Scope AllUsers -Force
Install-AWSToolsModule AWS.Tools.SecurityToken,AWS.Tools.SSO,AWS.Tools.SSOOIDC,AWS.Tools.EC2,AWS.Tools.S3,AWS.Tools.SimpleNotificationService,AWS.Tools.SQS,AWS.Tools.DynamoDBv2 -CleanUp -Scope AllUsers -Force

Install-PSResource PSReadLine -Reinstall -Scope AllUsers
Install-PSResource Powershell-yaml -Reinstall -Scope AllUsers
Install-PSResource posh-git -Reinstall -Scope AllUsers
Install-PSResource PowerShellForGitHub -Reinstall -Scope AllUsers
Install-PSResource ImportExcel -Reinstall -Scope AllUsers
cls
EOF




echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mClean up packages from apt\e[0m"
sudo DEBIAN_FRONTEND=noninteractive apt-get --yes -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" auto-remove
echo ''



echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstalling HomeBrew\e[0m"
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
source ~/.bash_profile


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInstalling brew formulas\e[0m"
HOMEBREW_NO_ENV_HINTS=1 HOMEBREW_NO_INSTALL_CLEANUP=1 /home/linuxbrew/.linuxbrew/bin/brew install yq \
  gh \
  git \
  pulumi \
  docker-compose \
  kubectl \
  helm \
  istioctl \
  kustomize \
  oh-my-posh \
  awscli \
  eksctl \
  nvm \
  yarn \
  node \
  go \
  goreleaser \
  yt-dlp


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mInitialize .npmrc file\e[0m"
cat > ~/.npmrc <<'EOF'
//npm.pkg.github.com/:_authToken=${ALI_GITHUB_PACKAGE_READER_TOKEN}
EOF

echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mConfigure docker group\e[0m"
sudo addgroup --system docker
sudo adduser $USER docker
if [ -S /var/run/docker.sock ]
then
  sudo chown root:docker /var/run/docker.sock
  sudo chmod g+w /var/run/docker.sock
fi


echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mCreate symlinks to host\e[0m"
rm -rf ~/.kube
mkdir -p ~/.kube
ln -sf $USERPROFILE/.kube/config $HOME/.kube/config
rm -rf ~/.aws
ln -sf $USERPROFILE/.aws $HOME/.aws

echo ''
echo -e "\e[1;36m------\e[0m"
echo -e "\e[1;36mAdding permissions for docker\e[0m"
sudo addgroup --system docker
sudo adduser $USER docker
if [ ! -S /var/run/docker.sock ]
then
  sudo ln -sf /mnt/wsl/rancher-desktop/run/docker.sock /var/run/docker.sock
fi

if [ -S /var/run/docker.sock ]
then
  sudo chown root:docker /var/run/docker.sock
  sudo chmod g+w /var/run/docker.sock
fi
sudo curl https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o /etc/bash_completion.d/docker.sh

# Initialize ssh-agent
# https://unix.stackexchange.com/questions/339840/how-to-start-and-use-ssh-agent-as-systemd-service
systemctl --user enable --now ssh-agent

echo ''
echo -e "\e[1;32m------\e[0m"
echo -e "\e[1;32mOS Initialization Complete\e[0m"
