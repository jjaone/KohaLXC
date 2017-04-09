package HistoryImportChain::Instructions;

sub getInstructions {
    return {
    'lillnhis.kir' => [
        ['borrowernumber' , [0] ], #lhcustid
        ['biblionumber' , [1] ], #lhdocid
        ['itemnumber' , [2] ], #lhcopyid
        ['issuedate' , [3] ], #lhloantime
        ['returndate', [4]], #lhretrtime, this might be 0 so apparently the Item has not been returned yet.
        #['NA' , [5] ], #lhaddrid, always 0, possibly the lillocid or library location id
        #['NA' , [6] ], #lhstatus, always 0 so just ignoring it.
    ]
    };
}

1;