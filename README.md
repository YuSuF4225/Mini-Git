Yusuf KORKMAZ

# version.sh

## Présentation

**version.sh** est un gestionnaire de versions développé entièrement en Shell (`dash`).

Il permet de suivre l'évolution d'un fichier en enregistrant des versions successives, de comparer les modifications, de restaurer une ancienne version et de conserver un historique des changements.

Les versions sont stockées dans un dossier caché `.version` situé à côté du fichier suivi, sous forme de copies et de patchs afin de limiter l'espace disque utilisé.

## Fonctionnalités

* Ajout d'un fichier sous gestion de versions
* Création de nouvelles versions (commit)
* Restauration d'une version (checkout)
* Historique des versions (log)
* Comparaison entre le fichier courant et la dernière version (diff)
* Modification de la dernière version (amend)
* Retour à une version précédente (reset)
* Suppression complète du suivi d'un fichier (rm)
* Aide intégrée (`--help`)

## Structure du projet

```text
.version/
├── fichier.1
├── fichier.2
├── fichier.3
├── fichier.latest
└── fichier.log

version.sh
```

## Commandes disponibles

```bash
./version.sh add FILE MESSAGE
./version.sh commit FILE MESSAGE
./version.sh diff FILE
./version.sh checkout FILE [VERSION]
./version.sh log FILE
./version.sh reset FILE VERSION
./version.sh amend FILE MESSAGE
./version.sh rm FILE
```

## Fonctionnement

Chaque fichier versionné possède un dossier caché `.version` contenant :

* la première version du fichier ;
* la dernière version enregistrée ;
* les patchs permettant de reconstruire toutes les versions intermédiaires ;
* un fichier de journalisation des commits.

Cette organisation permet de limiter l'espace de stockage tout en conservant l'historique complet des modifications.

## Exemple d'utilisation

```bash
./version.sh add notes.txt "Initial version"

./version.sh commit notes.txt "Added new section"

./version.sh diff notes.txt

./version.sh log notes.txt

./version.sh checkout notes.txt 2
```
