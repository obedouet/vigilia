# VIGILIA

Vigilia est un outil de monitoring d'acces Internet ecrit tres (salement !) rapidement en bash. Son principe est tres simple: il interroge des sites web et effectue une requete HTTP (wget) ainsi qu'un traceroute.

Pour chaque poll,on enregistre:
 - le debit reel (taille des donnes/temps d'execution)
 - le temps d'execution
 - le nombre de hops
 - les erreurs TCP (diff des compteurs de netstat)

Tout est stocke en base RRDTOOL.

