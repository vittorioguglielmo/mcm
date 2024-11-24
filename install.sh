#!/bin/bash
#
# aprire xterm con log installazione

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
dnow=$(date +%Y-%m-%d-%H:%M)
installation_log="installation-$dnow.log"


if [ -f "$installation_log" ] ; then
	rm $installation_log
fi

installa_log() {
[[ -d /home/$user_name/archived_logs ]] || sudo mkdir /home/$user_name/archived_logs
if [ ! -f etc/logrotate_"$user_name"_conf ]; then
wget -q https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/logrotate_USERNAME_conf -O logrotate_USERNAME_conf
sudo cp logrotate_USERNAME_conf /etc/logrotate_"$user_name"_conf
sudo sed -i "s/USERNAME/$user_name/g" /etc/logrotate_"$user_name"_conf
sudo sed -i "s/LOCALPREFIX/$log_local_prefix/g" /etc/logrotate_"$user_name"_conf

sudo cp logrotate_USERNAME_conf /etc/logrotate_"$apikey"_conf
sudo sed -i "s/USERNAME/$user_name/g" /etc/logrotate_"$apikey"_conf
sudo sed -i "s/LOCALPREFIX/$apikey/g" /etc/logrotate_"$apikey"_conf
fi
}


installa_crontab() {
echo
echo
line="*/1 * * * * /usr/sbin/logrotate /etc/logrotate_"$user_name"_conf"
if ! sudo crontab -l | grep -q "/etc/logrotate_"$user_name"_conf" ;then
(sudo crontab  -l; echo "$line" ) | sudo crontab  -
fi

if [ $? -eq 0 ]; then
   printf '%b\n' "Crontab installato: ${green} OK ${clear}"
   echo "Crontab installato con successo: OK" >> $installation_log
   echo >> $installation_log
   fi

}

installa_miner_desktop() {
echo
echo
wget -q -O Miner.desktop https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/Miner.desktop
mv Miner.desktop /home/$user_name/.config/autostart
if [ $? -eq 0 ]; then
   printf '%b\n' "Partenza automatica miner: ${green} OK ${clear}"
   echo "Partenza automatica miner installata con successo: OK" >> $installation_log
   echo >> $installation_log
   fi

}

installa_rustdesk_desktop() {
echo
echo
wget -q -O Rustdesk.desktop https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/Rustdesk.desktop
mv Rustdesk.desktop //home/$user_name/.config/autostart
if [ $? -eq 0 ]; then
   printf '%b\n' "Partenza automatica Rustdesk: ${green} OK ${clear}"
   echo "Partenza automatica Rustdesk installata con successo: OK" >> $installation_log
   echo >> $installation_log
   fi
sleep 3
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
if [ $? -eq 0 ]; then
        printf '%b\n' "Installato Rustdesk: ${green} OK ${clear}"
        echo "Installato Rustdesk : OK" >> $installation_log
        echo >> $installation_log
fi
sleep 2
main_menu
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
		if [ $? -eq 0 ]; then
                printf '%b\n' "Rimozione directory Rainbowminer: ${green} OK ${clear}"
        	echo "Rimozione directory Rainbowminer: OK" >> $installation_log
        	echo >> $installation_log
      		fi
                break;;
        [Nn]* ) echo "Uscita dal programma evitando la rimozione della directory di RainbowMiner: OK" >> $installation_log;
		echo >> $installation_log;
		exit;;
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
sleep 2
echo "Esecuzione di install_new_OS_mcm300.sh interrotta con CTRL+C" >> $installation_log
echo >> $installation_log

wget -O update_300.sh https://hashburst.io/nodes/rigs/update_300.sh
sudo chmod +x update_300.sh
sudo bash ./update_300.sh $apikey $cluster

if [ $? -eq 0 ]; then
   printf '%b\n' "Update_300.sh completato con successo: ${green} OK ${clear}"
   sleep 2
   echo "Update_300.sh completato con successo: OK" >> $installation_log
   echo >> $installation_log
   fi


unset finalizing_miner_installation
trap "$trap_sigint" SIGINT
return
}

trap_sigint="$(trap -p SIGINT)"
trap "finalizing_miner_installation" SIGINT SIGTERM
script -c "sudo bash ./install_new_OS_mcm300.sh $apikey $cluster" output_miner_installation.txt
finalizing_miner_installation
main_menu
}	

reboot() {
	
while true; do
        read -p "Finalizzazione terminata, procedo con il reboot? [S/N]" yn
    case $yn in
        [Ss]* ) sudo reboot;
                break;;
        [Nn]* ) exit;;
        * ) echo "Rispondi [s]i o [n]";;
    esac
done
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
#export NEWT_COLORS='
#window=,red
#border=white,red
#textbox=white,red
#button=black,white
#'
export NEWT_COLORS='
  root=white,black
    border=black,lightgray
    window=lightgray,lightgray
    shadow=black,gray
    title=blue,lightgray
    button=black,red
    actbutton=white,red
    compactbutton=black,lightgray
    checkbox=black,lightgray
    actcheckbox=lightgray,red
    entry=black,lightgray
    disentry=gray,lightgray
    label=black,lightgray
    listbox=black,lightgray
    actlistbox=black,red
    sellistbox=lightgray,black
    actsellistbox=lightgray,black
    textbox=black,lightgray
    acttextbox=black,red
    emptyscale=,gray
    fullscale=,red
    helpline=white,black
    roottext=lightgrey,black
'
#start=$(whiptail --separate-output --title "Installazione MCM  - APIKEY: $apikey - CLUSTER: $cluster -" --default-item 1 --radiolist "Select:" 0 0 5 \
start=$(whiptail --separate-output --title "Installazione MCM HASHBURST" --default-item 1 --radiolist "[APIKEY: $apikey - CLUSTER: $cluster] - Seleziona:" 0 0 5 \
  1 "Installa aggiornamenti" on \
  2 "Installa Rustdesk" off \
  3 "Installa il software di mining" off \
  4 "Installa add-on (log-rotation, crontab e automatismi)" off \
  5 "Reboot" off \
  6 "Esci" off \
  3>&1 1>&2 2>&3)

if [ -z "$start" ]; then
  echo "Nessuna opzione scelta (l'utente ha premuto Cancel)"
else
  for CHOICE in $start; do
    case "$CHOICE" in
    "1")
      clear && sudo apt update -y && sudo apt upgrade -y
      if [ $? -eq 0 ]; then
    	printf '%b\n' "Aggiornato il sistema operativo: ${green} OK ${clear}"
	echo "Aggiornato sistema operativo: OK" >> $installation_log
	echo >> $installation_log
      fi
      sleep 2 && main_menu
      ;;
    "2")
      installa_rustdesk
      ;;
    "3")
      installa_miner
      ;;
    "4")
      installa_crontab;
      installa_log;
      installa_miner_desktop;
      installa_rustdesk_desktop
      main_menu
      ;;
    "5")
      reboot
      ;;
    "6")
      exit 0
      ;;
    *)
      echo "Scelta non supportata: $CHOICE!" >&2
      main_menu
      ;;
    esac
  done
fi
}

main_menu
