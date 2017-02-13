#!/bin/bash

# File: kohatools/ppmmtws/ConversionTools/makeStaffAccounts.sh
# #############################################################################
# Code is part of the KohaLXC/kohatools Ansible/Bash setup tooling scripts
# for Koha/ILS-development, deployment & database conversion/migration tasks.
# Author: Pasi Korkalo, OUTI Libararies, Oulu/Finland. (create_accounts.sh)
# Author: Jukka Aaltonen, Koha-Lappi, Rovaniemi City Library, Lapland/Finland.
# License: Gnu General Public License version 2 (or later).
# 
# Description:
# KohaLXC/kohatools/ppmmtws conversion scripts for Ansible/Bash tooling:
# - Works in Ubuntu Server LTS (14.04/16.04) guest/host environments
# - Requires: xlsx2csv, apg, groff, ps2pdf and iconv for this to work
# - Generate staff accounts (after PP/MMT convesion of Patrons) 
# - Accounts will be imported to Koha with bulkPatronImport.pl).
# - It will assign a username, password and account expiry date based on the definitions in Microsoft Excel sourcefile (see the example).
# - Letters to account owners will be generated under "letters" directory.
# - Print them on a single double sided sheet
# - Fold the letters so that the account information is on the inside.
# - Then place in envelopes and send to your staff 
# - Works as CLI-script or as 'kohalxc'-tool or from Ansible/KohaLXC-playbooks
# 
# Modified: 2017-01 by "Jukka Aaltonen, Koha-Lappi" (@jjaone) 
## #############################################################################

## Base name of ConversionTable to be generated, e.g. 'patrons_staffaccounts'
SRC_NAME="${1:-patrons_staffaccounts}"
[[ -z "$SRC_NAME" ]] && echo "== Error: no Conversion/TranslationTable defined.. exiting." && echo && exit 2
echo && echo "== Name of the Translation/ConversionTable to be generated SRC_NAME='$SRC_NAME'"

exit 123

getfield() {
  echo -n $2 | cut -f $1 -d ';' | sed 's/^ *//;s/ *$//;s///g'
}

makeusername() {
  username="$(echo -n $1 | sed 's/[åÅ]/a/g;s/[äÄ]/a/g;s/[öÖ]/o/g;s/[ÈèÉé]/e/g;s/-//g' | cut -c 1-4 | tr [[:upper:]] [[:lower:]])"
  addchars=$((4 - $(expr length $username)))
  username="$username$(echo -n $2 | sed 's/[åÅ]/a/g;s/[äÄ]/a/g;s/[öÖ]/o/g;s/[ÈèÉé]/e/g;s/-//g' | cut -c 1-$((4 + $addchars)) | tr [[:upper:]] [[:lower:]])"
  echo -n $username
}

# I find the amount of ways of writing the date astonishing, these don't probably cover half of them...
# Check carefully.

convertdatedashed() {
  date="$(echo $1 | sed 's/ *//g')"
  day=$(echo $date | cut -f 2 -d '-')
  test $(expr length $day 2> /dev/null) -eq 1 && day="0$day" 2> /dev/null
  month=$(echo $date | cut -f 1 -d '-')
  test $(expr length $month 2> /dev/null) -eq 1 && month="0$month" 2> /dev/null
  year=$(echo $date | cut -f 3 -d '-')
  echo "$year-$month-$day"
}

convertdateslashed() {
  date="$(echo $1 | sed 's/ *//g')"
  day=$(echo $date | cut -f 2 -d '/')
  test $(expr length $day 2> /dev/null) -eq 1 && day="0$day" 2> /dev/null
  month=$(echo $date | cut -f 1 -d '/')
  test $(expr length $month 2> /dev/null) -eq 1 && month="0$month" 2> /dev/null
  year=$(echo $date | cut -f 3 -d '/')
  echo "$year-$month-$day"
}

convertdatedotted() {
  date="$(echo $1 | sed 's/ *//g')"
  day=$(echo $date | cut -f 1 -d '.')
  test $(expr length $day 2> /dev/null) -eq 1 && day="0$day" 2> /dev/null
  month=$(echo $date | cut -f 2 -d '.')
  test $(expr length $month 2> /dev/null) -eq 1 && month="0$month" 2> /dev/null
  year=$(echo $date | cut -f 3 -d '.')
  echo "$year-$month-$day"
}

converttonumber() {
  echo -n $1 | sed 's/ONE/1/g;s/TWO/2/g;s/THREE/3/g;s/FOUR/4/g;s/FIVE/5/g;s/SIX/6/g;s/SEVEN/7/g;s/EIGHT/8/g;s/NINE/9/g;s/ZERO/0/g'
}

test -z "$1" && SRC_DIR="sources"
test -z "$SRC_DIR" && echo "Need a directory name with sourcefiles as a parameter." && exit 1

borrowernumber=186300 # This is the first borrowernumber available for staff accounts, it will probably be converted to something completely different by bulkPatronImport.pl.
givenusernames=":"
IFS='
'
#for file in $(find "$1" -name '*.xlsx'); do
for file in ${SRC_DIR}/*.xlsx; do

    echo "=== Processing $file ==="
    # You need to "apt-get install xlsx2csv" for this
    xlsx2csv -d ';' -i "$file" > "/tmp/create_accounts.csv"
    
    for patron in $(cat /tmp/create_accounts.csv | sed '1,17d'); do

      borrowernumber=$((borrowernumber + 1))
      surname="$(getfield 1 $patron)"
      firstname="$(getfield 2 $patron)"

      unset usernameorder; unset username

      # "Questionable" usernames can be overriden with "overrides" file like this: "Firstname Surname,username". Without the quotes obviously and one user per line.
      test -f overrides && username="$(grep "^$firstname $surname" overrides 2> /dev/null | cut -f 2 -d ',')"
      
      # And then we make the username if there were no overrides
      if test -z "$username"; then
        usernameorder="muodostettu etunimestäsi ja sukunimestäsi: "
        username="$(makeusername $firstname $surname)"
      fi
      
      if echo "$givenusernames" | grep -q ":$username:"; then
        usernameorder="muodostettu sukunimestäsi ja etunimestäsi: "
        username="$(makeusername $surname $firstname)"
      fi

      if echo "$givenusernames" | grep -q ":$username:"; then
        usernameorder="etunimestäsi ja sukunimestäsi + yksilöivästä tunnistenumerosta "
        username="$(makeusername $firstname $surname)$(($borrowernumber - 186000))"
      fi

      # Keep a list of them so we don't give the same username to more than one person
      givenusernames="$givenusernames$username:"

      # Slow method to create memorable passwords (you need to "apt-get install apg" for this)
      passwordgen="$(apg -n 1 -m 10 -x 10 -M CN -t)"
      
      # Fast method to create random passwords
      #passwordgen="$(< /dev/urandom tr -cd '[:alnum:]' | head -c 10)" && passwordgen="$passwordgen ($passwordgen)"
      
      password="$(echo $passwordgen | cut -f 1 -d ' ')"
      passwordpronounce="$(echo $passwordgen | cut -f 2 -d ' ')"
      passwordpronounce="$(converttonumber $passwordpronounce)"
      passwordpronounce="$(echo $passwordpronounce | sed 's/(//g;s/)//g;')"
      
      echo -n "Adding patron $firstname $surname ($username) "
      
      # Address information
      address="$(getfield 4 $patron)"
      zipcode="$(getfield 5 $patron)"
      city="$(getfield 6 $patron)"

      # Set patron category
      categorycode="$(getfield 8 $patron)"
      categorycode="$(echo $categorycode | tr [[:lower:]] [[:upper:]])"
      
      # Set date of birth
      dateofbirth="$(getfield 3 $patron)"
      dateofbirth="19$(convertdatedashed $dateofbirth)"
      
      if test $(expr length $dateofbirth) -ne 10; then
        dateofbirth="$(getfield 3 $patron)"
        dateofbirth="$(convertdatedotted $dateofbirth)"
      fi
      
      if test $(expr length $dateofbirth) -ne 10; then
        dateofbirth="$(getfield 3 $patron)"
        dateofbirth="$(convertdateslashed $dateofbirth)"
      fi

      # Set homebranch
      branchcode="$(getfield 7 $patron)"
      
      # Set the account expiry date
      dateexpiry="$(getfield 20 $patron)"
      dateexpiry="20$(convertdatedashed $dateexpiry) 23:59:59+02"
      
      if test $(expr length $dateexpiry) -ne 22; then 
        dateexpiry="$(getfield 20 $patron)"
        dateexpiry="20$(convertdatedotted $dateexpiry) 23:59:59+02"
      fi
     
      if test $(expr length $dateexpiry) -ne 22; then 
        dateexpiry="$(getfield 20 $patron)"
        dateexpiry="20$(convertdateslashed $dateexpiry) 23:59:59+02"
      fi
       
      # Couln't make sense of the scribblings in Excel, use the default expiry date
      test $(expr length $dateexpiry) -ne 22 && dateexpiry="2015-12-31 23:59:59+02" 
      
      echo -n "[$dateexpiry]"

      # Resolve branch information for the letters
      #branchinfo="$(grep "^$branchcode" ../ConversionTables/branchesConversionTable.csv)"
      branchinfo="$(grep "^$branchcode" ../conversiontables/branchesConversionTable.csv)"
      #letter_branchname="$(echo $branchinfo | cut -f 2 -d ',' | sed 's/"//g')"
      letter_branchname=$(echo $branchinfo | cut -f 2 -d ',' | sed 's/"//g')
      letter_branchaddress=$(echo $branchinfo | cut -f 3 -d ',' | sed 's/"//g')
      letter_branchzip=$(echo $branchinfo | cut -f 4 -d ',')
      letter_branchcity=$(echo $branchinfo | cut -f 5 -d ',')

      # Tell the users when their accounts expire in the letters
      expirydateletter="$(echo $dateexpiry | cut -f 3 -d '-' | cut -f 1 -d ' ').$(echo $dateexpiry | cut -f 2 -d '-').$(echo $dateexpiry | cut -f 1 -d '-')"

      echo # This will cr/lf when the patron has been added, hands off!

      # Perl-hash for import
      mkdir -p kohamigration
      #echo "\$VAR1 = bless( {'active' => 't','address' => '$address','borrowernumber' => '$borrowernumber','branchcode' => '$branchcode','cardnumber' => '$username','categorycode' => '$categorycode','city' => '$city','country' => 'Suomi','dateenrolled' => '2015-10-19 0:0:0+02','dateexpiry' => '$dateexpiry','dateofbirth' => '$dateofbirth','email' => '','extendedAttributes' => '','firstname' => '$firstname','mobile' => '','password' => '$password','phone' => '','privacy' => '1','sex' => '','smsalertnumber' => '','standing_penalties' => '','state' => 'Pohjois-Suomi','surname' => '$surname','userid' => '$username','zipcode' => '$zipcode'}, 'Item' );" >> kohamigration/${file%.xlsx}.migrateme
      echo "\$VAR1 = bless( {'active' => 't','address' => '$address','borrowernumber' => '$borrowernumber','branchcode' => '$branchcode','cardnumber' => '$username','categorycode' => '$categorycode','city' => '$city','country' => 'Suomi','dateenrolled' => '2015-10-19 0:0:0+02','dateexpiry' => '$dateexpiry','dateofbirth' => '$dateofbirth','email' => '','extendedAttributes' => '','firstname' => '$firstname','mobile' => '','password' => '$password','phone' => '','privacy' => '1','sex' => '','smsalertnumber' => '','standing_penalties' => '','state' => 'Pohjois-Suomi','surname' => '$surname','userid' => '$username','zipcode' => '$zipcode'}, 'Item' );" >> kohamigration/$(basename $file).migrateme
      exit 123
      mkdir -p letters
      
      # Generate letter to account owner

cat << EOF > /tmp/create_accounts.txt








$firstname $surname
.br
$letter_branchname
.br
$letter_branchaddress
.br
$letter_branchzip $letter_branchcity























.ad c
.nh
EOF
for line in $(seq 65); do
  < /dev/urandom tr -cd '[:alnum:]' | head -c 120 >> /tmp/create_accounts.txt
  echo >> /tmp/create_accounts.txt
done
cat << EOF >> /tmp/create_accounts.txt











.ad l
Hei $firstname!

Käyttäjätunnuksesi Koha-järjestelmään on $usernameorder${username}. Salasanasi on 10 merkkiä pitkä: ${password}. Muistamisen helpottamiseksi voit painaa mieleesi ${passwordpronounce}.

Käyttäjätunnuksesi ja salasanasi ovat henkilökohtaisia, ethän jaa niitä kenenkään toisen kanssa. Tunnuksen haltijana olet vastuussa kaikesta mitä tunnuksella järjestelmässä tehdään. Tunnuksesi on voimassa $expirydateletter asti.

Terveisin Koha-ylläpito
EOF

    iconv -f utf-8 -t iso-8859-1 /tmp/create_accounts.txt | groff -Tps - > /tmp/create_accounts.ps 2> /dev/null 
    ps2pdf /tmp/create_accounts.ps "./letters/${firstname} ${surname}.pdf"

    done

done
unset IFS
echo "$givenusernames" > givenusernames.txt
