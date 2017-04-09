use utf8;

package ItemsImportChain::ItemsBuilder::Instructions;

sub getInstructions {
    return {
        #The order of these indexes is critical, since many attributes rely on previously initialized attributes.
    'liccopy.kir' => [
        ['biblionumber' , [0]],        #PRIMARYKEYS liccopy.kir->cpdocid 1 #define pk columns for all tables/files included in a comma separated list.
        ['deleted' , [16]],        #liccopy.kir->cpstatus1 17
        ['itemnumber' , [1]],                #liccopy.kir->cpcopyid 2
        ['holdingbranch' , [2,3,4,5,6]],      #liccopy.kir->cplibid 3, cphomelocid 4, cphomedepid 5, cplastlocid 6, cplastdepid 7 #cplibid determines if we use homeloc or lastloc
        ['homebranch' , [2,3,4,5,6]],      #liccopy.kir->cplibid 3, cphomelocid 4, cphomedepid 5, cplastlocid 6, cplastdepid 7 #cplibid determines if we use homeloc or lastloc
        ['barcode' , [2,1]],         #liccopy.kir->cplibid 3, liccopy.kir->cpcopyid 2
        ['itype' , [15]],    #liccopy.kir->cpmatcode 16, a Record can have a different material code than the item. Postprocess via a translation table.
        ['itemcallnumber' , [2,3,4,15]],   #liccopy.kir->cplibid 3, liccopy.kir->cphomelocid 4, liccopy.kir->cphomedepid 5 #call number #update the postprocessor %Reader::output reference if amount/order of rows in this file is altered.
        #cn_source and cn_sort are defined in set_itemcallnumber()
        ['dateaccessioned' , [18,11]],      #liccopy.kir->cpmodtime 19, liccopy.kir->cpaqmonth 12
        ['price' , [0]],             #liccopy.kir->cpdocid 1   fetch from marc \_021d
        ['replacementprice' , [0]],             #liccopy.kir->cpdocid 1   fetch from marc \_021d
        ['status' , [16,17,2,3,4]],        #liccopy.kir->cpstatus1 17, liccopy.kir->cpstatus2 18, either of these, 4 || 63 points to deleted
        #notforloan and damaged and itemlost and withdrawn are defined in set_status()
        ['location' , [0]],           #This is set primarily in preprocessor Item->set_home|holdingbranch(), but we do preprocessing here after the original values have been set.
        ['issues', [14]],			#cploancnttot 15 #total loan count for all times! Funny name in the Koha DB
        ['rotatingcollection', [0]], #liccopy.kir->cpdocid 1.
        ['materials', [0]],         #liccopy.kir->cpdocid, to fetch the $300zd from MarcRepository
        ['datelastborrowed', [9,10]], #liccopy.kir->cptime1, cptime2
        ['itemnotes', [1]],         #liccopy.kir->cpcopyid 2 ---> liccnote.kir->cncopyid 1
        #['notforloan', GENERATED IN STATUS],
        #['damaged', GENERATED IN STATUS],
        #['itemlost', GENERATED IN STATUS],
        ]
    };
}
1;
### asset.copy_location ###
#This table is easily filled as PP doesn't use this functionality at all.
#Just set "Stacks" as the sole copy_location for the entire consortium and point to it during INSERTs.
#id = 1 WHERE name='Stacks'

### config.circ_modifier ###
#Table will be filled in advance. Remember to backup circ modifier table!
#linked to in #circ_modifier

### asset.call_number.prefix ###
#owning_lib	:
#label		:

### asset.call_number.suffix ###
#owning_lib	:
#label		:

### asset.call_number ### #not necessary to inject to itemdata, can be extracted from marcdata
#one tricky bitch. Fetch call_numbers from library specific MARC fields 06x-09x.
#creator	:1
#editor		:1
#record		:liccopy.kir->cpdocid 1 #can be found from marcdata.
#owning_lib	:Use translation table to find out to which library each marc-field belongs to.
#label		:the value inside the call_number marc-field
#label_class:2 #we are using the Dewey Decimal Classification variant. Or are we?
#prefix		:
#suffix		:
