package PatronsImportChain::Instructions;

use utf8;

sub getInstructions {
    return {
    'lilcust.kir' => [

['borrowernumber' , [0] ], #cucustid
['active' , [28,29] ], #status1, status2
['surname' , [6] ], #culastname
['firstname' , [7] ], #cufirstname
#['title' , [] ],
#['othernames' , [] ],
#['initials' , [] ],
#['streetnumber' , [8] ],#Not in use in our Koha version
#['streettype' , [] ],
['address' , [8] ],
#['address2' , [8] ],
['city' , [9] ],
['state' , 'Itä-Suomi' ],
['zipcode' , [9] ],
['country' , 'Suomi' ],
['email' , [11,17] ],
['phone' , [10] ],
['mobile' , [13] ], #cuphone2
#['fax' , [] ],
#['emailpro' , [11,17] ], #taking this content from email, does he want email notifications?
#['phonepro' , [10] ], #taking this content from phone, does he want email notifications?
#['B_streetnumber' , [] ],
#['B_streettype' , [] ],
#['B_address' , [] ],
#['B_address2' , [] ],
#['B_city' , [] ],
#['B_state' , [] ],
#['B_zipcode' , [] ],
#['B_country' , [] ],
#['B_email' , [] ],
#['B_phone' , [] ],
['dateofbirth' , [20,3] ],
['branchcode' , [2] ],
['categorycode' , [3] ],
['dateenrolled' , [25] ],
['dateexpiry' , [25] ],
#['dateexpiry' , [] ],
#['gonenoaddress' , [] ],
#['lost' , [] ],
#TODO ['debarred' , [] ],
#TODO ['debarredcomment' , [] ],
#['contactname' , [] ],
#['contactfirstname' , [] ],
#['contacttitle' , [] ],
['guarantorid' , [1] ], #cuparentid 
['borrowernotes' , [17] ], #cunote
#['relationship' , [] ],
#['ethnicity' , [] ],
#['ethnotes' , [] ],
#['sex' , 'Please' ], #Pulled from the ssn
['password' , [21] ],
#['flags' , [] ],
['userid' , [0, 4] ], #cucustid, cuident. This is generated from the barcode unless cuident overrides it
#['opacnote' , [] ],
#['contactnote' , [] ],
#['sort1' , [] ],
#['sort2' , [] ],
#['altcontactfirstname' , [] ],
#['altcontactsurname' , [] ],
#['altcontactaddress1' , [] ],
#['altcontactaddress2' , [] ],
#['altcontactaddress3' , [] ],
#['altcontactstate' , [] ],
#['altcontactzipcode' , [] ],
#['altcontactcountry' , [] ],
#['altcontactphone' , [] ],
['smsalertnumber' , [10] ],
['privacy' , '1' ],
['cardnumber' , [0, 4] ], #cucustid, cuident. This is generated from the barcode unless cuident overrides it
['extendedAttributes', [4,13] ], #cuident. Pick the SSN
['standing_penalties' , [28,29] ], #reading status1 && status2, in Koha builds the borrower_debarments-table from these!

#TODO        
#        ['id' , [0] ],
#        ['home_ou' , [2] ],
#        ['profile' , [3] ],
#        ['usrname' , [0] ],
#        ['email' , [11,17] ], #email can be in custreet2 or cunote, but most likely it is in liwcuset.kir.
#        ['passwd' , [21] ],
#        ['ident_type' , 2 ],
#        ['ident_value' , [4] ],
#        ['first_given_name' , [7] ],
#        ['second_given_name' , [7] ],
#        ['family_name' , [6] ],
#        ['day_phone' , [10] ],
#        ['other_phone' , [13] ],
#        ['dob' , [20,3] ],
#        ['juvenile' , [3] ],
#        ['create_date' , [25] ],
#        ['last_update_time' , [30,27] ], #cumodmod && cudebt, we need those to find out Patrons that haven't been used in a long time and whom don't have debts, so we can delete them.
#        ['ident_value2' , [1] ],
#        ['alias' , [5] ],
#TODO        ['barred' , [28] ],
#        ['usr' , [0] ], #usr is the same as id, but usr-related tables ask for usr, as the patron id. So having it here just for sanitys sake.
#        ['street1' , [8] ],
#        ['city' , [9] ],
#        ['state' , 'Itä-Suomi' ],
#        ['country' , 'Suomi' ],
#        ['post_code' , [9] ],
#        ['creator' , 1 ],
#        ['title' , [17] ],
#        ['value' , [17] ],
#        ['barcode' , [0] ]
    ]
    };
}

"Returning very true, true as a donkeys arse!";

=legacy directives from old sheetparser
:DELIMITERS ",""\n" #"col delim" "row delim"
:PRIMARYKEYS lilcust.kir->cucustid 1 #define pk columns for all tables/files included in a comma separated list.
:POSTPROCESSESFILE postprocesses.pl

### actor.usr ###
id		:lilcust.kir->cucustid 1
#card		:lilcust.kir->cucardnum 27 #would display how many cards this patron has had
profile		:lilcust.kir->cutype 4
usrname 	:lilcust.kir->cucustid 1 #New username variant. We use barcode as username
#usrname	:lilcust.kir->culastname 7, lilcust.kir->cubirthdate 21  ##lastname+birthmonth+day
email		:lilcust.kir->cunote 18
email		:lilcust.kir->custreet2 12
passwd		:lilcust.kir->cupassword 22
##standing	:lilcust.kir->custatus1 29 ##needs reverse engineering
ident_type	:2  ## references config.identification_type.id = 2, which stands for SSN
ident_value	:lilcust.kir->cuident 5
first_given_name	:lilcust.kir->cufirstname 8
second_given_name	:lilcust.kir->cufirstname 8
family_name	:lilcust.kir->culastname 7
day_phone	:lilcust.kir->cuphone1 11
other_phone	:lilcust.kir->cuphone2 14
##mailing_address	:Imported using the actor.usr_address
##billing_address	:Imported using the actor.usr_address
home_ou		:lilcust.kir->culocid 3
dob			:lilcust.kir->cubirthdate 21  ##date of birth in format 1973-05-13 23:00:00+02
active		:lilcust.kir->custatus1 29, lilcust.kir->custatus2 30
juvenile	:lilcust.kir->cutype 4 ##in PallasPro 6 = Juvenile
create_date	:lilcust.kir->cucarddate 26
last_update_time	:lilcust.kir->cumodtime 31
ident_value2    :lilcust.kir->cuparentid 2 #vanhemman id
alias   	:lilcust.kir->cucustcode 6 #nimikirjaimet
barred          :lilcust.kir->custatus1 29
standing_penalties      :lilcust.kir->custatus1 29
##borrowernotes	:imported using actor.usr_note


### actor.usr_address ###
usr		:lilcust.kir->cucustid 1
street1		:lilcust.kir->custreet1 9
city		:lilcust.kir->cucity1 10  ## "1380140 [Joensuu]"
state		:Itä-Suomi #
country		:Suomi #
post_code	:lilcust.kir->cucity1 10  ## "13[80140] Joensuu"

### actor.usr_note ###
#usr	:lilcust.kir->cucustid 1 #duplicates actor.usr_address usr
creator	:1  ##egadmin is the creator!
title	:lilcust.kir->cunote 18 ## exclude email addresses
value	:lilcust.kir->cunote 18 ## exclude email addresses

### actor.card ###
#usr	:lilcust.kir->cucustid 1 #duplicates actor.usr_address usr
barcode	:lilcust.kir->cucustid 1
#active	:t #duplicates actor.usr active
=cut