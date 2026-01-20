#!/bin/bash

# Assign the current work directory to the bash script variable 'CWD'.
CWD=$(pwd)
# WARNING: The following path is hardcoded and may need to be changed.
TEMPLATE='/home/dominikb1888/.templates/letterhead.tex'

if [ $1 ]
then
  NAME=$(basename "$1" .tex)
  
  if [ $2 ] 
  then
    SENDER=$2
    xelatex -jobname="$NAME" '\def\'"$SENDER"'{1} \def\inputfile{'"$NAME"'} \input{'"$TEMPLATE"'}'
  else
    xelatex -jobname="$NAME" '\def\inputfile{'"$NAME"'} \input{'"$TEMPLATE"'}' 
  fi

  if [ -f "${CWD}/${NAME}.pdf" ]
  then
    open "${NAME}.pdf"
  fi

  ## declare an array variable
  declare -a formats=("aux" "dvi" "log")

  ## now loop through the above array
  for i in "${formats[@]}"
  do
    rm -f "${NAME}.$i"
  done
  
  exit
fi
