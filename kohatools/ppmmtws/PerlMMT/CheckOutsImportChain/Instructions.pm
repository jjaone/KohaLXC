package CheckOutsImportChain::Instructions;

use utf8;

#this Evergreen -table uses no NULL-values, so remember to set empty values as ''

sub getInstructions {
    return {
    'lilloan.kir' => [
        ['borrowernumber' , [1] ], #lncustid
        ['itemnumber' , [0] ], #lncopyid
        ['date_due' , [5] ], #lnduedate
        ['branchcode' , [2,3] ], #lnlocid, lndepid
        ['status', [6,7]], #lnstatus1, lnstatus2
        #['issuingbranch' , [] ],
        #['returndate' , [] ],
        #['lastreneweddate' , [] ],
        #['return' , [] ],
        ['renewals' , [6] ], #lnstatus1
        #['timestamp' , [] ], #defaults to NOW()
        ['issuedate' , [4] ], #lnloandate
    ]
    };
}

"try mixing Perl with threads! yay!";
=action.circulation
       Column        |           Type           |                            Modifiers                             
---------------------+--------------------------+------------------------------------------------------------------
 id                  | bigint                   | not null default nextval('money.billable_xact_id_seq'::regclass)
 usr                 | integer                  | not null      USE lncustid
 xact_start          | timestamp with time zone | not null default now()
 xact_finish         | timestamp with time zone |               USE ''
 unrecovered         | boolean                  |               USE ''
 target_copy         | bigint                   | not null      USE lncopyid
 circ_lib            | integer                  | not null      USE lnlocid + lndepid
 circ_staff          | integer                  | not null      USE 1 = egadmin
 checkin_staff       | integer                  |               USE ''
 checkin_lib         | integer                  |               USE ''
 renewal_remaining   | integer                  | not null      USE max_renewals - (status1-1) if status1 < 100
 grace_period        | interval                 | not null      USE '0'
 due_date            | timestamp with time zone |               USE lnduedate
 stop_fines_time     | timestamp with time zone |               USE ''
 checkin_time        | timestamp with time zone |               USE ''
 create_time         | timestamp with time zone | not null default now()    USE lnloandate
 duration            | interval                 |               USE lnduedate - lnloandate
 fine_interval       | interval                 | not null default '1 day'::interval
 recurring_fine      | numeric(6,2)             |               USE 0.20€ if pikalaina 0.50€
 max_fine            | numeric(6,2)             |               USE 5.00€
 phone_renewal       | boolean                  | not null default false
 desk_renewal        | boolean                  | not null default false
 opac_renewal        | boolean                  | not null default false
 duration_rule       | text                     | not null      USE 'Migrated from PP' if pikalaina 'Pikalaina migrated from PP'
 recurring_fine_rule | text                     | not null      USE 'Migrated from PP' if pikalaina 'Pikalaina migrated from PP'
 max_fine_rule       | text                     | not null      USE 'Migrated from PP'
 stop_fines          | text                     |               USE ''
 workstation         | integer                  |               USE 1
 checkin_workstation | integer                  |               USE ''
 copy_location       | integer                  | not null default 1
 
 asset.copy
 status = 1 if checked out
=cut


=Rummukainen kirsti kalstilantie 9006000 lainat (aika paljon)

copyid      status1      status2
90054456    00000001 1   00001010 10    ok
10310680    00000001 1   00001010 10    ok
90041285    00000001 1   00001010 10    ok
10477596    00000011 3   00001010 10    2 uusintaa
10457183    00000001 1   00001010 10    ok
10463716    00000011 3   00001010 10    2 uusintaa
10457233    00000001 1   00001010 10    varauksia?
-1136609    00001011 11  00001010 10    10 uusintaa


asset.opac_visible_copies? remove checked out copy lncopyid

=cut
