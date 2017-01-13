# VIGILIA

Vigilia est un outil de monitoring d'acces Internet ecrit tres (salement !) rapidement en bash. Son principe est tres simple: il interroge des sites web et effectue une requete HTTP (wget) ainsi qu'un traceroute.

Pour chaque poll,on enregistre:
 - le debit reel (taille des donnes/temps d'execution)
 - le temps d'execution
 - le nombre de hops
 - les erreurs TCP (diff des compteurs de netstat)

Tout est stocke en base RRDTOOL.

## Target

VIGILIA est oriente vers l'Internet Francais avec une liste representative de sites FR.

## Pre-requis

rrdtool
mtr

## Install

Idealement, creez un dossier /home/vigilia puis recopier le git:

cd /home/vigilia
git clone https://github.com/obedouet/vigilia.git

Lancez install.sh, il verifiera les pre-requis et vous indiquera les ajouts necessaires pour la crontab. Idealement, utilisez le user vigilia cree a l'install.

Enfin, il vous faudra configurer Apache ou Nginx pour pointer sur le dossier www

