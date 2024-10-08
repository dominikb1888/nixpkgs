#!/bin/bash

# Assign the current work directory to the bash script variable 'CWD'.
CWD=$(pwd)
TEMPLATE='/home/dominikb1888/.templates/letterhead.tex'

if [ $1 ]
then
  NAME=`echo $1 | sed 's/.tex//g'`
  
  if [ $2 ] 
  then
    SENDER=`echo $2`
    xelatex -jobname=$NAME '\def\'$SENDER'{1} \def\inputfile{'$NAME'} \input{'$TEMPLATE'}'
  else
    xelatex -jobname=$NAME '\def\inputfile{'$NAME'} \input{'$TEMPLATE'}' 
  fi

  if [ -f ${CWD}/$NAME.pdf ]
  then
    start "" /max "$NAME.pdf";
  fi

  ## declare an array variable
  declare -a formats=("aux" "dvi" "log")

  ## now loop through the above array
  for i in "${formats[@]}"
  do
    if [ -f ${CWD}/$NAME.$i ]
    then
      rm $NAME.$i
    fi
  done
  
  exit
fi

