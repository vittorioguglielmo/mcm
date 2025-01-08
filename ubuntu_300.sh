#!/bin/bash

### SETTING UP SCRIPT'S VARIABLES
# Getting first 2 chars of the cluster and APIKEY from Username and Login name
CLUSTER=$(hostname | cut -c 1-2)
MACHINE_TYPE="mcm"
LOGIN_NAME=$MACHINE_TYPE$(hostname | cut -c 3-6)
APIKEY=$(getent passwd $LOGIN_NAME | cut -d ':' -f 5 | tr -dc '[:alnum:][:space:]')

# Setting download links
host="hashburst.io/nodes/test"
rainbowminer_sh_link="$host/RainbowMiner/rainbowminer.sh"
wifi_sh_link="$host/wifi.sh"
setup="$host/mcm/setup1.json"

# Assigning files' name to variables
filename1="${APIKEY}"
filename2="${CLUSTER}${filename1:0:4}"

### AUTOLOGIN SETUP
# Check if user exist
if id "$LOGIN_NAME" &>/dev/null; then
    echo "Autologin configuration for: $LOGIN_NAME"
else
    echo "Error: user $LOGIN_NAME does not exist."
    exit 1
fi

# Set Autologin
AUTOLOGIN_SERVICE="/etc/systemd/system/getty@tty1.service.d/override.conf"

# Make directory if not existent
if ! sudo mkdir -p "$(dirname "$AUTOLOGIN_SERVICE")"; then
    echo "An error occured while creating folder $(dirname $AUTOLOGIN_SERVICE)"
    exit 1
fi

# Setting up autologin file
sudo bash -c "cat > $AUTOLOGIN_SERVICE" <<EOL
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $LOGIN_NAME --noclear %I \$TERM
EOL

# Reloading system deamons
sudo systemctl daemon-reload
echo "Autologin successfully configured for user: $LOGIN_NAME."

### UPDATING AND INSTALLING REQUIRED PACKAGES
# Be sure to be in the right directory
if ! cd /home/$LOGIN_NAME; then
    echo "Couldn't find /home/$LOGIN_NAME"
    exit 1
fi

# Downloads wifi.sh Script
if ! wget -O wifi.sh $wifi_sh_link; then
    echo "An error occured while trying to download wifi.sh"
    echo "Continuing script..."
    sleep 5
else
    if ! sudo chmod +x wifi.sh; then
        echo "An error occured while giving execution permissions to wifi.sh"
        exit 1
    else
        # Ask if the user wants to connect to a wifi network
        read -p "Do you want to execute the script for Wifi connection now? (Yes/No)" wifi
        if [[ "${wifi,,}" == "y" || "${wifi,,}" == "yes" ]]; then
            sudo bash wifi.sh
        fi
    fi
    
fi


# Update repositories
if ! sudo apt-get update; then
    echo "An error occured while updating System Packages List."
    exit 1
fi

# Complete uncofigured packages
if ! sudo dpkg --configure -a; then
    echo "An error occured while configuring un-configured packages."
    exit 1
fi

# Upgrade repositories
if ! sudo apt-get full-upgrade -y; then
    echo "An error occured while upgrading System Packages."
    exit 1
fi

# Install script's dependencies
if ! sudo apt install -y unzip curl git jq network-manager dialog; then
    echo "An error occured while installing Hashburst OS Dipendecies."
    exit 1
fi

### Downloading and giving permission to rainbowminer.sh
if ! wget -O rainbowminer.sh $rainbowminer_sh_link; then
    echo "An error occured while downloading RainbowMiner's Installer Script"
    exit 1
fi

if ! sudo chmod +x rainbowminer.sh; then
    echo "An error occured while trying make rainbowminer.sh executable"
    exit 1
fi


# Creating file to start RainbowMiner (RainbowMiner/start.sh)
if touch $filename1; then
    echo "#!/bin/bash" > "$filename1"
    echo "sudo /home/$LOGIN_NAME/RainbowMiner/./start.sh" >> "$filename1"
    echo "$filename1 created sucessfully."
else
    echo "An error occurred while creating $filename1"
    exit 1
fi

# Creating file to start JayDDee Miners with given parameters
if touch $filename2; then
    echo "#!/bin/bash" > "$filename2"
    echo "cd /home/$LOGIN_NAME/RainbowMiner/Bin/" >> "$filename2"
    echo "CPU-JayDDee/./cpuminer-sse2 -a x11 -o stratum+tcp://mining.viabtc.io:3004 -u Advisor21.${filename2} -p x &" >> "$filename2"
    echo "CPU-JayDDee/./cpuminer-sse2 -a yescrypt -o stratum+tcp://yescrypt.eu.mine.zpool.ca:6233 -u DPCAsyPg1bqLPmipJSGXP1adRS8ZSubXen -p c=DOGE,${filename1:0:4} &" >> "$filename2"
    echo "CPU-JayDDee/./cpuminer-sse2 -a scrypt -o stratum+tcp://ltc.viabtc.io:3333 -u Advisor21.${filename2} -p x" >> "$filename2"
    echo "$filename2 created sucessfully."
else
    echo "An error occured while creating $filename"
    exit 1
fi

# Creating script to delete periodically logs
if touch "delete_logs"; then
    cat > "delete_logs" << EOF
while true; do
    sleep \$((24 * 60 * 60))
    sudo echo "Deleting logs"
    > "$filename1.log"
    > "$filename2.log"
done
EOF
else
    echo "An error occured while creating delete_logs"
    exit 1
fi


# Giving execution permissions to the files
if ! chmod +x "$filename1" "$filename2"; then
    echo "An error occured while giving execution permissions to files: \"$filename1\" and \"$filename2\""
    exit 1
fi

# Create RainbowMiner Directory if not existent
if ! mkdir -p RainbowMiner; then
    echo "An error occured while creating /home/$LOGIN_NAME/RainbowMiner directory."
    exit 1
fi

# Execute rainbowminer.sh to download and extract RainbowMiner
if ! sudo bash rainbowminer.sh "$LOGIN_NAME"; then
    echo "An error occured while trying to execute rainbowminer.sh"
    exit 1
fi

if ! sudo rm -rf rainbowminer.sh; then
    echo "An error occured while deleting file rainbowminer.sh"
    sleep 5
fi

if ! sudo rm -rf /tmp/RainbowMiner_linux.zip; then
    echo "An error occured while deleting file /tmp/RainbowMiner_linux.zip"
    sleep 5
fi

# Try to create parallelStarter.sh (made to check any errors)
if ! touch parallelStarter.sh; then
    echo "An error occured while trying to create parallelStarter.sh"
    exit 1
fi
cat > parallelStarter.sh << EOF
#!/bin/bash

# Definizione delle variabili con i nomi degli script
script1="${filename1}"
script2="${filename2}"
lockfile="/tmp/miner.lock"

# Funzione per avviare uno script come demone e loggarne l'output
run_as_daemon() {
    local script="\$1"
    echo "Avvio dello script \${script} come demone..."
    chmod +x "\${script}"
    nohup stdbuf -oL -eL ./"\${script}" > "\${script}.log" 2>&1 < /dev/null &
    echo \$! > /tmp/\${script}.pid
}


# Pulizia: termina i processi esistenti e rimuove i file di log
cleanup() {
    pkill -f "CPU-JayDDee"
    pkill -f "RainbowMiner"
    pkill -f "\${script1}"
    pkill -f "\${script2}"
    pkill -f "delete_logs"

    sudo rm -rf "\${script1}.log" "\${script2}.log" "\${lockfile}"
    echo "Cleanup done for \${script1} and \${script2}."
}

# Funzione per gestire la concorrenza tra script1 e script2
manage_concurrency() {
    if [ -e "\${lockfile}" ]; then
        echo "Lockfile esistente: script2 sta usando i miner. Arresto di \${script1}."

        sudo pkill -f "\${script1}"
        sudo pkill -f "RainbowMiner"

        while [ -e "\${lockfile}" ]; do
            sleep 1
        done

        echo "Lockfile removed: restarting \${script1}."
        run_as_daemon "\${script1}"
    else
        echo "No conflicts detected, continuing execution."
    fi
}

# Funzione per eseguire script2 con lock
run_script2_with_lock() {
    echo "Avvio di \${script2} con lock: \${lockfile}"
    touch "\${lockfile}"

    run_as_daemon "\${script2}"

    # Attendi finché il processo è attivo
    while kill -0 "/tmp/\${script2}.pid" > /dev/null 2>&1; do
        sleep 1
    done

    echo "\${script2} completed. Removing lockfile."
    rm -f "\${lockfile}" "/tmp/\${script2}.pid"
}

# Funzione per gestire le opzioni dell'utente dopo la scelta di 'Q'
handle_user_input() {
    echo -e "\n1) Cleanup and restart deamons"
    echo "2) Exit"
    echo "3) Shutdown System"
    echo "4) Reboot System"
    read -p "Select an option: " choice
    case \${choice} in
        1)
            echo "Cleanup and restarting deamons..."
            cleanup
            run_as_daemon "\${script1}"
            run_script2_with_lock
            nohup ./delete_logs > /dev/null 2>&1 &
            ;;
        2)
            echo "Exiting..."
            # Cleanup non necessario perché con "trap cleanup" viene eseguito in automatico
            exit 0
            ;;
        3)
            echo "System shutdown..."
            sudo shutdown now
            ;;
        4)
            echo "System reboot..."
            sudo reboot
            ;;
        *)
            echo "Not valid Option..."
            ;;
    esac
}


# Aggiungo come parametro il mining su CPU a start.sh
sed -i 's|\./Config/config.txt;|./Config/config.txt -device CPU;|'  /home/$LOGIN_NAME/RainbowMiner/start.sh

# Mi assicuro di dare i permessi ai Miner
sudo chmod 777 -R /home/$LOGIN_NAME/RainbowMiner/Bin

# In caso di interruzioni da tastiera eseguo cleanup
trap 'cleanup; exit 0' SIGINT SIGTERM EXIT

#cleanup iniziale nel caso fossero rimasti residui di esecuzioni precedenti
cleanup

# Esegui gli script come demoni in background
run_as_daemon "\${script1}"
run_script2_with_lock
nohup ./delete_logs > /dev/null 2>&1 &



# Gestione manuale dell'interruzione da parte dell'utente
while true; do
    clear
    echo "Output di \${script2}:"
    echo "==================="
    tail -n 50 "\${script2}.log" | awk '{print \$0 "\n"}'
    echo "==================="
    echo "Output di \${script1}:"
    last_line=\$(tail -n 1 "\${script1}.log" | tr -d '\0')
    if [[ "\$last_line" == *"WARNING: Console"* ]]; then
        echo -e "\nRainbowMiner is mining!"
    else
        echo -e "\n\$last_line"
    fi
    echo "==================="

    manage_concurrency

    # Leggi l'input dell'utente con richiesta esplicita di premere Enter
    read -n1 -t 3 -p "Press 'Q' to show menu options: " input

    # Controlla l'input
    if [[ "\${input}" = "Q" || "\${input}" = "q" ]]; then
        handle_user_input
    fi

    # Se necessario, aggiungi un breve sleep per evitare cicli continui non desiderati
    sleep 1
done
EOF


# Giving execution permissions to parallelStarter.sh
if ! chmod +x parallelStarter.sh; then
    echo "An error occured while giving execution Permissions to parallelStarter.sh"
    exit 1
fi

### RainbowMiner Installation
# Change directory to RainbowMiner's directory
cd /home/$LOGIN_NAME/RainbowMiner/

# Executing RainbowMiner installer
if ! sudo bash ./install.sh -pu; then
    echo "An error occured while executing \"install.sh\""
    exit 1
fi

# Downloading setup.json (which contains some info about miners configuration)
if ! wget $setup -O setup.json; then
    echo "setup.json not found. Executing setup.sh"
    sleep 5
fi

# Modify start.sh to force CPU mining
if ! sudo sed -i 's|\./Config/config.txt;|./Config/config.txt -device CPU;|' ./start.sh; then
    echo "An error occured while trying to modify $(pwd)/start.sh"
    echo "Continuing script..."
    sleep 5
fi


# Modify setup.sh to run it with preconfigured options
if ! sudo sed -i 's|\./Config/config.txt -setuponly;|./Config/config.txt -setuponly -device CPU -BTC 3DLDaBbMhVN7TvpVaJZBBWbU3VzD3qPQuF -MinerStatusKey 7eaae1e7-7a72-43b5-9008-c1577d8c4e9c;|' ./setup.sh; then
    echo "An error occured while trying to moidfy $(pwd)/setup.sh"
    echo "Continuing script..."
    sleep 5
fi

sudo bash ./setup.sh

sudo bash ./start.sh &
# Save start.sh's PID
START_PID=$!


BIN_DIR="/home/$LOGIN_NAME/RainbowMiner/Bin"
TARGET_FILE="$BIN_DIR/CPU-JayDDee/cpuminer-sse2"

# FOLDER_COUNT control deleted because instable (different on each machine)
# FOLDER_COUNT=47  # Imposta il numero di cartelle da aspettare

# Loop until TARGET_FILE is present and $min_time timed out
time_elapsed=0
interval=10
min_time=100
while [ ! -e "$TARGET_FILE" ] || [ "$time_elapsed" -lt "$min_time" ]; do
    sleep "$interval"
    time_elapsed=$((time_elapsed + interval))
    echo "Waiting for main miner to appear... Time elapsed: ${time_elapsed}s"
    echo "Searching for $TARGET_FILE"
done

# When both conditions are true, terminate start process
if ps -p $START_PID > /dev/null; then
    echo "Terminating start.sh process..."
    sudo kill $START_PID
fi

# Give 777 permissions to bin (Miners) folder
if ! sudo chmod 777 -R /home/$LOGIN_NAME/RainbowMiner/Bin; then
    echo "An error occured while giving 777 permissions to /home/$LOGIN_NAME/RainbowMiner/Bin"
    exit 1
fi
sleep 0.5

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
    wget https://github.com/rustdesk/rustdesk/releases/download/1.3.2/rustdesk-1.3.2-x86_64.deb -O /tmp/rustdesk-1.3.2-x86_64.deb
    sudo apt install -y /tmp/rustdesk-1.3.2-x86_64.deb
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

# Be sure to be in right directory for user typed command
cd /home/$LOGIN_NAME/

# Selfremove script
sudo rm -- $0



clear

echo “Installation successfully completed!”
echo "Welcome! To start mcm300 Hashburst Mining System type: \"sudo bash parallelStarter.sh\""
