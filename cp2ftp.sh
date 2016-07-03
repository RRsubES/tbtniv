#!/bin/bash

FTP_CFG=${FTP_CFG:-bleiz.cfg}

if [ $# -ne 1 ] || [ "$1" == "-h" ]; then
	echo "copie le fichier donne en argument" >&2
	echo "dans le ftp defini par ${FTP_CFG}." >&2
	echo "usage: $(basename $0) file" >&2
	exit 1
fi

function cp2ftp {
	# $1 is the file to copy
	source "${FTP_CFG}"
	ftp -in ${FTP_ADR}<<EOF
quote user ${FTP_USER}
quote pass ${FTP_PW}
cd "${FTP_DIR}"
binary
put "${1}"
quit
EOF
}

cp2ftp "$1"
