#!/bin/dash

# Yusuf KORKMAZ

# Pour plus d'aide, entrer ce qui suit dans le terminal Linux
# ./version.sh --help

########################################################################################################
# FONCTIONS DE GESTION D'AIDE ET D'ERREURS
########################################################################################################

# help_ : Affiche l'aide complète
# Paramètre : Aucun
# Sortie : affiche un message sur la sortie standard termine le script avec exit 0
help_(){
    echo "Usage:"
    echo "    ${0} --help"
    echo "    ${0} <command> FILE [OPTION]"
    echo "    where <command> can be: add amend checkout|co commit|ci diff log reset rm"
    echo 
    echo "${0} add FILE MESSAGE"
    echo "    Add FILE under versioning with the initial log message MESSAGE"
    echo 
    echo "${0} commit|ci FILE MESSAGE"
    echo "    Commit a new version of FILE with the log message MESSAGE"
    echo 
    echo "${0} amend FILE MESSAGE"
    echo "    Modify the last registered version of FILE, or (inclusive) its log message"
    echo 
    echo "${0} checkout|co FILE [NUMBER]"
    echo "    Restore FILE in the version NUMBER indicated, or in the"
    echo "    latest version if there is no number passed in argument"
    echo 
    echo "${0} diff FILE"
    echo "    Displays the difference between FILE and the last committed version"
    echo 
    echo "${0} log FILE"
    echo "    Displays the logs of the versions already committed"
    echo 
    echo "${0} reset FILE NUMBER"
    echo "    Restores FILE in the version NUMBER indicated and"
    echo "    deletes the versions of number strictly superior to NUMBER"
    echo 
    echo "${0} rm FILE"
    echo "    Deletes all versions of a file under versioning"
    exit 0
}

# enterHelp : Affiche une erreur et invite l'utilisateur à consulter l'aide
# Paramètre : Aucun
# Sortie : affiche message d'erreur sur l'erreur standard et termine le script avec exit 1
enterHelp(){
    echo "Enter \"${0} --help\" for more information" >&2
    exit 1
}

# Les fonctions suivantes affichent un message d'erreur et l'usage spécifique de la commande

usageHelp(){
    echo "Usage:" >&2
    echo "    ${0} --help" >&2
    echo "    ${0} <command> FILE [OPTION]" >&2
    echo "    where <command> can be: add amend checkout|co commit|ci diff log reset rm" >&2
    exit 1
}

usageAdd(){
    echo "${0} add FILE MESSAGE" >&2
    echo "    Add FILE under versioning with the initial log message MESSAGE" >&2
    exit 1
} 

usageCi(){
    echo "${0} commit|ci FILE MESSAGE" >&2
    echo "    Commit a new version of FILE with the log message MESSAGE" >&2
    exit 1
}

usageAmend(){
    echo "${0} amend FILE MESSAGE" >&2
    echo "    Modify the last registered version of FILE, or (inclusive) its log message" >&2
    exit 1
}

usageCo(){
    echo "${0} checkout|co FILE [NUMBER]" >&2
    echo "    Restore FILE in the version NUMBER indicated, or in the" >&2
    echo "    latest version if there is no number passed in argument" >&2
    exit 1
}

usageDiff(){
    echo "${0} diff FILE" >&2
    echo "    Displays the difference between FILE and the last committed version" >&2
    exit 1
}

usageLog(){
    echo "${0} log FILE" >&2
    echo "    Displays the logs of the versions already committed" >&2
    exit 1
}

usageReset(){
    echo "${0} reset FILE NUMBER" >&2
    echo "    Restores FILE in the version NUMBER indicated and" >&2
    echo "    deletes the versions of number strictly superior to NUMBER" >&2
    exit 1
}

usageRm(){
    echo "${0} rm FILE" >&2
    echo "    Deletes all versions of a file under versioning" >&2
    exit 1
}

########################################################################################################
# FONCTIONS DE VERIFICATIONS
########################################################################################################

# testComment : Vérifie qu'un message n'est ni vide ni constitué uniquement d'espaces
# Paramètre : $1 = MESSAGE trimé (sans espace au début et à la fin"
# Sortie : Message d'erreur et appelle la fonction enterHelp si invalide
testComment(){
    if [ ! -n "$1" ]; then
	echo "Error! The message cannot be empty and must not contain only spaces." >&2
        enterHelp
    fi
}

# testFile : Vérifie qu'un fichier existe, est ordinaire, est lisible
# Paramètre : $1 = FILE
# Sortie : Message d'erreur et appelle la fonction enterHelp si invalide
testFile(){
    if [ ! -f "$1" ] || [ ! -r "$1" ]; then
	echo "Error! \"${1}\" is not a regular file or read permission is not granted" >&2
	enterHelp
    fi
}

# testFileWrite : Vérifie qu'un fichier a la permission d'écriture
# Paramètre : $1 = FILE
# Sortie : Message d'erreur et appelle la fonction enterHelp si invalide
testFileWrite(){
    if [ ! -w "$1" ]; then
	echo "Error! write permission is not granted to \"$1\"" >&2
	enterHelp
    fi
}

# testVersioning : Vérifie qu'un fichier est sous versioning (doit être utilisé après les definitions de rep et nom) 
# Paramètre : $1 = FILE
# Sortie : Message d'erreur et appelle la fonction enterHelp si invalide
testVersioning(){
    if [ ! -d "${rep}/.version" ] || [ ! -f "${rep}/.version/${nom}.1" ]; then
	echo "\"${1}\" is not under versioning" >&2
	enterHelp
    fi
}

# testInteger : Vérifie qu'un nombre est un entier positif >= 0 (doit être utilisé après les definitions de rep et nom) 
# Paramètre : $1 = NUMBER
# Sortie : Message d'erreur et appelle la fonction enterHelp si invalide
testInteger(){
    test 0 -eq "$1" 2>/dev/null
    res=$?
    if test "$res" -eq 2; then
	echo "Error! NUMBER isn't an integer" >&2
	enterHelp
    fi
    if test "$res" -eq 1 && test "$1" -le 0; then
	echo "Error! NUMBER must be over 1 or equal" >&2
	enterHelp
    fi
}

########################################################################################################
# FONCTIONS PRINCIPALES DES COMMANDES
########################################################################################################

# tout les fonctions suivantes doivent être utilisé après les definitions de rep et nom avec direname et basename

# log_ : Affiche l'historique des messages de log avec numérotation
# Paramètre : $1 = FILE sous versioning
# Sortie : Formate et affiche le .log avec nl -s' : '
log_(){
    # nl : ecit FILE dans sa sortie standard avec le numéro de ligne devant chaque ligne
    # option -s permet de rajouter une chaine de caractère après le numero de ligne
    nl -s' : ' "${rep}/.version/${nom}.log"
    exit 0
}

# add_ : Place le fichier sous gestion de versions et envoie une erreur s'il l'est déjà
# Paramètres : $1 = FILE à versionner, $2 = MESSAGE de log initial
# Sortie :
#  - Crée le répertoire caché .version dans le meme répertoire que FILE s'il n'existe pas déjà
#  - Crée les .log, .1 et .latest correspondant
#  - Envoie une erreur si FILE est déjà sous versionnement
add_(){
    # test si FILE est déjà sous versionnement
    if [ -d "$rep/.version" ] && [ -f "${rep}/.version/${nom}.1" ]; then
	echo "\"${1}\" already under versioning" >&2
	exit 1
    fi
    # trim le message
    msg=$(echo "$2" | sed -E 's/[ ]*$//;s/^[ ]*//')
    testComment "$msg"
    # crée le rep caché .version et les .1 et .latest correspondant
    mkdir -p "${rep}/.version"
    cp "$1" "${rep}/.version/${nom}.1"
    cp "$1" "${rep}/.version/${nom}.latest"
    echo "Added a new file under versioning:" \"$1\"
    # crée le .log
    echo $(date -R) \"$msg\" > "${rep}/.version/${nom}.log"
    exit 0
}

# rm_ : Supprime un fichier du versioning, demande confirmation
# Paramètre : $1 = FILE sous versioning
# Sortie :
#  - Supprime le versionnement de FILE, et tout les fichiers correspondant et envoie un message de confirmation (si on accepte)
#  - Supprime le répertoire caché .version s'il est vide (après la suppression du versioning)
rm_(){
    echo -n "Are you sure you want to delete \"${1}\" from versioning ? (yes/no) "
    read x
    if [ "$x" = "yes" ]; then
	# supprime les fichier (.1 ; .latest ; patch ; .log) correspondant à FILE
	rm -f "${rep}/.version/${nom}."*
	# tente de supprimer le rep caché .version, le fait que s'il est vide
	rmdir "${rep}/.version" 2>/dev/null
	echo \"${1}\" "is not under versioning anymore"
    else
	echo "Nothing done"
    fi
    exit 0
}

# commit_ : Ajoute une nouvelle version si le fichier a changé (patch)
# Paramètre : $1 = FILE sous versioning, $2 = MESSAGE pour log
# Sortie :
#  - Ajoute le nouveau patch dans .version
#  - Met à jour le .log et le .latest
#  - Envoie message de confirmation
#  - Envoie message d'erreur si FILE est identique à la dernière version commité (.latest)
commit_(){
    # test si FILE n'est pas identique à la dernière version commité
    if ! cmp -s "$1" "${rep}/.version/${nom}.latest"; then
	# trim le message
        msg=$(echo "$2" | sed -E 's/[ ]*$//;s/^[ ]*//')
	testComment "$msg"
	# ver = numero du dernier patch
	ver=$(ls "${rep}/.version" | grep -E "^${nom}\.[1-9][0-9]*$" | sed -E 's/.*\.([1-9][0-9]*)$/\1/' | sort -nr | head -n 1)
	nouvver=$(($ver + 1))
	# crée le nouveau patch 
	diff -u "${rep}/.version/${nom}.latest" "$1" > "${rep}/.version/${nom}.${nouvver}"
	cp "$1" "${rep}/.version/${nom}.latest"
	# ajoute le message dans le .log
	echo $(date -R) \"$msg\" >> "${rep}/.version/${nom}.log"
	echo "Committed a new version:" $nouvver
	exit 0
    else
	echo "Your file is identical to the last committed version" >&2
	exit 1
    fi
}

# diff_ : Affiche le différence avec la dernière version commité
# Paramètre : $1 = FILE sous versioning
# Sortie : affiche la différence si c'est vraiment différent, envoie un message si identique
diff_(){
    # test si FILE est identique à la dernière version commité
    if cmp -s "$1" "${rep}/.version/${nom}.latest"; then
	echo "Your file is identical to the last committed version"
	exit 0
    fi
    # affiche la différence entre FILE et la dernière version commité
    diff -u "${rep}/.version/${nom}.latest" "$1"
    exit 0
}

# checkout_ : Restaure à une version donnée (ou la dernière si absent) un fichier sous versionnement
# Paramètre : $1 = FILE sous versioning, [ $2 = NUMBER = version voulue ] -> option
# Sortie : restaure la version correspondant et affiche message de confirmation
checkout_(){
    # si on executé la commande checkout sans l'argument NUMBER, copie dans FILE la dernère version commité
    if [ $# -eq 1 ]; then
	cp "${rep}/.version/${nom}.latest" "$1"
	echo "Checked out to the latest version"
	exit 0
    fi
    # si NUMBER = 1, alors on revient à la toute première version
    if [ "$2" -eq 1 ]; then
	cp "${rep}/.version/${nom}.1" "$1"
	echo "Checked out version: 1"
	exit 0
    fi
    # last = numero du dernier patch
    last=$(ls "${rep}/.version" | grep -E "^${nom}\.[1-9][0-9]*$" | sed -E 's/.*\.([1-9][0-9]*)$/\1/' | sort -nr | head -n 1)
    # si NUMBER = last, copie dans FILE la dernère version commité
    if [ "$2" -eq "$last" ]; then
	cp "${rep}/.version/${nom}.latest" "$1"
	echo "Checked out to the latest version"
	exit 0
    fi
    # si 1 < NUMBER < last
    if [ "$2" -gt 1 ] && [ "$2" -lt "$last" ]; then
	# copie dans FILE la toute première version (le .1)
	cp "${rep}/.version/${nom}.1" "$1"
	# applique chaque patch successivement dans l'ordre jusqu'à la version souhaité (NUMBER)
	for pat in $(seq 2 "$2"); do
	    patch -u "$1" "${rep}/.version/${nom}.${pat}" >/dev/null 2>&1
	done
	echo "Checked out version:" $2
	exit 0
    fi
    # si on arrive ici, cela veut dire que NUMBER ne correspond pas à une version qui existe
    echo "Error : version ${2} doesn't exist" >&2
    usageCo
}

# reset_ : Restaure à une version donnée, et supprime toutes les suivantes, demande confirmation
# Paramètre : $1 = FILE sous versioning, $2 = NUMBER = version demandée
# Sortie : après confirmation
#  - Restaure FILE à la version demandé
#  - Met à jour .latest
#  - Supprime les logs/patch postérieurs
reset_(){
    # last = numero du dernier patch
    last=$(ls "${rep}/.version" | grep -E "^${nom}\.[1-9][0-9]*$" | sed -E 's/.*\.([1-9][0-9]*)$/\1/' | sort -nr | head -n 1)
    # si NUMBER = last, copie dans FILE la dernère version commité
    if [ "$2" -eq "$last" ]; then
	cp "${rep}/.version/${nom}.latest" "$1"
	echo "Checked out to the latest version"
	exit 0
    fi
    # si 1 <= NUMBER < last, on demande confirmation
    if [ "$2" -ge 1 ] && [ "$2" -lt "$last" ]; then
	echo -n "Are you sure you want to reset \"${1}\" to version \"${2}\" ? (yes/no) "
	read X
	if [ "$X" = "yes" ]; then
	    # copie dans le .latest la toute première version (le .1)
	    cp "${rep}/.version/${nom}.1" "${rep}/.version/${nom}.latest"
	    # si NUMBER != 1, lui applique les patchs successivement dans l'ordre jusqu'à la version souhaité (NUMBER)
	    if [ "$2" -ne 1 ]; then
		for pat in $(seq 2 "$2"); do
		    patch -u "${rep}/.version/${nom}.latest" "${rep}/.version/${nom}.${pat}" >/dev/null 2>&1
		done
	    fi
	    # copie le .latest dans FILE
	    cp "${rep}/.version/${nom}.latest" "$1"
	    first=$(($2 + 1))
	    # supprime les patchs supérieurs à la version qu'on est revenu
	    for ver in $(seq "$first" "$last"); do
		rm -f "${rep}/.version/${nom}.${ver}"
	    done
	    # supprime les message de log des patchs supérieurs à la version qu'on est revenu
	    sed -i "${first},${last}d" "${rep}/.version/${nom}.log"
	    echo "Reset to version :" $2
	    exit 0
	fi
	echo "Nothing done"
	exit 0
    fi
    # si on arrive ici, cela veut dire que NUMBER ne correspond pas à une version qui existe
    echo "Error! version ${2} doesn't exist" >&2
    usageReset
}

# amend_ : Modifie la dernière version (.latest) et/ou son message de log
# Paramètre : $1 = FILE sous versioning, $2 = nouveau MESSAGE de log
# Sortie : Met à jour le dernier patch, le .latest avec le contenu de FILE et le .log avec le nouveau message
amend_(){
    msg=$(echo "$2" | sed -E 's/[ ]*$//;s/^[ ]*//')
    testComment "$msg"
    last=$(ls "${rep}/.version" | grep -E "^${nom}\.[1-9][0-9]*$" | sed -E 's/.*\.([1-9][0-9]*)$/\1/' | sort -nr | head -n 1)
    before=$(($last - 1))
    cp "${rep}/.version/${nom}.1" "${rep}/.version/${nom}.latest"
    # applique au .latest chaque patch successivement dans l'ordre jusqu'à l'avant dernière version
    for pat in $(seq 2 "$before"); do
	patch -u "${rep}/.version/${nom}.latest" "${rep}/.version/${nom}.${pat}" >/dev/null 2>&1
    done
    # supprime le message de log du dernier patch
    sed -i "${last}d" "${rep}/.version/${nom}.log"
    # ajout le message de log souhaité pour le dernier patch
    echo $(date -R) \"$msg\" >> "${rep}/.version/${nom}.log"
    # modifie le dernier patch avec FILE
    diff -u "${rep}/.version/${nom}.latest" "$1" > "${rep}/.version/${nom}.${last}"
    cp "$1" "${rep}/.version/${nom}.latest"
    echo "Latest version amended:" $last
    exit 0
}

########################################################################################################
# SELECTION DE COMMANDE (MAIN)
########################################################################################################

# La validation du nombre d'arguments est effectuée pour chaque commande :
# si la commande est reconnue, on appelle la fonction dédiée
# sinon, message d'erreur + aide

if [ $# -eq 0 ]; then
    echo "Error! you didn't give any command" >&2
    enterHelp
fi

# on peut encore plus factoriser ce qui suit pour éviter de répeter testFile et testVerisoning :
# en mettant testFile "$2"  apres les def de rep et nom
# en sortant add du case et en testant avec un if si $1 = add
# puis en mettant testVersioning "$2" après cela
# (on sort le add du case et le met avant testVersioning car add s'applique sur un fichier non versionné)
# mais je préfère laisser comme ceci car je préfère qu'on teste en premier le nombre d'arguments avant ces tests

case "$1" in
    --help)
	if [ "$#" -ne 1 ]; then
	    echo "Error! too many arguments" >&2
	    usageHelp
	fi
	help_ 
	;;
    add|rm|commit|ci|diff|checkout|co|log|reset|amend)
	# dirname : supprime le dernier composant après le dernier / du nom de fichier
	# basename : garde le dernier composant après le dernier / du nom de fichier
	rep=$(dirname "$2")
	nom=$(basename "$2")
	case "$1" in
	    add)
		if [ "$#" -ne 3 ]; then
		    echo "Error! add expects two arguments" >&2
		    usageAdd
		fi
		testFile "$2"
		add_ "$2" "$3"
		;;
	    rm)
		if [ "$#" -ne 2 ]; then
		    echo "Error! rm expects one argument" >&2
		    usageRm 
		fi
		testFile "$2"
		testVersioning "$2"
		rm_ "$2"
		;;
	    commit|ci)
		if [ "$#" -ne 3 ]; then
		    echo "Error! commit|ci expects two arguments" >&2
		    usageCi 
		fi
		testFile "$2"
		testVersioning "$2"
		commit_ "$2" "$3"
		;;
	    diff)
		if [ "$#" -ne 2 ]; then
		    echo "Error! diff expects one argument" >&2
		    usageDiff
		fi
		testFile "$2"
		testVersioning "$2"
		diff_ "$2"
		;;
	    checkout|co)
		if [ "$#" -gt 3 ] || [ "$#" -eq 1 ]; then
		    echo "Error! checkout|co expects only one or two arguments" >&2
		    usageCo
		fi
		testFile "$2"
		# On teste si on a la permission d'ecriture sur FILE car on peut modifier son contenu
		testFileWrite "$2"
		testVersioning "$2"
		# on pourrait directement faire checkout_ "$2" "$3" même si $3 était vide
		# mais dans ma fonction, il y a test qui verifie si on lui passe 1 ou 2 arguments
		if [ "$#" -eq 3 ]; then
		    testInteger "$3"
		    checkout_ "$2" "$3"
		else
		    checkout_ "$2"
		fi
		;;
	    log)
		if [ "$#" -ne 2 ]; then
		    echo "Error! log expects one argument" >&2
		    usageLog
		fi
		testFile "$2"
		testVersioning "$2"
		log_ "$2"
		;;
	    reset)
		if [ "$#" -ne 3 ]; then
		    echo "Error! reset expects two arguments" >&2
		    usageReset
		fi
		testFile "$2"
		# On teste si on a la permission d'ecriture sur FILE car on peut modifier son contenu
		testFileWrite "$2"
		testVersioning "$2"
		testInteger "$3"
		reset_ "$2" "$3"
		;;
	    amend)
		if [ "$#" -ne 3 ]; then
		    echo 'Error! amend expects two arguments' >&2
		    usageAmend
		fi
		testFile "$2"
		# On teste si on a la permission d'ecriture sur FILE car on peut modifier son contenu
		testFileWrite "$2"
		testVersioning "$2"
		amend_ "$2" "$3"
		;;
	esac
	;;
    *)
	echo "Error! The command \""$1"\" does not exist." >&2
	enterHelp
	;;
esac



