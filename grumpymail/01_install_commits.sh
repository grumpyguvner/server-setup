#! /bin/bash

OURNAME=01_install_commits.sh

echo -e "\n-- Executing ${ORANGE}${OURNAME}${NC} subscript --"

CODENAME=`lsb_release -c -s`

#Once stable use the following hashes to lock in a specific version of the commits:
#will also need to uncomment the relevant checkout commands in the script files
GRUMPYMAIL_COMMIT="d383f97f99e876bb24c8512d3648b74389a76f6f"
ZONEMTA_COMMIT="bac2d9b7f099013027c254ee75880ca19db52a14" # zone-mta-template
WEBMAIL_COMMIT="461a3817d54a5f09323c7bd0133919e3cebed4a3"
GRUMPYMAIL_ZONEMTA_COMMIT="52d3bf30148d445dd3a7670393c918f8acdeb1d9"
GRUMPYMAIL_HARAKA_COMMIT="e1f4c6de47980a1c4844b20aa05355b348ff4b5c"

echo -e "\n-- Finished ${ORANGE}${OURNAME}${NC} subscript --"
