#!/bin/bash

# chmod 755 on all the scripts

# For all the files that end with .sh
for f in $( ls ./ ); do
	if [[ $f == *.sh ]]; then
		chmod 755 $f
	fi
done

printf "Done!\n\n"

exit 0
