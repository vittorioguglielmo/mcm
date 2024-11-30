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
dnow=$(date +%Y-%m-%d)
now="date +%H:%M:%S"
installation_log="/home/$user_name/installation-$dnow.log"



aggiorna_so() {

if [ -f "$installation_log" ] ; then
	rm $installation_log
fi



echo "Aggiornamento del sistema operativo">> $installation_log;
echo "===================================">> $installation_log;
echo >> $installation_log;

clear && sudo apt update -y && sudo apt upgrade -y
if [ $? -eq 0 ]; then
	echo
	echo
	echo -n "Aggiornamento del sistema operativo: " && printf "${green} OK ${clear}"
        echo
	echo "Aggiornamento del sistema operativo: OK alle "$(eval $now) >> $installation_log
	echo >> $installation_log
fi
echo
read -rsp $'Premi un tasto per continuare ...\n' -n1 key
rl1="OFF"
rl2="ON"
rl3="OFF"
rl4="OFF"
rl5="OFF"
main_menu
}

installa_get_accepted() {
echo
echo
wget -q https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/get-accepted.sh -O /home/$user_name/get-accepted.sh
sed -i "s/USERNAME/$user_name/g" /home/$user_name/get-accepted.sh
sed -i "s/LOG_LOCAL_PREFIX/$log_local_prefix/g" /home/$user_name/get-accepted.sh
chmod +x /home/$user_name/get-accepted.sh
if [ ! -L /usr/local/bin/get-accepted.sh ]; then
sudo ln -s /home/$user_name/get-accepted.sh /usr/local/bin/get-accepted.sh
fi

if [ $? -eq 0 ]; then
   echo -n "Installazione get-accepted: " && printf "${green} OK ${clear}"
   echo
   echo "Installazione get-accepted : OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi
}

installa_log() {
echo
echo
[[ -d /home/$user_name/archived_logs ]] || sudo mkdir /home/$user_name/archived_logs
if [ ! -f etc/logrotate_"$user_name"_conf ] || [ ! -f /etc/logrotate_"$apikey"_conf ]; then
wget -q https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/logrotate_USERNAME_conf -O /home/$user_name/logrotate_USERNAME_conf && \
sudo cp /home/$user_name/logrotate_USERNAME_conf /etc/logrotate_"$user_name"_conf && \
sudo sed -i "s/USERNAME/$user_name/g" /etc/logrotate_"$user_name"_conf && \
sudo sed -i "s/LOCALPREFIX/$log_local_prefix/g" /etc/logrotate_"$user_name"_conf && \

sudo cp /home/$user_name/logrotate_USERNAME_conf /etc/logrotate_"$apikey"_conf && \
sudo sed -i "s/USERNAME/$user_name/g" /etc/logrotate_"$apikey"_conf && \
sudo sed -i "s/LOCALPREFIX/$apikey/g" /etc/logrotate_"$apikey"_conf 
fi

if [ $? -eq 0 ]; then
   echo -n "Installazione logrotate: " && printf "${green} OK ${clear}"
   echo
   echo "Installazione logrotate : OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi

}


installa_crontab() {
echo
echo
line1="0 0 * * * /usr/sbin/logrotate /etc/logrotate_"$user_name"_conf"
line2="0 2 * * * /usr/sbin/logrotate /etc/logrotate_"$apikey"_conf"
if ! sudo crontab -l | grep -q "/etc/logrotate_"$user_name"_conf" ;then
(sudo crontab  -l; echo "$line1" ) | sudo crontab  -
fi

if ! sudo crontab -l | grep -q "/etc/logrotate_"$apikey"_conf" ;then
(sudo crontab  -l; echo "$line2" ) | sudo crontab  -
fi


if [ $? -eq 0 ]; then
   echo -n "Installazione crontab: " && printf "${green} OK ${clear}"
   echo
   echo "Installazione crontab : OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi

}

installa_miner_desktop() {
echo
echo
wget -q -O Miner.desktop https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/Miner.desktop
mv Miner.desktop /home/$user_name/.config/autostart
if [ $? -eq 0 ]; then
   echo -n "Installazione partenza automatica miner: " && printf "${green} OK ${clear}"
   echo
   echo "Installazione partenza automatica miner : OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi

}

installa_rustdesk_desktop() {
echo
echo
wget -q -O Rustdesk.desktop https://github.com/vittorioguglielmo/mcm/raw/refs/heads/main/Rustdesk.desktop
mv Rustdesk.desktop //home/$user_name/.config/autostart
if [ $? -eq 0 ]; then
   echo -n "Installazione partenza automatica Rustdesk: " && printf "${green} OK ${clear}"
   echo
   echo "Installazione partenza automatica Rustdesk : OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi
sleep 3
echo
}


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
    sudo apt install -y /tmp/rustdesk-1.3.2-x86_64.deb
else
    # Scarico Rustdesk con il link precedentemente generato 
    wget $DOWNLOAD_URL -O /tmp/rustdesk-x86_64.deb
    sudo apt install -y /tmp/rustdesk-x86_64.deb 
fi
if [ $? -eq 0 ]; then
	echo
	echo
        printf '%b\n' "Installato Rustdesk: ${green} OK ${clear}"
        echo "Installato Rustdesk : OK alle "$(eval $now) >> $installation_log
        echo >> $installation_log
fi
#if ! pgrep -f /usr/bin/rustdesk >/dev/null; then
bash -c "nohup /usr/bin/rustdesk &"
#fi

sleep 2
echo
read -rsp $'Premi un tasto per continuare ...\n' -n1 key
rl1="OFF"
rl2="OFF"
rl3="ON"
rl4="OFF"
rl5="OFF"
main_menu
}


finalizing_miner_installation() {
clear
echo "Esecuzione di install_new_OS_mcm300.sh interrotta con CTRL+C"
echo 
echo "Finalizzo installazione con update_300.sh"
echo
sleep 4
echo "Esecuzione di install_new_OS_mcm300.sh interrotta con CTRL+C alle "$(eval $now) >> $installation_log
echo >> $installation_log

wget -O update_300.sh https://hashburst.io/nodes/rigs/update_300.sh
sudo chmod +x update_300.sh
sudo bash ./update_300.sh $apikey $cluster

if [ $? -eq 0 ]; then
   printf '%b\n' "Update_300.sh completato con successo: ${green} OK ${clear}"
   sleep 2
   echo "Update_300.sh completato con successo: OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi

echo
read -rsp $'Premi un tasto per continuare ...\n' -n1 key
rl1="OFF"
rl2="OFF"
rl3="OFF"
rl4="ON"
rl5="OFF"
main_menu

unset finalizing_miner_installation
trap "$trap_sigint" SIGINT
return
}

installa_miner() {
trap_sigint="$(trap -p SIGINT)"
trap 'return' SIGINT 
clear 	

homesub="${apikey:0:4}"

while true; do
if [ -d "/home/mcm${homesub}/RainbowMiner" ] ; then
        read -p "Sembra che il miner sia già stato installato, vuoi reinstallarlo? [S/N]" yn
    case $yn in
        [Ss]* ) sudo rm -rf /home/mcm${homesub}/RainbowMiner;
		if [ $? -eq 0 ]; then
                printf '%b\n' "Rimozione directory Rainbowminer: ${green} OK ${clear}"
        	echo "Rimozione directory Rainbowminer: OK alle "$(eval $now) >> $installation_log
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

sudo bash ./install_new_OS_mcm300.sh $apikey $cluster

if [ $? = 130 ]; then
finalizing_miner_installation
        else
echo "Esecuzione di install_new_OS_mcm300.sh completata con successo"
echo 
echo "Finalizzo installazione con update_300.sh"
echo    
sleep 4
echo "Esecuzione di install_new_OS_mcm300.sh completata con successo alle "$(eval $now) >> $installation_log
echo >> $installation_log

wget -O update_300.sh https://hashburst.io/nodes/rigs/update_300.sh
sudo chmod +x update_300.sh
sudo bash ./update_300.sh $apikey $cluster

if [ $? -eq 0 ]; then
   printf '%b\n' "Update_300.sh completato con successo: ${green} OK ${clear}"
   sleep 2
   echo "Update_300.sh completato con successo: OK alle "$(eval $now) >> $installation_log
   echo >> $installation_log
   fi

echo
read -rsp $'Premi un tasto per continuare ...\n' -n1 key
rl1="OFF"
rl2="OFF"
rl3="OFF"
rl4="ON"
rl5="OFF"
main_menu
fi
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
echo
echo
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
start=$(whiptail --separate-output --title "Installazione MCM HASHBURST" --default-item 1 --radiolist "[ APIKEY: $apikey - CLUSTER: $cluster ] - Seleziona:" 0 0 5 \
  1 "Installa aggiornamenti" $rl1 \
  2 "Installa Rustdesk" $rl2 \
  3 "Installa il software di mining" $rl3 \
  4 "Installa add-on (log-rotation, crontab e automatismi)" $rl4 \
  5 "Reboot" $rl5 \
  6 "Esci" off \
  3>&1 1>&2 2>&3)

if [ -z "$start" ]; then
  echo "Nessuna opzione scelta (l'utente ha premuto Cancel)"
else
  for CHOICE in $start; do
    case "$CHOICE" in
    "1")
      echo;
      aggiorna_so
      ;;
    "2")
      echo "Installazione Rustdesk">> $installation_log;
      echo "======================">> $installation_log;
      echo >> $installation_log;
      installa_rustdesk
      ;;
    "3")
      echo "Installazione Miner HASHBURST">> $installation_log;
      echo "============================">> $installation_log;
      echo >> $installation_log;
      installa_miner
      ;;
    "4")
      echo "Installazione componenti aggiuntive">> $installation_log;
      echo "===================================">> $installation_log;
      echo >> $installation_log;
      installa_crontab;
      installa_log;
      installa_get_accepted;
#      installa_miner_desktop;
      installa_rustdesk_desktop;
      echo;
      read -rsp $'Premi un tasto per continuare ...\n' -n1 key;
      rl1="OFF";
      rl2="OFF";
      rl3="OFF";
      rl4="OFF";
      rl5="ON";
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

#SOSTITUISCO PLACEHOLDER con utente in sudoers e copio il file
sudo sh -c "echo '$user_name ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/dont-prompt-localuser-for-pwd"

rl1="ON"
rl2="OFF"
rl3="OFF"
rl4="OFF"
rl5="OFF"
main_menu
