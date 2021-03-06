#!/bin/bash

# unlink all dev packages
apm unlink --dev --all

# removed packages
#  "atom-mad-sounds"

## declare an array variable
declare -a array=("atom-backspace-death" "atom-backspace-fight" "atom-flashlight" "atom-handcuffs" "atom-dvorak" "atom-script" "atom-random-color" "atom-random-font-size" "atom-strasburger-challenge" "atom-u2i-hackathon" "atom-voltosaur")

# get length of an array
arraylength=${#array[@]}

# use for loop to read all values and indexes
for (( i=1; i<${arraylength}+1; i++ ));
do
  cd ./${array[$i-1]}
  rm -fr node_modules
  npm install
  cd ..
  apm link -d ${array[$i-1]}
  echo "\033[1  ;32m$prompt"
  echo ${array[$i-1]} "installed!!!"
  echo '\033[0m'
done
