#!/bin/sh

destDir=/home/vagrant/.bashrc

# Enable execution of BLT commands within VM.
if test -f "$destDir" && ! grep -q "function blt()" "$destDir";
then
cat << 'eof' >> "$destDir"
# Enable execution of BLT commands within the VM.
function blt() {
  if [[ ! -z ${AH_SITE_ENVIRONMENT} ]]; then
    PROJECT_ROOT="/var/www/html/${AH_SITE_GROUP}.${AH_SITE_ENVIRONMENT}"
  elif [ "`git rev-parse --show-cdup 2> /dev/null`" != "" ]; then
    PROJECT_ROOT=$(git rev-parse --show-cdup)
  else
    PROJECT_ROOT="."
  fi

  if [ -f "$PROJECT_ROOT/vendor/bin/blt" ]; then
    $PROJECT_ROOT/vendor/bin/blt "$@"
  # Check for local BLT.
  elif [ -f "./vendor/bin/blt" ]; then
    ./vendor/bin/blt "$@"
  else
    echo "You must run this command from within a BLT-generated project."
    return 1
  fi
}
eof
fi

# Add additional packages.
sudo apt-get update
sudo apt-get install php-http -y
sudo apt-get install php-raphf -y
sudo apt-get install php-propro -y
sudo apt-get install bsdtar -y
