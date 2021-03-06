package TranslationTables::liqlocde_translation;

use strict;
use warnings;
use utf8;
use Carp qw(cluck);
#libid #locid #depid [ '#code (old)' , '#code (new)' , '#shelving location' ]
our $org_unitsPielinen = {
0 => {
    0 => {
        0 => ['===','',''],
    },
},
1 => {
    0 => {
        0 => ['541','',''],
    },
    1001 => {
        0 => ['N','NUR_NUR','KONVERSIO'],
        1 => ['NNA','NUR_NUR','AIK'],
        2 => ['NNK','NUR_NUR','REF','NoLoan'],
        3 => ['NNP','NUR_NUR','KOT','NoLoan'],
        4 => ['NNY','NUR_NUR','VAR','PubNote','Ylävarasto'], #Julk. nidehuomautus: Ylävarasto
        5 => ['NNV','NUR_NUR','VAR','PubNote','Alavarasto'], #Julk. nidehuomautus: Alavarasto
        6 => ['NSA','NUR_NUR','LEH'],
        7 => ['NSK','NUR_NUR','POIS'], #?Pois?
        8 => ['NTH','NUR_NUR','VVA','PubNote','Tilapäisvarasto'], #Julk. nidehuomautus: Tilapäisvarasto. Lisää NUR_NUR hyllypaikan kirjastorajoituksiin
        9 => ['NNL','NUR_NUR','LAP'],
        10 => ['NNN','NUR_NUR','NUO'],
        11 => ['NXA','NUR_NUR','AVA'], #AV-Aikuiset
        12 => ['NXK','NUR_NUR','MUK','NoLoan'],
        13 => ['NKA','NUR_NUR','POIS'],
        14 => ['NMU','NUR_NUR','POIS'],
        15 => ['NAR','NUR_NUR','ARK','NoLoan'], #Arkisto
        16 => ['NMO','NUR_NUR','POIS'],
        17 => ['NKO','NUR_NUR','POIS'],
        18 => ['NKK','NUR_NUR','POIS'],
        19 => ['NKH','NUR_NUR','POIS'],
        20 => ['NKM','NUR_NUR','POIS'],
        21 => ['NLK','NUR_NUR','POIS'],
        22 => ['NLV','NUR_NUR','POIS'],
        23 => ['NRA','NUR_NUR','KAD'],
        24 => ['NOL','NUR_NUR','OHE'],
    },
    1010 => {
        0 => ['NAA','NUR_NURAU','AIK'],
        1 => ['NAU','NUR_NURAU','POIS'],
    }
},
2 => {
    0 => {
        0 => ['422','',''],
    },
    2001 => {
        0 => ['PK','LIE_LIE','KONVERSIO'],
        1 => ['PKA','LIE_LIE','AIK'],
        2 => ['PKK','LIE_LIE','REF','NoLoan'],
        3 => ['PKN','LIE_LIE','NUO'],
        4 => ['PKNK','LIE_LIE','NUK','NoLoan'],
        5 => ['LEHD','LIE_LIE','LEH'],
        6 => ['PKM','LIE_LIE','MUS'],
        7 => ['PKMK','LIE_LIE','MUK','NoLoan'],
        8 => ['PKKS','LIE_LIE','KOT','NoLoan'],
        9 => ['PKSK','LIE_LAKO','AIK'], #Kolin etätoimipiste. Kolin siirtokokoelma. Ei varaukset tartu.
        10 => ['OL','LIE_LIE','OHE'],
        11 => ['PKAV','LIE_LIE','VAR'],
        12 => ['PKNV','LIE_LIE','NUV'],
        13 => ['PKMV','LIE_LIE','VAR'],
        14 => ['TPVA','LIE_LIE','VVA'], #Siirtolainoja
        15 => ['TPVN','LIE_LIE','NUV'], #Siirtolainoja
        16 => ['NOP','LIE_LIE','PIK'],
    },
    2101 => {
        0 => ['LA','LIE_LIEAU','KONVERSIO'],
        1 => ['LAA','LIE_LIEAU','AIK'],
        2 => ['LAK','LIE_LIEAU','KONVERSIO'],
        3 => ['LAN','LIE_LIEAU','LAP'],
    },
    2201 => {
        0 => ['B','LIE_LAKO','KONVERSIO'],
        1 => ['BA','LIE_LAKO','AIK'],
        2 => ['BK','LIE_LAKO','POIS'],
        3 => ['BN','LIE_LAKO','POIS'],
    },
    2301 => {
        0 => ['PA','LIE_LIE','POIS'],
        1 => ['PAA','LIE_LIE','POIS'],
        2 => ['PAK','LIE_LIE','POIS'],
        3 => ['PAN','LIE_LIE','POIS'],
        4 => ['PANK','LIE_LIE','POIS'],
    },
    2401 => {
        0 => ['RA','LIE_LIE','KAD','lost'],
        1 => ['RAA','LIE_LIE','POIS'],
        2 => ['RAK','LIE_LIE','POIS'],
        3 => ['RAN','LIE_LIE','POIS'],
        4 => ['RANK','LIE_LIE','POIS'],
    },
    2501 => {
        0 => ['LOK','LIE_LIE','POIS'],
        1 => ['LOKLT','LIE_LIE','POIS'],
        2 => ['LOKTS','LIE_LIE','POIS'],
        3 => ['LOKTR','LIE_LIE','POIS'],
        4 => ['LOKAK','LIE_LIE','POIS'],
    }
},
3 => {
    0 => {
        0 => ['146','',''],
    },
    3001 => {
        0 => ['IPK','ILO_ILO','KONVERSIO'],
        1 => ['IPKA','ILO_ILO','AIK'],
        2 => ['IPKK','ILO_ILO','REF','NoLoan'],
        3 => ['IPKKO','ILO_ILO','KOT','NoLoan'],
        4 => ['IPKKU','ILO_ILO','KUV'],
        5 => ['IPKL','ILO_ILO','LAP'],
        6 => ['IPKN','ILO_ILO','NUO'],
        7 => ['IPKNE','ILO_ILO','KONVERSIO'],
        8 => ['IPKOH','ILO_ILO','OHE'],
        9 => ['IPKT1','ILO_ILO','KONVERSIO'],
        10 => ['IPKT2','ILO_ILO','KONVERSIO'],
        11 => ['IPKT3','ILO_ILO','KONVERSIO'],
        12 => ['IPKV','ILO_ILO','VAR'],
        13 => ['IPKV1','ILO_ILO','KONVERSIO'],
        14 => ['IPKV2','ILO_ILO','KONVERSIO'],
        15 => ['IPKV3','ILO_ILO','KONVERSIO'],
    },
    3101 => {
        0 => ['IAU','ILO_ILOAU','KONVERSIO'],
        1 => ['IAUA','ILO_ILOAU','AIK'],
        2 => ['IAUV1','ILO_ILOAU','KONVERSIO'],
        3 => ['IAUV2','ILO_ILOAU','KONVERSIO'],
    },
    3201 => {
        0 => ['ITE','ILO_LATER','KONVERSIO'],
        1 => ['ITEA','ILO_LATER','AIK'],
        2 => ['ITEV1','ILO_LATER','KONVERSIO'],
        3 => ['ITEV2','ILO_LATER','KONVERSIO'],
    },
    3301 => {
        0 => ['ILU','ILO_LUK','KONVERSIO'],
        1 => ['ILUA','ILO_LUK','AIK'],
        2 => ['ILUN','ILO_LUK','LAP'],
        3 => ['ILUK','ILO_LUK','REF','NoLoan'],
        4 => ['ILUV1','ILO_LUK','KONVERSIO'],
        5 => ['ILUV2','ILO_LUK','KONVERSIO'],
    },
    3401 => {
        0 => ['IPA','ILO_ILO','KONVERSIO'],
        1 => ['IPAA','ILO_ILO','KONVERSIO'],
        2 => ['IPAL','ILO_ILO','KONVERSIO'],
        3 => ['IPAN','ILO_ILO','KONVERSIO'],
        4 => ['IPAK','ILO_ILO','KONVERSIO'],
        5 => ['IPAV1','ILO_ILO','KONVERSIO'],
        6 => ['IPAV2','ILO_ILO','KONVERSIO'],
    },
    3501 => {
        0 => ['IPO','ILO_ILO','KONVERSIO'],
        1 => ['IPOA','ILO_ILO','KONVERSIO'],
        2 => ['IPOL','ILO_ILO','KONVERSIO'],
        3 => ['IPON','ILO_ILO','KONVERSIO'],
        4 => ['IPOK','ILO_ILO','KONVERSIO'],
        5 => ['IPOV1','ILO_ILO','KONVERSIO'],
        6 => ['IPOV2','ILO_ILO','KONVERSIO'],
    },
    3601 => {
        0 => ['IER','ILO_ILO','KONVERSIO'],
        1 => ['IERKA','ILO_ILO','KONVERSIO'],
        2 => ['IERIP','ILO_ILO','KONVERSIO'],
        3 => ['IERV1','ILO_ILO','KONVERSIO'],
        4 => ['IERV2','ILO_ILO','KONVERSIO'],
    }
}
};


my $org_unitsJokunen = {
0 => {
     0 => {
         0 => [ 'JOKUNEN' , 'JOE_JOE' , '' ]
     }
},
1 => {
     0 => {
         0 => [ '167' , '' , '' ]  #ohita aineisto täällä ja näytä tietueen tiedot
     },
     1001 => {
         0 => [ 'PK' , 'JOE_JOE' , 'KONVERSIO' ],
         1 => [ 'PKA' , 'JOE_JOE' , 'AIK' ],
         2 => [ 'PKAV' , 'JOE_JOE' , 'VAR' ],
         3 => [ 'PKSV' , 'JOE_JOE' , 'VAR' ],
         4 => [ 'POISPKH' , 'JOE_JOE' , 'KONVERSIO' ],
         5 => [ 'POISPKH1' , 'JOE_JOE' , 'KONVERSIO' ],
         6 => [ 'PKH2' , 'JOE_JOE' , 'HEN' , 'EmplOnly'],
         7 => [ 'POISPKH4' , 'JOE_JOE' , 'KONVERSIO' ],
         8 => [ 'POISPKH8' , 'JOE_JOE' , 'KONVERSIO' ],
         9 => [ 'PKN' , 'JOE_JOE' , 'LAP' ],
         10 => [ 'PKNK' , 'JOE_JOE' , 'LAK' , 'NoLoan' ],
         11 => [ 'PKNV' , 'JOE_JOE' , 'VAR' ],
         12 => [ 'POISPKH5' , 'JOE_JOE' , 'KONVERSIO' ],
         13 => [ 'POISPKK' , 'JOE_JOE' , 'KONVERSIO' ],
         14 => [ 'POISPKKV' , 'JOE_JOE' , 'KONVERSIO' ],
         15 => [ 'POISPKL' , 'JOE_JOE' , 'KONVERSIO' ],
         16 => [ 'POISPKH7' , 'JOE_JOE' , 'KONVERSIO' ],
         17 => [ 'POISPKM' , 'JOE_JOE' , 'KONVERSIO' ],
         18 => [ 'POISPKMK' , 'JOE_JOE' , 'KONVERSIO' ],
         19 => [ 'POISPKH6' , 'JOE_JOE' , 'KONVERSIO' ],
         20 => [ 'PKSK' , 'JOE_JOE' , 'SII' ],
         21 => [ 'POISPKKO' , 'JOE_JOE' , 'KONVERSIO' ],
         22 => [ 'POISPKH3' , 'JOE_JOE' , 'KONVERSIO' ],
         23 => [ 'PKSO' , 'JOE_JOE' , 'SOR' , 'NoLoan'],
         24 => [ 'PKPIKA' , 'JOE_JOE' , 'PIK' ],
         25 => [ 'PKVARA2' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1011 => {
         0 => [ 'PKMT' , 'JOE_JOE' , 'KONVERSIO' ],
         1 => [ 'PKM' , 'JOE_JOE' , 'MUS' ],
         2 => [ 'PKMK' , 'JOE_JOE' , 'MUK' , 'NoLoan'],
         3 => [ 'PKMV1' , 'JOE_JOE' , 'KONVERSIO' ],
         4 => [ 'PKMV2' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1021 => {
         0 => [ 'PKLT' , 'JOE_JOELT' , 'LEH' ],
         1 => [ 'PKL' , 'JOE_JOELT' , 'LEH' ],
         2 => [ 'PKLV1' , 'JOE_JOELT' , 'KONVERSIO' ],
         3 => [ 'PKLV2' , 'JOE_JOELT' , 'KONVERSIO' ]
     },
     1031 => {
         0 => [ 'PKKK' , 'JOE_JOE' , 'REF' , 'NoLoan'],
         1 => [ 'PKK' , 'JOE_JOE' , 'REF' , 'NoLoan'],
         2 => [ 'PKKV' , 'JOE_JOE' , 'VAR' ],
         3 => [ 'PKKV1' , 'JOE_JOE' , 'KONVERSIO' ],
         4 => [ 'PKKV2' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1041 => {
         0 => [ 'PKOK' , 'JOE_JOE' , 'KOT' , 'NoLoan'],
         1 => [ 'PKKO' , 'JOE_JOE' , 'PKO' , 'NoLoan'],
         2 => [ 'PKOV1' , 'JOE_JOE' , 'KONVERSIO' ],
         3 => [ 'PKOV2' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1051 => {
         0 => [ 'PKAU' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1061 => {
         0 => [ 'JKOTI' , 'JOE_JOE' , 'JKOTI' ],
         1 => [ 'JOKOTI' , 'JOE_JOE' , 'JKOTI' ],
         2 => [ 'KIKOTI' , 'JOE_KII' , 'KIKOTI' ],
         3 => [ 'KOKOTI' , 'JOE_KON' , 'KOKOTI' ],
         4 => [ 'OUKOTI' , 'JOE_OKU' , 'OUKOTI' ],
         5 => [ 'POKOTI' , 'JOE_POL' , 'POKOTI' ],
         6 => [ 'PYKOTI' , 'JOE_PYH' , 'PYKOTI' ],
         7 => [ 'TUKOTI' , 'JOE_TUU' , 'TUKOTI' ],
         8 => [ 'LIKOTI' , 'JOE_LIP' , 'LIKOTI' ],
         9 => [ 'ENKOTI' , 'JOE_ENO' , 'ENKOTI' ],
         10 => [ 'KOTV1' , '' , '' ],
         11 => [ 'KOTV2' , '' , '' ],
         12 => [ 'KOTV3' , '' , '' ],
         13 => [ 'KOTV4' , '' , '' ]
     },
     1101 => {
         0 => [ 'AU' , 'JOE_JOEAU' , 'KONVERSIO' ],
         1 => [ 'AUA' , 'JOE_JOEAU' , 'AIK' ],
         2 => [ 'AUN' , 'JOE_JOEAU' , 'LAP' ],
         3 => [ 'POISAUH' , 'JOE_JOEAU' , 'KONVERSIO' ],
         4 => [ 'PSAUTO' , 'JOE_JOEAU' , 'KONVERSIO' ],
         5 => [ 'AUVARA2' , 'JOE_JOEAU' , 'KONVERSIO' ]
     },
     1201 => {
         0 => [ 'KA' , 'JOE_KAR' , 'KONVERSIO' ],
         1 => [ 'KAA' , 'JOE_KAR' , 'AIK' ],
         2 => [ 'KAN' , 'JOE_KAR' , 'LAP' ],
         3 => [ 'KAK' , 'JOE_KAR' , 'REF' , 'NoLoan'],
         4 => [ 'POISKAH' , 'JOE_KAR' , 'KONVERSIO' ],
         5 => [ 'KAVARA1' , 'JOE_KAR' , 'KONVERSIO' ],
         6 => [ 'KAVARA2' , 'JOE_KAR' , 'KONVERSIO' ]
     },
     1301 => {
         0 => [ 'NI' , 'JOE_NII' , 'KONVERSIO' ],
         1 => [ 'NIA' , 'JOE_NII' , 'AIK' ],
         2 => [ 'NIN' , 'JOE_NII' , 'LAP' ],
         3 => [ 'NIK' , 'JOE_NII' , 'REF' , 'NoLoan'],
         4 => [ 'POISNIH' , 'JOE_NII' , 'KONVERSIO' ],
         5 => [ 'NIVARA1' , 'JOE_NII' , 'KONVERSIO' ],
         6 => [ 'NIVARA2' , 'JOE_NII' , 'KONVERSIO' ]
     },
     1401 => {
         0 => [ 'RA' , 'JOE_RAN' , 'KONVERSIO' ],
         1 => [ 'RAA' , 'JOE_RAN' , 'AIK' ],
         2 => [ 'RAN' , 'JOE_RAN' , 'LAP' ],
         3 => [ 'RAK' , 'JOE_RAN' , 'REF' , 'NoLoan'],
         4 => [ 'POISRAH' , 'JOE_RAN' , 'KONVERSIO' ],
         5 => [ 'RANA' , 'JOE_RAN' , 'NUO' ],
         6 => [ 'RAVAR2' , 'JOE_RAN' , 'KONVERSIO' ]
     },
     1501 => {
         0 => [ 'LA' , '' , '' ],
         1 => [ 'LAA' , '' , '' ],
         2 => [ 'LAN' , '' , '' ],
         3 => [ 'POISLAH' , '' , '' ],
         4 => [ 'LAVAR1' , '' , '' ]
     },
     1601 => {
         0 => [ 'KL' , 'JOE_LAKO' , 'KONVERSIO' ],
         1 => [ 'KLA' , 'JOE_LAKO' , 'AIK' ],
         2 => [ 'KLVARA1' , 'JOE_LAKO' , 'KONVERSIO' ]
     },
     1701 => {
         0 => [ 'SL' , 'JOE_LASI' , 'KONVERSIO' ],
         1 => [ 'SLA' , 'JOE_LASI' , 'AIK' ],
         2 => [ 'SLVARA1' , 'JOE_LASI' , 'KONVERSIO' ]
     },
     1801 => {
         0 => [ 'ERIKOIS' , 'JOE_JOE' , 'KONVERSIO' ],
         1 => [ 'KADONNEET' , 'JOE_JOE' , 'KONVERSIO' , 'Lost' ],   #tila!   kadonnut
         2 => [ 'ILMPAL' , 'JOE_JOE' , 'KONVERSIO' , 'Claims returned' ],   #tila!  ilmoittaa palauttaneensa/lainassa
         3 => [ 'EIKIER' , 'JOE_JOE' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         4 => [ 'KIRJLAINA' , 'JOE_JOE' , 'KONVERSIO' ],
         5 => [ 'KOTIPALVE' , 'JOE_JOE' , 'KONVERSIO' ],
         6 => [ 'KORJATTAV' , 'JOE_JOE' , 'KONVERSIO' , 'Bindery' ],   #tila!   korjattavana
         8 => [ 'HENKILKU' , 'JOE_JOE' , 'HEN' , 'EmplOnly'],
         9 => [ 'SIIRTOLAI' , 'JOE_JOE' , 'KONVERSIO' ],
         10 => [ 'RKKIRLAINA' , 'JOE_JOE' , 'KONVERSIO' ],
         11 => [ 'NIKIRLAINA' , 'JOE_JOE' , 'KONVERSIO' ],
         12 => [ 'KAKIRLAINA' , 'JOE_JOE' , 'KONVERSIO' ],
         13 => [ 'LASKUT' , 'JOE_JOE' , 'KONVERSIO' , 'Billed' ],   #tila! laskutettu
         14 => [ 'ERIOS14' , 'JOE_JOE' , 'KONVERSIO' ],
         15 => [ 'ERIOS15' , 'JOE_JOE' , 'KONVERSIO' ],
         16 => [ 'ERIOS16' , 'JOE_JOE' , 'KONVERSIO' ],
         17 => [ 'ERIOS17' , 'JOE_JOE' , 'KONVERSIO' ],
         18 => [ 'ERIOS18' , 'JOE_JOE' , 'KONVERSIO' ],
         19 => [ 'ERIOS19' , 'JOE_JOE' , 'KONVERSIO' ],
         20 => [ 'ERIOS20' , 'JOE_JOE' , 'KONVERSIO' ]
     },
     1851 => {
         0 => [ 'KI' , 'JOE_KII' , 'KONVERSIO' ],
         1 => [ 'KIA' , 'JOE_KII' , 'AIK' ],
         2 => [ 'KIH' , 'JOE_KII' , 'HEN' , 'EmplOnly'],
         3 => [ 'KIK' , 'JOE_KII' , 'REF' , 'NoLoan'],
         4 => [ 'KIKO' , 'JOE_KII' , 'KOT' , 'NoLoan'],
         5 => [ 'KIN' , 'JOE_KII' , 'LAP' ],
         6 => [ 'KION' , 'JOE_KII' , 'OHE' ],
         7 => [ 'KIV' , 'JOE_KII' , 'VAR' ]
     },
     1861 => {
         0 => [ 'H' , 'JOE_HEI' , 'KONVERSIO' ],
         1 => [ 'HA' , 'JOE_HEI' , 'AIK' ],
         2 => [ 'HK' , 'JOE_HEI' , 'REF' , 'NoLoan'],
         3 => [ 'HN' , 'JOE_HEI' , 'LAP' ]
     },
     1871 => {
         0 => [ 'KIE' , 'JOE_KII' , 'KONVERSIO' ],
         1 => [ 'KIEKO' , 'JOE_KII' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'KIEKA' , 'JOE_KII' , 'KONVERSIO' , 'Lost' ],   #tila!   kadonnut
         3 => [ 'KIEIP' , 'JOE_KII' , 'KONVERSIO' , 'Claims returned' ]   #tila! ilmoittaa palauttaneensa/lainassa
     },
     1901 => {
         0 => [ 'TP' , 'JOE_TUU' , 'KONVERSIO' ],
         1 => [ 'TPA' , 'JOE_TUU' , 'AIK' ],
         2 => [ 'TPK' , 'JOE_TUU' , 'REF' , 'NoLoan'],
         3 => [ 'TPKO' , 'JOE_TUU' , 'KOT' , 'NoLoan'],
         4 => [ 'TPKU' , 'JOE_TUU' , 'LAP' ],
         5 => [ 'TPL' , 'JOE_TUU' , 'LAP' ],
         6 => [ 'TPN' , 'JOE_TUU' , 'NUO' ],
         7 => [ 'TPV' , 'JOE_TUU' , 'VAR' ]
     },
     1911 => {
         0 => [ 'TA' , 'JOE_TUU' , '' ],
         1 => [ 'TAA' , 'JOE_TUU' , '' ],
         2 => [ 'TAKU' , 'JOE_TUU' , '' ],
         3 => [ 'TAL' , 'JOE_TUU' , '' ],
         4 => [ 'TAN' , 'JOE_TUU' , '' ],
         5 => [ 'TAV' , 'JOE_TUU' , '' ]
     },
     1921 => {
         0 => [ 'TE' , 'JOE_TUU' , 'KONVERSIO' ],
         1 => [ 'TEKO' , 'JOE_TUU' , 'KONVERSIO' ],
         2 => [ 'TEIP' , 'JOE_TUU' , 'KONVERSIO' ],
         3 => [ 'TEKA' , 'JOE_TUU' , 'KONVERSIO' ]
     }
},
2 => {
     0 => {
         0 => [ '251' , '' , '' ],
     }
},
3 => {
     0 => {
         0 => [ '276' , '' , '' ],
     },
     3001 => {
         0 => [ 'KO' , 'JOE_KON' , 'KONVERSIO' ],
         1 => [ 'KOA' , 'JOE_KON' , 'AIK' ],
         2 => [ 'KOH' , 'JOE_KON' , 'HEN' , 'EmplOnly'],
         3 => [ 'KOK' , 'JOE_KON' , 'REF' , 'NoLoan'],
         4 => [ 'KOKO' , 'JOE_KON' , 'KOT' , 'NoLoan'],
         5 => [ 'KON' , 'JOE_KON' , 'LAP' ],
         6 => [ 'KOVA' , 'JOE_KON' , 'VAR' ],
         7 => [ 'KOVN' , 'JOE_KON' , 'VAR' ],
         8 => [ 'KOPIKA' , 'JOE_KON' , 'PIK' ],
     },
     3101 => {
         0 => [ 'LE' , 'JOE_LEH' , 'KONVERSIO' ],
         1 => [ 'LEA' , 'JOE_LEH' , 'AIK' ],
         2 => [ 'LEH' , 'JOE_LEH' , 'HEN' , 'EmplOnly'],
         3 => [ 'LEK' , 'JOE_LEH' , 'REF' , 'NoLoan'],
         4 => [ 'LEN' , 'JOE_LEH' , 'LAP' ],
         5 => [ 'LEVA' , 'JOE_LEH' , 'VAR' ],
         6 => [ 'LEVN' , 'JOE_LEH' , 'VAR' ],
     },
     3201 => {
         0 => [ 'AK' , 'JOE_KONAU' , 'KONVERSIO' ],
         1 => [ 'AKA' , 'JOE_KONAU' , 'AIK' ],
         2 => [ 'AKN' , 'JOE_KONAU' , 'LAP' ],
     },
     3301 => {
         0 => [ 'KOE' , 'JOE_KON' , 'KONVERSIO' ],
         1 => [ 'KOEKOR' , 'JOE_KON' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'KOEJOU' , 'JOE_KON' , 'JOU' ],
         3 => [ 'KOE2KA' , 'JOE_KON' , 'TUP' ],
         4 => [ 'KOE2KN' , 'JOE_KON' , 'TUP' ],
         5 => [ 'KOEKV' , 'JOE_KON' , 'KONVERSIO' ],
         6 => [ 'KOEN' , 'JOE_KON' , 'SHO' ],
         7 => [ 'KOEPO' , 'JOE_KON' , 'KONVERSIO' ],
         8 => [ 'KOEIP' , 'JOE_KON' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         9 => [ 'KOEKAD' , 'JOE_KON' , 'KONVERSIO' , 'Lost' ],   #tila!   kadonnut
         10 => [ 'KOEOL' , 'JOE_KON' , 'OHE' ],
         11 => [ 'KOESK1' , 'JOE_KON' , 'SII' ],
         12 => [ 'KOESK2' , 'JOE_KON' , 'SII' ],
         13 => [ 'KOESK3' , 'JOE_KON' , 'SII' ],
         14 => [ 'KOESK4' , 'JOE_KON' , 'SII' ],
         15 => [ 'KOESK5' , 'JOE_KON' , 'SII' ],
         16 => [ 'KOEOLT' , 'JOE_KON' , 'OHE' ],
         17 => [ 'KOEVARA1' , 'JOE_KON' , 'KONVERSIO' ],
         18 => [ 'KOEVARA2' , 'JOE_KON' , 'KONVERSIO' ],
     },
     3401 => {
         0 => [ 'LEE' , 'JOE_LEH' , 'KONVERSIO' ],
         1 => [ 'LEEKOR' , 'JOE_LEH' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'LEEJOU' , 'JOE_LEH' , 'JOU' ],
         3 => [ 'LEE2KA' , 'JOE_LEH' , 'TUP' ],
         4 => [ 'LEE2KN' , 'JOE_LEH' , 'TUP' ],
         5 => [ 'LEEN' , 'JOE_LEH' , 'SHO' ],
         6 => [ 'LEEPO' , 'JOE_LEH' , 'KONVERSIO' ],
         7 => [ 'LEEIP' , 'JOE_LEH' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         8 => [ 'LEEKAD' , 'JOE_LEH' , 'KONVERSIO' , 'Lost' ],   #tila!   kadonnut
     },
},
4 => {
     0 => {
         0 => [ '309' , '' , '' ],
     },
     4001 => {
         0 => [ 'O' , 'JOE_OKU' , 'KONVERSIO' ],
         1 => [ 'OA' , 'JOE_OKU' , 'AIK' ],
         2 => [ 'OH' , 'JOE_OKU' , 'HEN' , 'EmplOnly'],
         3 => [ 'OI' , 'JOE_OKU' , 'ISO' ],
         4 => [ 'OK' , 'JOE_OKU' , 'REF' , 'NoLoan'],
         5 => [ 'OKO' , 'JOE_OKU' , 'KOT' , 'NoLoan'],
         6 => [ 'OM' , 'JOE_OKU' , 'MUS' ],
         7 => [ 'OMK' , 'JOE_OKU' , 'MUK' , 'NoLoan'],
         8 => [ 'ON' , 'JOE_OKU' , 'LAP' ],
         9 => [ 'ONA' , 'JOE_OKU' , 'NUA' ],
         10 => [ 'OS' , 'JOE_OKU' , 'SII' ],
         11 => [ 'OV' , 'JOE_OKU' , 'VAR' ],
     },
     4101 => {
         0 => [ 'OE' , 'JOE_OKU' , 'KONVERSIO' ],
         1 => [ 'OES' , 'JOE_OKU' , 'KONVERSIO' ],
         2 => [ 'OEKA' , 'JOE_OKU' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         3 => [ 'OE2K' , 'JOE_OKU' , 'KONVERSIO' ],
         4 => [ 'OEN' , 'JOE_OKU' , 'KONVERSIO' ],
         5 => [ 'OEIP' , 'JOE_OKU' , 'KONVERSIO' , 'Claims returned' ],   #tila! ilmoittaa palauttaneensa/lainassa
         6 => [ 'OEKP' , 'JOE_OKU' , 'KONVERSIO' ],
         7 => [ 'OELU' , 'JOE_OKU' , 'KONVERSIO' ],
         8 => [ 'OENO' , 'JOE_OKU' , 'KONVERSIO' ],
     },
     4201 => {
         0 => [ 'AO' , 'JOE_OKU' , 'KONVERSIO' ], #oikeasti JOE_OKUAU
         1 => [ 'AOA' , 'JOE_OKU' , 'AIK' ], #oikeasti JOE_OKUAU
         2 => [ 'AON' , 'JOE_OKU' , 'LAP' ], #oikeasti JOE_OKUAU
         3 => [ 'AONA' , 'JOE_OKU' , 'NUA' ], #oikeasti JOE_OKUAU
     },
},
5 => {
     0 => {
         0 => [ '607' , '' , '' ],
     },
     5001 => {
         0 => [ 'PO' , 'JOE_POL' , 'KONVERSIO' ],
         1 => [ 'POA' , 'JOE_POL' , 'AIK' ],
         2 => [ 'POH' , 'JOE_POL' , 'HEN' , 'EmplOnly'],
         3 => [ 'POK' , 'JOE_POL' , 'REF' , 'NoLoan'],
         4 => [ 'POKO' , 'JOE_POL' , 'KOT' , 'NoLoan'],
         5 => [ 'POM' , 'JOE_POL' , 'MUS' ],
         6 => [ 'PON' , 'JOE_POL' , 'LAP' ],
         7 => [ 'POVA' , 'JOE_POL' , 'VAR' ],
         8 => [ 'POVN' , 'JOE_POL' , 'VAR' ],
     },
     5101 => {
         0 => [ 'POE' , 'JOE_POL' , 'KONVERSIO' ],
         1 => [ 'POEKOR' , 'JOE_POL' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'POEIP' , 'JOE_POL' , 'KONVERSIO' , 'Claims returned' ],   #tila! ilmoittaa palauttaneensa/lainassa
         3 => [ 'POEKAD' , 'JOE_POL' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         4 => [ 'POESK' , 'JOE_POL' , 'SII' ],
         5 => [ 'POEOL' , 'JOE_POL' , 'OHE' ],
         6 => [ 'POEJOU' , 'JOE_POL' , 'JOU' ],
         7 => [ 'POEOS7' , 'JOE_POL' , 'KONVERSIO' ],
         8 => [ 'POEOS8' , 'JOE_POL' , 'KONVERSIO' ],
     },
},
6 => {
     0 => {
         0 => [ '632' , '' , '' ],
     },
     6001 => {
         0 => [ 'PY' , 'JOE_PYH' , 'KONVERSIO' ],
         1 => [ 'PYA' , 'JOE_PYH' , 'AIK' ],
         2 => [ 'PYH' , 'JOE_PYH' , 'HEN' , 'EmplOnly'],
         3 => [ 'PYK' , 'JOE_PYH' , 'REF' , 'NoLoan'],
         4 => [ 'PYKO' , 'JOE_PYH' , 'KOT' , 'NoLoan'],
         5 => [ 'PYN' , 'JOE_PYH' , 'LAP' ],
         6 => [ 'PYNA' , 'JOE_PYH' , 'NUA' ],
         7 => [ 'PYV' , 'JOE_PYH' , 'VAR' ],
         8 => [ 'PYPIKA' , 'JOE_PYH' , 'PIK' ],
     },
     6101 => {
         0 => [ 'R' , 'JOE_REI' , 'KONVERSIO' ],
         1 => [ 'REA' , 'JOE_REI' , 'AIK' ],
         2 => [ 'RK' , 'JOE_REI' , 'REF' , 'NoLoan'],
         3 => [ 'RN' , 'JOE_REI' , 'LAP' ],
         4 => [ 'RNA' , 'JOE_REI' , 'NUA' ],
         5 => [ 'RV' , 'JOE_REI' , 'VAR' ],
         6 => [ 'RH' , 'JOE_REI' , 'HEN' , 'EmplOnly'],
         7 => [ 'REPIKA' , 'JOE_REI' , 'PIK' ],
     },
     6201 => {
         0 => [ 'PYE' , 'JOE_PYH' , 'KONVERSIO' ],
         1 => [ 'PYEKOR' , 'JOE_PYH' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'PYEKA' , 'JOE_PYH' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         3 => [ 'PYEIP' , 'JOE_PYH' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         4 => [ 'PYEKK' , 'JOE_PYH' , 'TUP' ],
         5 => [ 'PYEO9' , 'JOE_PYH' , 'KONVERSIO' ],
     },
     6301 => {
         0 => [ 'RE' , 'JOE_REI' , 'KONVERSIO' ],
         1 => [ 'REKOR' , 'JOE_REI' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'REKA' , 'JOE_REI' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         3 => [ 'REIP' , 'JOE_REI' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         4 => [ 'REKK' , 'JOE_REI' , 'TUP' ],
         5 => [ 'REO10' , 'JOE_REI' , 'KONVERSIO' ],
     },
},
7 => {
     0 => {
         0 => [ '856' , '' , '' ],
     }
},
8 => {
     0 => {
         0 => [ '176' , '' , '' ],
     },
     8001 => {
         0 => [ 'JU' , 'JOE_JUU' , 'KONVERSIO' ],
         1 => [ 'JUA' , 'JOE_JUU' , 'AIK' ],
         2 => [ 'JUH' , 'JOE_JUU' , 'HEN' , 'EmplOnly'],
         3 => [ 'JUK' , 'JOE_JUU' , 'REF' , 'NoLoan'],
         4 => [ 'JUKK' , 'JOE_JUU' , 'JKK' ],
         5 => [ 'JUKO' , 'JOE_JUU' , 'KOT' , 'NoLoan'],
         6 => [ 'JULU' , 'JOE_JUU' , 'OHE' ],
         7 => [ 'JUN' , 'JOE_JUU' , 'LAP' ],
         8 => [ 'JUOL' , 'JOE_JUU' , 'OHE' ],
         9 => [ 'JUTK' , 'JOE_JUU' , 'JTE' ],
         10 => [ 'JUV' , 'JOE_JUU' , 'VAR' ],
         11 => [ 'JUVN' , 'JOE_JUU' , 'VAR' ],
         12 => [ 'JUVV' , 'JOE_JUU' , 'VAR' ],
         13 => [ 'JUIP' , 'JOE_JUU' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         14 => [ 'JUKR' , 'JOE_JUU' , 'KONVERSIO' ],
         15 => [ 'JUKA' , 'JOE_JUU' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         16 => [ 'JUPIKA' , 'JOE_JUU' , 'PIK' ],
         17 => [ 'JUPO' , 'JOE_JUU' , 'KONVERSIO' ],
         18 => [ 'JUVARA2' , 'JOE_JUU' , 'KONVERSIO' ],
         19 => [ 'JUVARA3' , 'JOE_JUU' , 'KONVERSIO' ],
         20 => [ 'JUVARA4' , 'JOE_JUU' , 'KONVERSIO' ],
     },
     8011 => {
         0 => [ 'JUUKOT' , 'JOE_JUU' , '' ],
         1 => [ 'JUKOTI' , 'JOE_JUU' , '' ],
         2 => [ 'JKOTV1' , 'JOE_JUU' , '' ],
         3 => [ 'JKOTV2' , 'JOE_JUU' , '' ],
         4 => [ 'JKOTV3' , 'JOE_JUU' , '' ],
         5 => [ 'JKOTV4' , 'JOE_JUU' , '' ],
     },
     8101 => {
         0 => [ 'AJ' , 'JOE_JUU' , '' ],
         1 => [ 'AJA' , 'JOE_JUU' , '' ],
         2 => [ 'AJN' , 'JOE_JUU' , '' ],
         3 => [ 'AJV' , 'JOE_JUU' , '' ],
     },
},
9 => {
     0 => {
         0 => [ '426' , '' , '' ],
     },
     9001 => {
         0 => [ 'LIP' , 'JOE_LIP' , 'KONVERSIO' ],
         1 => [ 'LIPA' , 'JOE_LIP' , 'AIK' ],
         2 => [ 'LIPN' , 'JOE_LIP' , 'NUO' ],
         3 => [ 'LIPL' , 'JOE_LIP' , 'LAP' ],
         4 => [ 'LIPNA' , 'JOE_LIP' , 'NUA' ],
         5 => [ 'LIPK' , 'JOE_LIP' , 'REF' , 'NoLoan'],
         6 => [ 'LIPV' , 'JOE_LIP' , 'VAR' ],
         7 => [ 'LIPKO' , 'JOE_LIP' , 'KOT' , 'NoLoan'],
         8 => [ 'LIPOH' , 'JOE_LIP' , 'OHE' ],
         9 => [ 'LIPH' , 'JOE_LIP' , 'HEN' , 'EmplOnly'],
         10 => [ 'LIPVAR1' , 'JOE_LIP' , 'KONVERSIO' ],
         11 => [ 'LIPVAR2' , 'JOE_LIP' , 'KONVERSIO' ],
         12 => [ 'LIPVAR3' , 'JOE_LIP' , 'KONVERSIO' ],
         13 => [ 'LIPVAR4' , 'JOE_LIP' , 'KONVERSIO' ],
         14 => [ 'LIPVAR5' , 'JOE_LIP' , 'KONVERSIO' ],
     },
     9101 => {
         0 => [ 'LIV' , 'JOE_VII' , 'KONVERSIO' ],
         1 => [ 'LIVA' , 'JOE_VII' , 'AIK' ],
         2 => [ 'LIVN' , 'JOE_VII' , 'NUO' ],
         3 => [ 'LIVL' , 'JOE_VII' , 'LAP' ],
         4 => [ 'LIVNA' , 'JOE_VII' , 'NUA' ],
         5 => [ 'LIVK' , 'JOE_VII' , 'REF' , 'NoLoan'],
         6 => [ 'LIVH' , 'JOE_VII' , 'HEN' , 'EmplOnly'],
         7 => [ 'LIVEIP' , 'JOE_VII' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         8 => [ 'LIVEKAD' , 'JOE_VII' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         9 => [ 'LIVEKOR' , 'JOE_VII' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         10 => [ 'LIVEVALI' , 'JOE_VII' , 'VVA' ],
         11 => [ 'LIVVAR5' , 'JOE_VII' , 'KONVERSIO' ],
     },
     9201 => {
         0 => [ 'LIY' , 'JOE_YMY' , 'KONVERSIO' ],
         1 => [ 'LIYA' , 'JOE_YMY' , 'AIK' ],
         2 => [ 'LIYN' , 'JOE_YMY' , 'NUO' ],
         3 => [ 'LIYL' , 'JOE_YMY' , 'LAP' ],
         4 => [ 'LIYNA' , 'JOE_YMY' , 'NUA' ],
         5 => [ 'LIYK' , 'JOE_YMY' , 'REF' , 'NoLoan'],
         6 => [ 'LIYH' , 'JOE_YMY' , 'HEN' , 'EmplOnly'],
         7 => [ 'LIYEIP' , 'JOE_YMY' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         8 => [ 'LIYEKAD' , 'JOE_YMY' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         9 => [ 'LIYEKOR' , 'JOE_YMY' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         10 => [ 'LIYEVALI' , 'JOE_YMY' , 'VVA' ],
         11 => [ 'LIYVAR5' , 'JOE_YMY' , 'KONVERSIO' ],
     },
     9301 => {
         0 => [ 'LIA' , 'JOE_LIPAU' , 'KONVERSIO' ],
         1 => [ 'LIAA' , 'JOE_LIPAU' , 'AIK' ],
         2 => [ 'LIAN' , 'JOE_LIPAU' , 'NUO' ],
         3 => [ 'LIAL' , 'JOE_LIPAU' , 'LAP' ],
         4 => [ 'LIANA' , 'JOE_LIPAU' , 'NUA' ],
         5 => [ 'LIAK' , 'JOE_LIPAU' , 'REF' , 'NoLoan'],
         6 => [ 'LIAVAR1' , 'JOE_LIPAU' , 'KONVERSIO' ],
         7 => [ 'LIAVAR2' , 'JOE_LIPAU' , 'KONVERSIO' ],
         8 => [ 'LIAVAR3' , 'JOE_LIPAU' , 'KONVERSIO' ],
     },
     9401 => {
         0 => [ 'LIE' , 'JOE_LIP' , 'KONVERSIO' ],
         1 => [ 'LIEKOR' , 'JOE_LIP' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'LIEKAD' , 'JOE_LIP' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         3 => [ 'LIEVALI' , 'JOE_LIP' , 'VVA' ],
         4 => [ 'LIEIP' , 'JOE_LIP' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         5 => [ 'LIELASK' , 'JOE_LIP' , 'KONVERSIO' , 'Billed' ],  #tila! laskutettu
         6 => [ 'LIESL' , 'JOE_LIP' , 'SII' ],
         7 => [ 'LIEVIKOR' , 'JOE_VII' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         8 => [ 'LIEVIVALI' , 'JOE_VII' , 'VVA' ],
         9 => [ 'LIEYKOR' , 'JOE_YMY' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         10 => [ 'LIEYVALI' , 'JOE_YMY' , 'VVA' ],
         11 => [ 'LIEvara1' , 'JOE_LIP' , 'KONVERSIO' ],
     },
},
10 => {
     0 => {
         0 => [ '045' , '' , '' ],
     },
     10001 => {
         0 => [ 'ENO' , 'JOE_ENO' , 'KONVERSIO' ],
         1 => [ 'ENOA' , 'JOE_ENO' , 'AIK' ],
         2 => [ 'ENON' , 'JOE_ENO' , 'NUO' ],
         3 => [ 'ENOL' , 'JOE_ENO' , 'LAP' ],
         4 => [ 'ENONA' , 'JOE_ENO' , 'NUA' ],
         5 => [ 'ENOK' , 'JOE_ENO' , 'REF' , 'NoLoan'],
         6 => [ 'ENOKO' , 'JOE_ENO' , 'KOT' , 'NoLoan'],
         7 => [ 'ENOHK' , 'JOE_ENO' , 'HEN' , 'EmplOnly'],
         8 => [ 'ENONK' , 'JOE_ENO' , 'REF' , 'NoLoan'],
         9 => [ 'ENOV' , 'JOE_ENO' , 'VAR' ],
         10 => [ 'ENOOL' , 'JOE_ENO' , 'OHE' ],
         11 => [ 'ENOM' , 'JOE_ENO' , 'MUS' ],
         12 => [ 'ENOPIKA' , 'JOE_ENO' , 'PIK' ],
         13 => [ 'ENOVAR2' , 'JOE_ENO' , 'KONVERSIO' ],
         14 => [ 'ENOVAR3' , 'JOE_ENO' , 'KONVERSIO' ],
     },
     10101 => {
         0 => [ 'ENOU' , 'JOE_UIM' , 'KONVERSIO' ],
         1 => [ 'ENOUA' , 'JOE_UIM' , 'AIK' ],
         2 => [ 'ENOUN' , 'JOE_UIM' , 'NUO' ],
         3 => [ 'ENOUL' , 'JOE_UIM' , 'LAP' ],
         4 => [ 'ENOUNA' , 'JOE_UIM' , 'NUA' ],
         5 => [ 'ENOUK' , 'JOE_UIM' , 'REF' , 'NoLoan'],
         6 => [ 'ENOUKO' , 'JOE_UIM' , 'KOT' , 'NoLoan'],
         7 => [ 'ENOUHK' , 'JOE_UIM' , 'HEN' , 'EmplOnly'],
         8 => [ 'ENOUM' , 'JOE_UIM' , 'MUS' ],
         9 => [ 'ENOUVA1' , 'JOE_UIM' , 'KONVERSIO' ],
         10 => [ 'ENOUVA2' , 'JOE_UIM' , 'KONVERSIO' ],
         11 => [ 'ENOUVA3' , 'JOE_UIM' , 'KONVERSIO' ],
     },
     10201 => {
         0 => [ 'ENOAU' , 'JOE_ENO' , 'KONVERSIO' ],
         1 => [ 'ENOAUA' , 'JOE_ENO' , 'AIK' ],
         2 => [ 'ENOAUN' , 'JOE_ENO' , 'NUO' ],
         3 => [ 'ENOAUL' , 'JOE_ENO' , 'LAP' ],
         4 => [ 'ENOAUNA' , 'JOE_ENO' , 'NUA' ],
         5 => [ 'ENOAUV1' , 'JOE_ENO' , 'KONVERSIO' ],
         6 => [ 'ENOAUV2' , 'JOE_ENO' , 'KONVERSIO' ],
         7 => [ 'ENOAUV3' , 'JOE_ENO' , 'KONVERSIO' ],
     },
     10301 => {
         0 => [ 'ENOE' , 'JOE_ENO' , 'KONVERSIO' ],
         1 => [ 'ENOEKOR' , 'JOE_ENO' , 'KONVERSIO' , 'Bindery' ],  #tila!   korjattavana
         2 => [ 'ENOEKAD' , 'JOE_ENO' , 'KONVERSIO' , 'Lost' ],  #tila!   kadonnut
         3 => [ 'ENOEIP' , 'JOE_ENO' , 'KONVERSIO' , 'Claims returned' ],  #tila! ilmoittaa palauttaneensa/lainassa
         4 => [ 'ENOELV' , 'JOE_ENO' , 'VAR' ],
         5 => [ 'ENOEVA1' , 'JOE_ENO' , 'KONVERSIO' ],
         6 => [ 'ENOEVA2' , 'JOE_ENO' , 'KONVERSIO' ],
         7 => [ 'ENOEVA3' , 'JOE_ENO' , 'KONVERSIO' ],
     },
},
};

sub getWithLibid {
    my $libid = shift;
    my $org_units;
    if ($CFG::CFG->{organization} eq 'pielinen') {
        $org_units = $org_unitsPielinen;
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $org_units = $org_unitsJokunen;
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }

    my $values = $org_units->{$libid}->{0}->{0};

    return ($values->[1]) ? $values->[1] : $values->[0];
}

=head resolve

    my $licloqde = TranslationTables::liqlocde_translation::resolve(  { libid => $libid, locid => $locid, depid => $depid }  );
    my $oldLocName = $licloqde->[0];
    my $branchcode = $licloqde->[1];
    my $shelvingLocation = $licloqde->[2];
    my $itemStatus = $licloqde->[3];
    my $itemStatusSupplement = $licloqde->[4];

Get the licloqde-translation map.
@param 'libid'
@param 'locid'
@param 'depid'
@RETURNS Array of Strings: ['oldName','KohaBranchcode','shelvingLocation','itemStatus','itemStatusSupplement']
                           eg. ['NNY','NUR_NUR','VAR','PubNote','Ylävarasto']
=cut
sub resolve {
    my $libid = ($_[0]->{libid}) ? $_[0]->{libid} : undef;
    my $locid = ($_[0]->{locid}) ? $_[0]->{locid} : undef;
    my $depid = ($_[0]->{depid}) ? $_[0]->{depid} : undef;
#    my $getOldName = $_[0]->{getOldName} if $_[0]->{getOldName};
#    my $getShelvingLocationToo = $_[0]->{getShelvingLocationToo} if $_[0]->{getShelvingLocationToo};
#    my $getStatus = $_[0]->{getStatus} if $_[0]->{getStatus};

    $depid = '0' if ! defined $depid;
    $locid = '0' if ! defined $locid;

    if (! defined $libid) {
        if (length $locid == 5) {
            $libid = substr $locid,0,2;
        }
        else {
            $libid = substr $locid,0,1;
        }
    }

    my $org_units;
    if ($CFG::CFG->{organization} eq 'pielinen') {
        $org_units = $org_unitsPielinen;
    }
    elsif ($CFG::CFG->{organization} eq 'jokunen') {
        $org_units = $org_unitsJokunen;
    }
    else {
        cluck "No such organization '$CFG::CFG->{organization}' mapped!";
    }

    my $values = $org_units->{$libid}->{$locid}->{$depid};

    #in some cases $libid doesnt match the first characters of $locid, even if they should. Overwriting the locid's libid designation with the supposedly proper libid
    if (! (defined $values) && $libid) {
        $locid = $libid . substr( $locid, -3, 3 );
        $values = $org_units->{$libid}->{$locid}->{$depid};
    }

    if (! defined $values) {
        print "not defined liqlocde \$values for libid '".($libid) ? $libid : ''."', locid '".($locid) ? $locid : ''."', depid '".($depid) ? $depid : ''."'";
    }

    return $values;
#    if ($getShelvingLocationToo) {
#        return ($values->[0] && !(defined $getOldName)) ? ($values->[1],$values->[2]) : ($values->[0],$values->[2]);
#    }
#    elsif ($getStatus) {
#        return ($values->[0]) ? $values->[3] : undef;
#    }
#    else {
#        return ($values->[0] && !(defined $getOldName)) ? $values->[1] : $values->[0];
#    }
}
