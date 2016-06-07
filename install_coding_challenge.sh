#!/bin/bash
## declare an array variable
declare -a array=("atom-backspace-death" "atom-blank-keyboard" "atom-dvorak" "atom-script" "atom-mirror-mode" "atom-upside-down" "atom-mad-sounds" "atom-random-color" "atom-random-font-size" "atom-strasburger-challenge")

# get length of an array
arraylength=${#array[@]}

# use for loop to read all values and indexes
for (( i=1; i<${arraylength}+1; i++ ));
do
  cd ./${array[$i-1]}
  npm install
  cd ..
  apm link -d ${array[$i-1]}
  echo "\033[1  ;32m$prompt"
  echo ${array[$i-1]} "installed!!!"
  echo '\033[0m'
done
