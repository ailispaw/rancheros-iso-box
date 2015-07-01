#!/bin/sh

USERNAME=rancher
HOME_DIR=$(grep ^$USERNAME /etc/passwd | cut -f6 -d:)

if [ ! -d $HOME_DIR/.ssh ]; then
  mkdir -p $HOME_DIR/.ssh
  chmod 0700 $HOME_DIR/.ssh
fi

if [ ! -e $HOME_DIR/.ssh/authorized_keys ]; then
  touch $HOME_DIR/.ssh/authorized_keys
  chmod 0600 $HOME_DIR/.ssh/authorized_keys
fi

# Set Vagrant insecure private key at the first time
if ! grep -q "vagrant" $HOME_DIR/.ssh/authorized_keys; then
  cat <<KEY > $HOME_DIR/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key
KEY
fi

chown -R $USERNAME:$USERNAME $HOME_DIR/.ssh

# Disable SSH Password Authentication
if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
  echo "PasswordAuthentication no" >> /etc/ssh/sshd_config
fi

# Disable SSH Use DNS
if ! grep -q "^UseDNS no" /etc/ssh/sshd_config; then
  echo "UseDNS no" >> /etc/ssh/sshd_config
fi

labels=$(system-docker inspect -f '{{range $label, $value := .Config.Labels}} --label={{$label}}={{$value}} {{end}}' ntp)
system-docker rm -f ntp
system-docker run -d --name=ntp --restart=always --privileged --net=host ${labels} rancher/os-ntp:v0.3.2 ntpd -d
