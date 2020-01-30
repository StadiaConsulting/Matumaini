#!//bin/bash

# bash script to build HFK - Kajiado Children's Home App Environment
# Author: John P. Chao

# Assumption: Terraform generated output values are in terraform state.

DEBUG=false
RunID=$(date +%s)

# Function to replace all "Stubs" with AWS instance values
#
# First parameter passed ($1) in will be the filename followed by one or more
# replacement values.
#
# This function will generate a new file based on first parameter with RunID
# appended to the filename.
FILE_Replace() {
  if [ $# != 3 ]; then
    echo "First paramater must be a configuration file."
    echo "Second paramater must be the string that will be replaced."
    echo "Third parameter must be the new string"
    exit 1
  fi

  sed "s|$2|$3|g" $1 > $1.$RunID
  return $?
}

NewValue=$(terraform output $2)

if [ $DEBUG ]; then
  echo "$RunID ($1) ($2) ($NewValue)"
fi

FILE_Replace $1 $2 $NewValue
if [$? != 0]; then
  echo "Error $?"
else
  echo "Success"
fi
