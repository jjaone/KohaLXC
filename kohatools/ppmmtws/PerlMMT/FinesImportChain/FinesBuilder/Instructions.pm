use utf8;

package FinesImportChain::FinesBuilder::Instructions;

sub getInstructions {
    return {
        #The order of these indexes is critical, since many attributes rely on previously initialized attributes.
        'lilcdebt.kir' => [

            ['borrowernumber', [0]],     #cdcustid
            ['date', [1,2]],             #cddate, cdtime
            ['amount', [3]],             #cdamount
            ['description', [4]],        #cdtext
            ['accounttype', 'Konversio'],#CONSTANT
        ],
    };
}
1;