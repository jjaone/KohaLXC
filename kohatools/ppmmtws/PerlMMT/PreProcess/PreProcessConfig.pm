package PreProcess::PreProcessConfig;

sub getInstructions {
    return {
        'BibliosImportChain' => {
        
            #List of source files that need sanitizing
            'sourceFiles' => [
                                'liccopy.kir',
                                'licmarca.kir',
                                'licmarcb.kir',
                                'licinfoa.kir',
                                'licauths.kir',
                                'licauthp.kir',
                                'licauthc.kir',
                                'licinfoid.kir',
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'liccopy.kir'  => 21,
                                'licmarca.kir' => 10,
                                'licmarcb.kir' => 10,
                                'licinfoa.kir' => 22,
                                'licauthp.kir' => 11,
                                'licauthc.kir' => 8,
                                'licauths.kir' => 8,
                                'licinfoid.kir' => 8,
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                                #Special directives for lengthIndicator removal tool can be passed in array
                                                #Array[0] = column index, Array[1] = directive1.
                                                #Directives = 'noTrim', will not trim whitespace around the column
                                'liccopy.kir'  => [15],
                                'licmarca.kir' => [[6,'noTrim']], #Cannot trim marcData, as it starts with SIGNUM; which could be just spaces.
                                'licmarcb.kir' => [[6,'noTrim']], #Cannot trim marcData, as it starts with SIGNUM; which could be just spaces.
                                'licinfoa.kir' => [2,6,7,8,9,10,11,12],
                                'licauthp.kir' => [1,2,4,5],
                                'licauthc.kir' => [2,3],
                                'licauths.kir' => [2,3],
                                'licinfoid.kir' => [2],
            },
            'chunkable' => {
                'licmarca.kir' => 1,
                'licmarcb.kir' => 1,
            }
        },
        'ItemsImportChain' => {

            #List of source files that need sanitizing
            'sourceFiles' => [
                                #'licauthmarc.repo', DO NOT PREPROCESS licauthmarc.repo, as it is already valid. It is automatically truncated when trying to be read from source PallasPro dump.
                                'liltrans.kir',
                                'liccopyid.kir',
                                'liccopy.kir',
                                'liccnote.kir',
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'liltrans.kir' => 15,
                                'liccopyid.kir' => 5,
                                'liccopy.kir'  => 21,
                                'liccnote.kir' => 6,
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                'liltrans.kir' => [1,2,3,4],
                                'liccopyid.kir' => [1],
                                'liccopy.kir'  => [15],
                                'liccnote.kir' => [2],
            },
            'chunkable' => {
                'liccopy.kir' => 1
            }
        },
        'HoldsImportChain' => {

            #List of source files that need sanitizing
            'sourceFiles' => [
                                'lilresrv.kir',
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'lilresrv.kir' => 12,
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
            },
            'chunkable' => {
                'lilresrv.kir' => 1
            }
        },
        'PatronsImportChain' => {

            'sourceFiles' => [
#                                'huoltaja.kir',
                                'liwcuset.kir',
                                'lilcust.kir',
                            ],
            'sourceFilesExpectedColumnCounts' => {
#                                'huoltaja.kir' => 1,
                                'liwcuset.kir' => 16,
                                'lilcust.kir'  => 33,
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                'liwcuset.kir' => [1,2,9],
                                'lilcust.kir'  => [4,6,7,8,9,10,13,14,15,16,17,18,19],
            },
            'chunkable' => {
                'lilcust.kir' => 1
            }
        },
        'CheckOutsImportChain' => {

            'sourceFiles' => [
                                'lilloan.kir'
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'lilloan.kir'  => 11
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                
            },
            'chunkable' => {
                'lilloan.kir' => 1
            }
        },
        'HistoryImportChain' => {

            'sourceFiles' => [
                                'lillnhis.kir'
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'lillnhis.kir'  => 7
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                
            },
            'chunkable' => {
                'lillnhis.kir' => 1,
            }
        },
        'FinesImportChain' => {
            
            'sourceFiles' => [
                                'lilcdebt.kir'
                            ],
            'sourceFilesExpectedColumnCounts' => {
                                'lilcdebt.kir' => 8,
            },
            'sourceFilesColumnsWithLengthIndicators' => { #indexes start from 0
                                'lilcdebt.kir' => [4],
            },
            'chunkable' => {
                                'lilcdebt.kir' => 1,
            }
        },
        'CharacterEncodings' => {
            'DEFAULT' => 'ISO_6937-2',
            'lilcust.kir' => 'LATIN1'
        },
    };
}

"Whyyyy?";
