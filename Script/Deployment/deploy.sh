#!/bin/bash
source Deploy_Functions.sh

# Drie functies, destroy, edit en create

# Deze functie vernietigt de omgeving veilig, met de vagrant destroy commando.
f_destroy() {
  (cd "/mt/sdb1/home/ansible/s1154427_IAC2022/customers/$1/$2" && vagrant destroy)
  #Verwijderd zowel de omgeving als klant om het op te schonen.
  rm -r "/mt/sdb1/home/ansible/s1154427_IAC2022/customers/$1/$2"
  rm -r "/mt/sdb1/home/ansible/s1154427_IAC2022/customers/$1"
}

# Functie om de omgeving aan te passen
f_edit() {
  # Gooit de opgevraagde klantenomgeving om in een VAR
  DEST="/mt/sdb1/home/ansible/s1154427_IAC2022/customers/$1/$2"
  # Terughalen van omgevingsinformatie, dit staat in de envvars tekst bestand
  f_search_old
  # Kijken of klant de webservers wil aanpassen, gebruik van de boolean read functie
  WEBSERVERS=$(f_read_bool "Wil je de webservers aanpassen? [true/false]: ")
  if [ $WEBSERVERS == "true" ]
  then
    #Vragen om webserver gegevens
    WEBSERVERS_AMOUNT=$(f_read_num "Hoeveel webservers wil je? [Je hebt er nu $WEBSERVERS_AMOUNT]: ")
    WEBSERVERS_MEMORY=$(f_read_mem "Hoeveel RAM wil je [ophogingen van 128, je zit op dit moment op $WEBSERVERS_MEMORY]: ")
  fi

  # Eerst kijken of omgeving productie is, want test omgeving is alleen webservers.
  if [ "$ENVIRONMENT" == "productie" ]
  then
    # vragen of loadbalancers aangepast moet worden
    LOADBALANCERS=$(f_read_bool "Wil je de loadbalancers aanpassen? [true/false]: ")
    if [ $LOADBALANCERS == "true" ]
    then
      #Vragen om loadbalancer gegevens
      LOADBALANCERS_AMOUNT=$(f_read_num "Hoeveel loadbalancers wil je? [Je hebt er nu $LOADBALANCERS_AMOUNT]: ")
      LOADBALANCERS_MEMORY=$(f_read_mem "Hoeveel RAM wil je [ophogingen van 128, je zit op dit moment op $LOADBALANCERS_MEMORY]: ")
      LOADBALANCERS_PORT=$(f_read_num "Op welke poort moet de loadbalancer draaien [Op dit moment luisters hij op $LOADBALANCERS_PORT]: ")
    fi
  fi
  # Kijken of klant databaseservers wil aanpassen
  DATABASESERVERS=$(f_read_bool "Wil je de databaseservers aanpassen? [true/false]: ")
  if [ $DATABASESERVERS == "true" ]
  then
    # Vragen om databaseserver informatie
    DATABASESERVERS_AMOUNT=$(f_read_num "Hoeveel databaseservers wil je? [Je hebt er nu $DATABASESERVERS_AMOUNT]: ")
    DATABASESERVERS_MEMORY=$(f_read_mem "Hoeveel RAM wil je [ophogingen van 128, je zit op dit moment op $DATABASESERVERS_MEMORY]: ")
  fi
#Loops, hij itereert door de oude hoeveelheid, verwijdert deze. Mocht de hoeveelheid oude hoger zijn dan nieuwe dan loopt hij niet.
  while [ $WEBSERVERS_AMOUNT -lt $WEBSERVERS_AMOUNT_OLD ]
  do
    #Destroy de webserver van oude hoeveelheid tot aan 0
    (cd $DEST && vagrant destroy "$1-$2-web$WEBSERVERS_AMOUNT_OLD" -f)
    #Bij elke iteratie haal 1 van de totale oude webservers
    WEBSERVERS_AMOUNT_OLD=`expr $WEBSERVERS_AMOUNT_OLD - 1`
  done

  while [ $LOADBALANCERS_AMOUNT -lt $LOADBALANCERS_AMOUNT_OLD ]
  do
    #Destroy de loadbalancer van oude hoeveelheid tot aan 0
    (cd $DEST && vagrant destroy "$1-$2-lb$LOADBALANCERS_AMOUNT_OLD" -f)
    #Bij elke iteratie haal 1 van de totale oude loadbalancer
    LOADBALANCERS_AMOUNT_OLD=`expr $LOADBALANCERS_AMOUNT_OLD - 1`
  done

  while [ $DATABASESERVERS_AMOUNT -lt $DATABASESERVERS_AMOUNT_OLD ]
  do
    #Destroy de databaseservers van oude hoeveelheid tot aan 0
    (cd $DEST && vagrant destroy "$1-$2-db$DATABASESERVERS_AMOUNT_OLD" -f)
    #Bij elke iteratie haal 1 van de totale oude databaseserver
    DATABASESERVERS_AMOUNT_OLD=`expr $DATABASESERVERS_AMOUNT_OLD - 1`
  done
  # Verwijdert de oude bestanden om deze opnieuw te vullen
  rm "$DEST/Vagrantfile"
  rm "$DEST/envvars.txt"
  rm "$DEST/inventory.ini"
  rm "$DEST/ansible.cfg"
  #Zet de nieuwe omgeving op met de nieuwe informatie.
  f_create_edit
}

#Create functie specifiek voor de edit functie.
f_create_edit() {
  #Kopieert de template bestanden
  f_copy_files
  # Vult de vragrant file
  f_fill_vagrant
  #Vullen van vagrant bestanden met server info
  f_vagrant_servers
  #Herstarten servers en up brengen
  (cd $DEST && vagrant reload)
  (cd $DEST && vagrant up)
  sleep 1m
  #Playbook afspelen voor de rollen
  (cd $DEST && ansible-playbook /mt/sdb1/home/ansible/s1154427_IAC2022/playbooks/site.yml)
  exit 0
}

# De creeer functie, hiermee komt een nieuwe omgeving tot stand.
f_create() {
  # Lees de meegegeven waardes.
  f_read_vars
  # Kopieer de bestanden vanuit de template en voeg de servers toe aan de inventory bestand
  f_copy_files
  # Vult de vragrant file
  f_fill_vagrant
  # Vullen van de vagrant file met de machine specificaties
  f_vagrant_servers
  # Geneert de keys voor SSH en ansible connectie
  f_gen_key
  f_fill_vagrant
  # Brengt de vm's tot leven
  (cd $DEST && vagrant up)
  #Voert de playbook uit, de site.yml.
  (cd $DEST && ansible-playbook /mt/sdb1/home/ansible/s1154427_IAC2022/playbooks/site.yml)
  exit 0
}
##############

# Deze functie toont de help display, die krijg je wanneer je de ./deploy.sh zonder parameters uitvoerd.
f_display_help()
{
  echo "####################################################################################################"
  echo "#### [Welkom bij deze mooie grafische portaal, dit dient ter creatie van een vagrant omgeving!] ####"
  echo "####################################################################################################"
  echo "Manier van gebruiken: $0 [-h/-N/-E/-D]"
  echo -e "\t-h Laat een menu zien met hulpcommando's"
  echo -e "\t-N Creeer een nieuwe omgeving"
  echo -e "\t-E Edit een omgeving"
  echo -e "\t\t-c Naam van van de klant om te editen"
  echo -e "\t\t-e Naam van de omgeving om te editen"
  echo -e "\t-D Vernietig een omgeving"
  echo -e "\t\t-c Naam van van de klant om te vernietigen"
  echo -e "\t\t-e Naam van de omgeving om te vernietigen"
  exit 1 # Verlaat de script zodra alle tekst geprint is.
}
#########

#Dit is de getopts functie die kijkt naar de parameters.
while getopts "NDEhc:e:" opt
do
  case "$opt" in
    N )
      NEW="true"
      ;;
    D )
      DESTROY="true"
      ;;
    E )
      EDIT="true"
      ;;
    c)
     # Parameter c voor customer, oftewel klant. Is niet verplicht bij NEW, vandaar Optional.
      PARAMETER_C="$OPTARG"
      ;;
    e )
     # Parameter e voor environment, oftewel omgeving. Is niet verplicht bij NEW, vandaar Optional.
      PARAMETER_E="$OPTARG"
      ;;
    h )
      # Toont weer de help display
      f_display_help
      ;;
    ? )
      f_display_help # Toont de help display wanneer de niet geschikte parameter gegeven wordt.
      ;;
  esac
done

#Kijkt of de parameters correct zijn afgegeven.
if [[ "$DESTROY" == "true" && "$EDIT" == "true" ]] || [[ "$NEW" == "true" && "$EDIT" == "true" ]] || [[ "$NEW" == "true" && "$DESTROY" == "true" ]]
then
  echo "Conflicterende paramaters zijn gegeven";
  f_display_help
fi

# Als de -d parameter gegeven is, moet -c en -e ook aanwezig zijn.
if [ "$DESTROY" == "true" ] || [ "$EDIT" == "true" ]
then
  # Als beide paramaters leeg zijn, toon help display.
  if [ -z "$PARAMETER_C" ] || [ -z "$PARAMETER_E" ]
  then
    echo "Sommige of alle parameters zijn leeg";
    f_display_help
  fi
# Als de -D flag niet gegeven is, maar wel -c en -e, toon help display.
elif [ -z "$DESTROY" ] && [ -z "$EDIT" ]
then
  if [ ! -z "$PARAMETER_C" ] || [ ! -z "$PARAMETER_E" ]
  then
    echo "-c or -e requires the -d flag to be passed as well"
    f_display_help
  fi
fi

#Aanroeping van de destroy functie
if [ "$DESTROY" == "true" ]
then
  f_destroy $PARAMETER_C $PARAMETER_E
  exit 0
# Aanroeping van de edit functie
elif [ "$EDIT" == "true" ]
then
  f_edit $PARAMETER_C $PARAMETER_E

#Aanroeping van de main functie, oftwel creatie van nieuwe omgeving.
elif [ "$NEW" == "true" ]
then
  f_create
else
  f_display_help
fi
