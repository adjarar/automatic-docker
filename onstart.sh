#!/bin/bash

wget https://raw.githubusercontent.com/adjarar/automatic-user-files/main/load_models.sh
chmod +x load_models.sh.sh
mv load_models.sh /home/webui

# Switch to the webui user
su -s /bin/bash webui << 'EOF'

cd ~
bash load_models.sh

EOF
