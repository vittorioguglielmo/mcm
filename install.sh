#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
# Clear the color after that
clear='\033[0m'

user_name=$(whoami)
user_record="$(getent passwd $user_name)"
user_gecos_field="$(echo "$user_record" | cut -d ':' -f 5)"
user_full_name="$(echo "$user_gecos_field" | cut -d ',' -f 1)"
apikey=$user_full_name
cluster="mi"
akext=${user_name:(-4)}
log_local_prefix=$cluster$akext

installa_log() {
[[ -d /home/$user_name/archived_logs ]] || sudo mkdir /home/$user_name/archived_logs
if [ ! -f etc/logrotate_"$user_name"_conf ]; then
wget https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/logrotate_USERNAME_conf -O logrotate_USERNAME_conf
sudo cp logrotate_USERNAME_conf /etc/logrotate_"$user_name"_conf
sudo sed -i "s/USERNAME/$user_name/g" /etc/logrotate_"$user_name"_conf
sudo sed -i "s/LOCALPREFIX/$log_local_prefix/g" /etc/logrotate_"$user_name"_conf
fi
}


installa_crontab() {
line="*/1 * * * * /usr/sbin/logrotate /etc/logrotate_"$user_name"_conf"
if ! sudo crontab -l | grep -q "/etc/logrotate_"$user_name"_conf" ;then
(sudo crontab  -l; echo "$line" ) | sudo crontab  -
fi
}

#SOSTITUISCO PLACEHOLDER con utente in sudoers e copio il file
sudo sh -c "echo '$user_name ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/dont-prompt-localuser-for-pwd"

installa_rustdesk() {
# Scarico il JSON contentente le info sull'ultima versione di Rustdesk presente sulla repository GitHub
REQUEST=$(curl -s "https://api.github.com/repos/rustdesk/rustdesk/releases/latest")

# Estraggo dal JSON il link per scaricare l'ultima versione di Rustdesk per Linux Debian x86_64
DOWNLOAD_URL=$(echo "$REQUEST" | jq -r '.assets[] | select(.browser_download_url | contains("-x86_64.deb")) | .browser_download_url'|head -n 1)

# Controllo se sono riuscito a risolvere il link
if [ -z "$DOWNLOAD_URL" ]; then
    #In caso di errore scarica una versione obsoleta da un server default
    echo "Non è stato possibile scaricare l'ultima versione di Rustdesk"
    echo "Procedo con la versione di Rustdesk 1.3.2"
    sleep 6
    wget https://github.com/rustdesk/rustdesk/releases/download/1.3.2/rustdesk-1.3.2-x86_64.deb -O /tmp/rustdesk-1.3.2-x86_64.deb
    sudo apt install /tmp/rustdesk-1.3.2-x86_64.deb
else
    # Scarico Rustdesk con il link precedentemente generato 
    wget $DOWNLOAD_URL -O /tmp/rustdesk-x86_64.deb
    sudo apt install /tmp/rustdesk-x86_64.deb 
fi
}



installa_miner() {
clear 	
stty sane

homesub="${apikey:0:4}"

while true; do
if [ -d "/home/mcm${homesub}/RainbowMiner" ] ; then
        read -p "Sembra che il miner sia già stato installato, vuoi reinstallarlo? [S/N]" yn
    case $yn in
        [Ss]* ) sudo rm -rf /home/mcm${homesub}/RainbowMiner;
                break;;
        [Nn]* ) exit;;
        * ) echo "Rispondi [s]i o [n]";;
    esac
    	else break
fi
done

if  wget -q https://hashburst.io/nodes/rigs/install_new_OS_mcm300.sh -O install_new_OS_mcm300.sh  ;then printf '%b\n' "Scarico file di installazione: ${green} OK ${clear}"
else 
printf '%b\n' "Non sono riuscito a scaricare https://hashburst.io/nodes/rigs/install_new_OS_mcm300.sh: ${red} KO ${clear}"
fi
if chmod +x install_new_OS_mcm300.sh ; then printf '%b\n' "Garantisco permessi di esecuzione a install_new_OS_mcm300.sh: ${green} OK ${clear}"
echo
fi
sleep 3

finalizing_miner_installation() {
clear
echo "Esecuzione di install_new_OS_mcm300.sh interrotta con CTRL+C"
echo 
echo "Finalizzo installazione con update_300.sh"
echo
wget -O update_300.sh https://hashburst.io/nodes/rigs/update_300.sh
sudo chmod +x update_300.sh
sudo bash ./update_300.sh

while true; do
        read -p "Finalizzazione terminata, procedo con il reboot? [S/N]" yn
    case $yn in
        [Ss]* ) sudo reboot;
                break;;
        [Nn]* ) exit;;
        * ) echo "Rispondi [s]i o [n]";;
    esac
done

unset finalizing_miner_installation
trap "$trap_sigint" SIGINT
return
}

trap_sigint="$(trap -p SIGINT)"
trap "finalizing_miner_installation" SIGINT SIGTERM
script -c "sudo bash ./install_new_OS_mcm300.sh $apikey $cluster" output_miner_installation.txt
finalizing_miner_installation
}	

####Controllo se ho accesso a Internet

wget -q --spider http://google.com

if [ $? -eq 0 ]; then
    echo -n "Accesso a Internet " && printf "${green} OK ${clear}"
    echo
else
    echo -n "Accesso a Internet " && printf "${red} KO ${clear}"
    echo
    echo "Non hai accesso ad Internet, riprova dopo aver risolto" && exit 1
    echo
fi

main_menu() {
start=$(whiptail --separate-output --title "Installazione MCM Miner" --default-item 1 --radiolist "Select:" 0 0 5 \
  1 "Installa aggiornamenti" on \
  2 "Installa Rustdesk" off \
  3 "Installa il software di mining" off \
  4 "Installa add-on (log-rotation e crontab e altro)" off \
  5 "Esci" off \
  3>&1 1>&2 2>&3)

if [ -z "$start" ]; then
  echo "Nessuna opzione scelta (l'utente ha premuto Cancel)"
else
  for CHOICE in $start; do
    case "$CHOICE" in
    "1")
      clear && sudo apt update -y && sudo apt upgrade -y
      #sudo apt install -y rustdesk
      ;;
    "2")
      installa_rustdesk
      ;;
    "3")
      installa_miner
      ;;
    "4")
      installa_crontab;
      installa_log
      ;;
    *)
      echo "Unsupported item $CHOICE!" >&2
      exit 1
      ;;
    esac
  done
fi
}

main_menu
