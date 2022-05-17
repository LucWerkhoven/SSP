#!/bin/bash
# Alle functies voor het lezen van input

#Deze functies lezen de meegegeven parameter en stop het in een variabele.
f_read() {
  # Interactieve prompt, -p optie met de string tekst
  read -p "$1" VALUE
  # Als de string leeg is:
  if [ -z $VALUE ]
  then
    # Dan geef de prompt opnieuw op.
    VALUE=$(f_read "$1")
  fi
  # Om de waarde op te vragen, indien de waarde niet leeg is.
  echo $VALUE
}

#Functie die de soort omgeving leest.
f_read_env() {
  # Interactieve prompt, gebruikt de read functie.
  VALUE=$(f_read "$1")
  # Als de waarde niet test of productie is:
  if [ $VALUE != "test" ] && [ $VALUE != "productie" ]
  then
    # Geeft de prompt opnieuw.
    VALUE=$(f_read_env "$1")
  fi
  # Indien de waarde wel test of productie is, echo deze om op te vragen.
  echo $VALUE
}

#Functie voor het lezen van een boolean waarde, true of false.
f_read_bool() {
  # Interactieve prompt, gebruikt de read functie.
  VALUE=$(f_read "$1")
  # Als de waarde niet true of false is:
  if [ $VALUE != "true" ] && [ $VALUE != "false" ]
  then
    #Geeft de prompt opnieuw.
    VALUE=$(f_read_bool "$1")
  fi
  # Indien de waarde wel true of false is, echo deze om op te vragen.
  echo $VALUE
}

#Functie voor het lezen van een getal waarde.
f_read_num() {
  # Interactieve prompt, gebruikt de read functie.
  VALUE=$(f_read "$1")
  # Als de waarde niet voldoet aan de gegeven regex ^[0-9]+$ tester:
  if ! [[ $VALUE =~ ^[0-9]+$ ]]
  then
    #Geeft de prompt opnieuw.
    VALUE=$(f_read_num "$1")
  fi
  # Indien de waarde wel een getal is, echo deze om op te vragen.
  echo $VALUE
}

#Functie voor het lezen van RAM geheugen.
f_read_mem() {
  # Interactieve prompt, gebruikt de read functie.
  VALUE=$(f_read "$1")
  # Als de waarde niet voldoet aan het deelbaar zijn door 128 dan:
  if ! [[ `expr $VALUE % 128` == 0 ]]
  then
    # Geef de prompt opniew op.
    VALUE=$(f_read_mem "$1")
  fi
  # Indien wel correcte waarde, echo deze om op te vragen.
  echo $VALUE
}
################







# Main functie om de input te lezen van de gebruiker, met de daarbijhorende vragen.
f_read_vars() {
  CUSTOMER=$(f_read "Wat is je naam: ")
  ENVIRONMENT=$(f_read_env "Omgevingstype, test of productie: ")

  # WEBSERVERS
  WEBSERVERS=$(f_read_bool "Wil je webservers? [true/false]: ")
  if [ $WEBSERVERS == "true" ]
  then
    WEBSERVERS_AMOUNT=$(f_read_num "Hoeveel webservers wil je: ")
    WEBSERVERS_MEMORY=$(f_read_mem "Hoeveel RAM per webserver [ophogingen van 128MB]: ")
  else
    WEBSERVERS_AMOUNT=0
    WEBSERVERS_MEMORY=0
  fi

  # LOADBALANCERS
  if [ "$ENVIRONMENT" == "productie" ]
  then
    LOADBALANCERS=$(f_read_bool "Wil je loadbalancers? [true/false]: ")
    if [ $LOADBALANCERS == "true" ]
    then
      LOADBALANCERS_AMOUNT=$(f_read_num "Hoeveel loadbalancers wil je: ")
      LOADBALANCERS_MEMORY=$(f_read_mem "HHoeveel RAM per loadbalancer [ophogingen van 128MB]: ")
      LOADBALANCERS_PORT=$(f_read_num "Op welke poort moet de loadbalancer draaien: ")
    else
      LOADBALANCERS_AMOUNT=0
      LOADBALANCERS_MEMORY=0
      LOADBALANCERS_PORT=80
    fi
  else
    LOADBALANCERS="false"
    LOADBALANCERS_AMOUNT=0
    LOADBALANCERS_MEMORY=0
    LOADBALANCERS_PORT=80
  fi

  # DATABASESERVERS
  DATABASESERVERS=$(f_read_bool "Wil je databaseservers [true/false]: ")
  if [ $DATABASESERVERS == "true" ]
  then
    DATABASESERVERS_AMOUNT=$(f_read_num "Hoeveel databaseservers wil je: ")
    DATABASESERVERS_MEMORY=$(f_read_mem "Hoeveel RAM per databaseserver [ophogingen van 128MB]: ")
  else
    DATABASESERVERS_AMOUNT=0
    DATABASESERVERS_MEMORY=0
  fi

  SUBNET=$(f_read "Welk subnet wil je gebruiken [x.x.x.]: ")
  #Definieerd in de DEST var de omgevingsmap. Dit is hoe de klantenmappenstructuur wordt opgebouwd.
  DEST="/mt/sdb1/home/ansible/s1154427_IAC2022/customers/$CUSTOMER/$ENVIRONMENT"
}
#########



#Functie om te zoeken naar waarden die in de envvars bestand staan.
f_search_old() {
  #Leest elke lijn in de envvars bestand
  while read -r line; do
    #voorgeprogrammeerde pattern variabelen
    pattern1='CUSTOMER=(.*)'
    pattern2='ENVIRONMENT=(.*)'
    pattern3='SUBNET=(.*)'
    pattern4='WEBSERVERS=(.*)'
    pattern5='WEBSERVERS_AMOUNT=(.*)'
    pattern6='WEBSERVERS_MEMORY=(.*)'
    pattern7='LOADBALANCERS=(.*)'
    pattern8='LOADBALANCERS_AMOUNT=(.*)'
    pattern9='LOADBALANCERS_MEMORY=(.*)'
    pattern10='LOADBALANCERS_PORT=(.*)'
    pattern11='DATABASESERVERS=(.*)'
    pattern12='DATABASESERVERS_AMOUNT=(.*)'
    pattern13='DATABASESERVERS_MEMORY=(.*)'
    #Per pattern zoekt hij de waarde die na de = teken komt. Deze slaat hij op in een variabele
    if [[ $line =~ $pattern1 ]]; then
       CUSTOMER="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern2 ]]; then
       ENVIRONMENT="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern3 ]]; then
       SUBNET="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern4 ]]; then
       WEBSERVERS="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern5 ]]; then
       WEBSERVERS_AMOUNT="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern6 ]]; then
       WEBSERVERS_MEMORY="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern7 ]]; then
       LOADBALANCERS="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern8 ]]; then
       LOADBALANCERS_AMOUNT="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern9 ]]; then
       LOADBALANCERS_MEMORY="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern10 ]]; then
       LOADBALANCERS_PORT="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern11 ]]; then
       DATABASESERVERS="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern12 ]]; then
       DATABASESERVERS_AMOUNT="${BASH_REMATCH[1]}"
    fi
    if [[ $line =~ $pattern13 ]]; then
       DATABASESERVERS_MEMORY="${BASH_REMATCH[1]}"
    fi
  done < "$DEST/envvars.txt"

  WEBSERVERS_AMOUNT_OLD=$WEBSERVERS_AMOUNT
  LOADBALANCERS_AMOUNT_OLD=$LOADBALANCERS_AMOUNT
  DATABASESERVERS_AMOUNT_OLD=$DATABASESERVERS_AMOUNT
}

# Deze functie genereert de public/private key combo voor de ssh connectie en ansible connectie.
f_gen_key() {
  cd $DEST
  #genereert de key pair met de meegegeven klantenomgevingsnaam
  ssh-keygen -q -f $CUSTOMER-$ENVIRONMENT-id_rsa -N ""
}

f_fill_vagrant() {
  #Vervangt de nog onbekende tekst in vagrantfile met de waarde vanuit de prompt. Zodat hij de goede key pair pakt voor SSH.
  sed -i "s/{{ customer }}/$CUSTOMER/g" "$DEST/Vagrantfile"
  sed -i "s/{{ environment }}/$ENVIRONMENT/g" "$DEST/Vagrantfile"
  # Ook voor de ansible connectie, vervangt de onbekende tekst in de ansible.cfg met de goede omgevingsnaam.
  sed -i -e "s;%customer%;$CUSTOMER;g" -e "s;%environment%;$ENVIRONMENT;g" "$DEST/ansible.cfg"
  #Aanvullen van de subnet en hostname
  sed -i "s/{{ hostname_base }}/$CUSTOMER-$ENVIRONMENT-/g" "$DEST/Vagrantfile"
  sed -i "s/{{ subnet }}/$SUBNET/g" "$DEST/Vagrantfile"
}


#Functie om de templates te kopieeren en de omgevings variabelen naar de klantenomgeving.
f_copy_files() {
  #Creatie van de klantenomgevingsfolders
  mkdir --parents $DEST
  #Kopieert templates
  cp /mt/sdb1/home/ansible/s1154427_IAC2022/templates/Vagrantfile $DEST/Vagrantfile
  cp //mt/sdb1/home/ansible/s1154427_IAC2022/templates/ansible.cfg $DEST/ansible.cfg
  #Vullen van ansible inventory
  f_build_inventory
  #Deze kopieeren de gegeven informatie naar de envvars bestand.
  echo "CUSTOMER=$CUSTOMER" >> $DEST/envvars.txt
  echo "ENVIRONMENT=$ENVIRONMENT" >> $DEST/envvars.txt
  echo "SUBNET=$SUBNET" >> $DEST/envvars.txt
  echo "WEBSERVERS=$WEBSERVERS" >> $DEST/envvars.txt
  echo "WEBSERVERS_AMOUNT=$WEBSERVERS_AMOUNT" >> $DEST/envvars.txt
  echo "WEBSERVERS_MEMORY=$WEBSERVERS_MEMORY" >> $DEST/envvars.txt
  echo "LOADBALANCERS=$LOADBALANCERS" >> $DEST/envvars.txt
  echo "LOADBALANCERS_AMOUNT=$LOADBALANCERS_AMOUNT" >> $DEST/envvars.txt
  echo "LOADBALANCERS_MEMORY=$LOADBALANCERS_MEMORY" >> $DEST/envvars.txt
  echo "LOADBALANCERS_PORT=$LOADBALANCERS_PORT" >> $DEST/envvars.txt
  echo "DATABASESERVERS=$DATABASESERVERS" >> $DEST/envvars.txt
  echo "DATABASESERVERS_AMOUNT=$DATABASESERVERS_AMOUNT" >> $DEST/envvars.txt
  echo "DATABASESERVERS_MEMORY=$DATABASESERVERS_MEMORY" >> $DEST/envvars.txt
}

# VM informatie wordt in de vagrantfile gestopt
f_vagrant_servers() {
  sed -i "s/{{ webservers }}/$WEBSERVERS/g" "$DEST/Vagrantfile"
  sed -i "s/{{ webserver_amount }}/$WEBSERVERS_AMOUNT/g" "$DEST/Vagrantfile"
  sed -i "s/{{ webserver_memory }}/$WEBSERVERS_MEMORY/g" "$DEST/Vagrantfile"

  sed -i "s/{{ loadbalancers }}/$LOADBALANCERS/g" "$DEST/Vagrantfile"
  sed -i "s/{{ loadbalancer_amount }}/$LOADBALANCERS_AMOUNT/g" "$DEST/Vagrantfile"
  sed -i "s/{{ loadbalancer_memory }}/$LOADBALANCERS_MEMORY/g" "$DEST/Vagrantfile"

  sed -i "s/{{ databaseservers }}/$DATABASESERVERS/g" "$DEST/Vagrantfile"
  sed -i "s/{{ databaseserver_amount }}/$DATABASESERVERS_AMOUNT/g" "$DEST/Vagrantfile"
  sed -i "s/{{ databaseserver_memory }}/$DATABASESERVERS_MEMORY/g" "$DEST/Vagrantfile"
}

# Creeert de inventory bestand en vult deze
f_build_inventory() {
  if [ -f "$DEST/inventory.ini" ]
  then
    echo "Inventory bestaat al, bezig met verwijderen van oude bestand."
    rm $DEST/inventory.ini
  fi
  # Creert het bestand
  touch $DEST/inventory.ini
  # Zodra webservers nodig zijn, vult in inventory bestand
  if [ $WEBSERVERS == "true" ]
  then
    echo "[webservers]" >> $DEST/inventory.ini
    COUNTER=0
    while [ $COUNTER -lt $WEBSERVERS_AMOUNT ]
    do
      # Webservers subnet begint vanaf 20
      echo "$SUBNET`expr $COUNTER + 20`" >> $DEST/inventory.ini
      COUNTER=`expr $COUNTER + 1`
    done
    echo "" >> $DEST/inventory.ini
  fi
  # Zodra loadbalancers nodig zijn, vult in inventory bestand
  if [ $LOADBALANCERS == "true" ]
  then
    echo "[loadbalancers]" >> $DEST/inventory.ini
    COUNTER=0
    while [ $COUNTER -lt $LOADBALANCERS_AMOUNT ]
    do
      # loadbalancers subnet begint van 2
      echo "$SUBNET`expr $COUNTER + 2`" >> $DEST/inventory.ini
      COUNTER=`expr $COUNTER + 1`
    done
    echo "" >> $DEST/inventory.ini
    echo "[loadbalancers:vars]" >> $DEST/inventory.ini
    echo "bind_port=$LOADBALANCERS_PORT" >> $DEST/inventory.ini
    echo "" >> $DEST/inventory.ini
  fi
  # Zodra databaseservers nodig zijn, vult in inventory bestand
  if [ $DATABASESERVERS == "true" ]
  then
    echo "[databaseservers]" >> $DEST/inventory.ini
    COUNTER=0
    while [ $COUNTER -lt $DATABASESERVERS_AMOUNT ]
    do
      # DATABASESERVERS subnet begint vanaf 10
      echo "$SUBNET`expr $COUNTER + 10`" >> $DEST/inventory.ini
      COUNTER=`expr $COUNTER + 1`
    done
    echo "" >> $DEST/inventory.ini
  fi
}
################
