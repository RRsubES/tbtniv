Utiliser cygwin, et aller dans ce répertoire, et taper ensuite:
sh ./gen.sh < BALISEP
sinon c'est simplement du ./gen.sh < BALISEP > OUTPUT_FILE
rem: impossible de modifier les droits en exécution pour gen.sh, la seule possibilité est de demander à l'AMIB, aussi essayer de ne pas avoir à modifier gen.sh (tout est externalisé dans les scripts awk). 
