#!/bin/bash


##########INSTALLAZIONE RUSTDESK#########
#
Scarico il JSON contentente le info sull'ultima versione di Rustdesk presente sulla repository GitHub
REQUEST=$(curl -s "https://api.github.com/repos/rustdesk/rustdesk/releases/latest")


# Estraggo dal JSON il link per scaricare l'ultima versione di Rustdesk per Linux Debian x86_64
DOWNLOAD_URL=$(echo "$REQUEST" | jq -r '.assets[] | select(.browser_download_url | contains("-x86_64.deb")) | .browser_download_url'|head -n 1)

# Controllo se sono riuscito a risolvere il link
if [ -z "$DOWNLOAD_URL" ]; then
    #In caso di errore scarica una versione obsoleta da un server default
    echo "Non è stato possibile scaricare l'ultima versione di Rustdesk"
    echo "Procedo con la versione di Rustdesk 1.3.2"
    sleep 6
    wget https://github.com/rustdesk/rustdesk/releases/download/1.3.6/rustdesk-1.3.6-x86_64.deb -O /tmp/rustdesk-1.3.6-x86_64.deb

    sudo apt install -y /tmp/rustdesk-1.3.6-x86_64.deb
else
    # Scarico Rustdesk con il link precedentemente generato
    wget $DOWNLOAD_URL -O /tmp/rustdesk-x86_64.deb
    sudo apt install -y /tmp/rustdesk-x86_64.deb
fi
if [ $? -ne 0 ]; then
        echo
        echo "An error occured while downloading and installing Rustdesk"
fi
bash -c "nohup /usr/bin/rustdesk &"

cat > /home/$(whoami)/.config/autostart/Rustdesk.desktop << EOF
[Desktop Entry]
Type=Application
Name=Rustdesk
Exec=nohup /usr/bin/rustdesk &
EOF

###########################################


sudo rm -- $0
