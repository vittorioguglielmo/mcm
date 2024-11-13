#!/bin/bash

user_name=$(whoami)
user_record="$(getent passwd $user_name)"
user_gecos_field="$(echo "$user_record" | cut -d ':' -f 5)"
user_full_name="$(echo "$user_gecos_field" | cut -d ',' -f 1)"
echo "$user_name ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dont-prompt-localuser-for-pwd 
start=$(whiptail --separate-output --title "Installazione MCM Miner" --default-item 1 --radiolist "Select:" 0 0 5 \
  1 "Installa aggiornamenti" on \
  2 "Installa il software di mining" off \
  3 "Riporta il sistema a vergine" off \
  3>&1 1>&2 2>&3)

if [ -z "$start" ]; then
  echo "Nessuna opzione scelta (l'utente ha premuto Cancel)"
else
  for CHOICE in $start; do
    case "$CHOICE" in
    "1")
      #echo "Option 1 was selected"
      clear && apt update -y && apt upgrade -y
      ;;
    "2")
      echo "Option 2 was selected"
      ;;
    "3")
      echo "Option 3 was selected"
      ;;
    "4")
      echo "Option 4 was selected"
      ;;
    *)
      echo "Unsupported item $CHOICE!" >&2
      exit 1
      ;;
    esac
  done
fi
