use utf8;

package HoldsImportChain::HoldsBuilder::Instructions;

sub getInstructions {
    return {
        #The order of these indexes is critical, since many attributes rely on previously initialized attributes.
    'lilresrv.kir' => [
        
        ## See EGDATA-27 ##
        
        ['id', [0]],                 #PK need not be preserved, but is useful for debugging
        ##Check the status in borrowernumber! Discard already fulfilled holds and expired holds.
        ['borrowernumber', [1,7,8,0]], #rvcustid
        ['reservedate', [5]],        #rvresdate
        ['biblionumber', [2]],       #rvdocid
        ['constrainttype', 'a'],     #always a
        ['branchcode', [4]],         #rvlocid
        #['notificationdate', 'NULL'],   #
        #['reminderdate', 'NULL'],       #
        #['cancellationdate', 'NULL'],   #
        #['reservenotes', ''],       #
        ['priority', [5]],           #rvresdate, first come first serve basis
        #['found', 'NULL'],          #
        #['timestamp', []],          #NOW()
        ['itemnumber', [3]],         #rvcopyid
        ['status', [7,8]],           #rvstatus1, rvstatus2
        ['expirationdate', [6]],     #rvduedate maybe??
        #['lowestPriority', '0'],    #
        #['suspend', '0'],           #
        #['suspend_until', 'NULL'],  #
        ['waitingdate', ''],         #Fake this to an arbitrarily low date to make koha catch these as expired holds. Otherwise no match from lilresrv.kir.
                                     #Using the already calculated status.
        ]
    };
}
1;