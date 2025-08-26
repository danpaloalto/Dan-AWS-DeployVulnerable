#!/bin/bash

# Update and install base packages
apt-get update -y
apt-get install -y \
  python3 \
  python3-pip \
  curl \
  netcat \
  apache2 \
  ftp \
  telnet \
  vsftpd \
  unzip \
  git

# Create a vulnerable requirements.txt file
cat <<EOF > /home/ubuntu/requirements.txt
flask==0.12
requests==2.19.1
pyyaml==3.13
urllib3==1.24.2
django==1.11.1
EOF

# Install vulnerable Python packages
pip3 install -r /home/ubuntu/requirements.txt

# Enable Apache and start it
systemctl enable apache2
systemctl start apache2

# Create simple index.html for testing HTTP
echo "<h1>Vulnerable Demo Server</h1>" > /var/www/html/index.html
chown www-data:www-data /var/www/html/index.html

# Done
echo "Setup complete."
