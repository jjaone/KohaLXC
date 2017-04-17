package MMT::Biblios::MaterialTypeRepair;

use Modern::Perl;
use utf8;
use Switch;
use Try::Tiny;

use MMT::Util::Common;

my $statistics;

#EGDATA-116
## Initializing anonymous sanitation functions
my $leader;
my $f008;
my $r;

sub al {
	$leader = MMT::Util::Common::characterReplace($leader,6,'a');
	$leader = MMT::Util::Common::characterReplace($leader,7,'s');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'p');
};

sub br {
	$leader = MMT::Util::Common::characterReplace($leader,6,'g');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'x');
	$f008 = MMT::Util::Common::characterReplace($f008,26,'m');
};

sub cd {
	$f008 = MMT::Util::Common::characterReplace($f008,23,'r');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = MMT::Util::Common::characterReplace($leader,6,'j');
	}
	else {
		$leader = MMT::Util::Common::characterReplace($leader,6,'i');
	}
};

sub cr {
	$leader = MMT::Util::Common::characterReplace($leader,6,'l');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
};

sub di {
	$leader = MMT::Util::Common::characterReplace($leader,6,'g');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'a');
};

sub dv {
	$leader = MMT::Util::Common::characterReplace($leader,6,'g');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'z'); #Replaced with 'm' in USEMARCON after having signalled that this is a DVD
	$f008 = MMT::Util::Common::characterReplace($f008,26,'m');
};

sub dr {
	$leader = MMT::Util::Common::characterReplace($leader,6,'l');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
};

sub es {
	$leader = MMT::Util::Common::characterReplace($leader,6,'r');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'p');
};

sub ka {
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = MMT::Util::Common::characterReplace($leader,6,'j');
		$leader = MMT::Util::Common::characterReplace($leader,7,'a');
	}
	else {
		$leader = MMT::Util::Common::characterReplace($leader,6,'i');
		$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	}
};

sub kr {
	$leader = MMT::Util::Common::characterReplace($leader,6,'e');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
};

sub ki {
	$leader = MMT::Util::Common::characterReplace($leader,6,'a');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
};
sub ko {
	$leader = MMT::Util::Common::characterReplace($leader,6,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'y');
};

sub kp {
	$leader = MMT::Util::Common::characterReplace($leader,6,'l');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'g');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
};

sub ku {
	$leader = MMT::Util::Common::characterReplace($leader,6,'k');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'g');
};

sub ll {
	print("Lehtileike docid ".$r->docId()." not in use!\n");
};

sub mf {
	$leader = MMT::Util::Common::characterReplace($leader,6,'h');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'c');
};

sub mk {
	$leader = MMT::Util::Common::characterReplace($leader,6,'h');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'d');
};

sub mp {
	$leader = MMT::Util::Common::characterReplace($leader,6,'l');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'h');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'s');
};

sub mm {
	print("Muu mikrotallenne docid ".$r->docId()." not in use!\n");
};

sub mo {
	print("Moniviestin docid ".$r->docId()." not in use!\n");
};

sub nu {
	$leader = MMT::Util::Common::characterReplace($leader,6,'c');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'m');
};

sub nä {
	#print("Nuotti+Äänite docid ".$r->docId()." not in use!\n");
};

sub pa {
	$leader = MMT::Util::Common::characterReplace($leader,6,'c');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'a');
};

sub sk {
	$leader = MMT::Util::Common::characterReplace($leader,6,'a');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'f');
};

sub sl {
	$leader = MMT::Util::Common::characterReplace($leader,6,'a');
	$leader = MMT::Util::Common::characterReplace($leader,7,'s');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'n');
};

sub ty {
	$leader = MMT::Util::Common::characterReplace($leader,6,'k');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'j');
};

sub va {
	$leader = MMT::Util::Common::characterReplace($leader,6,'l');
	$f008 = MMT::Util::Common::characterReplace($f008,21,'j');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'i');
};

sub vi {
	$leader = MMT::Util::Common::characterReplace($leader,6,'g');
	$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	$f008 = MMT::Util::Common::characterReplace($f008,23,'n');
	$f008 = MMT::Util::Common::characterReplace($f008,26,'a');
};

sub le {
	$f008 = MMT::Util::Common::characterReplace($f008,23,'q');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = MMT::Util::Common::characterReplace($leader,6,'j');
		$leader = MMT::Util::Common::characterReplace($leader,7,'a');
	}
	else {
		$leader = MMT::Util::Common::characterReplace($leader,6,'i');
		$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	}
};

sub än {
	$f008 = MMT::Util::Common::characterReplace($f008,23,'o');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = MMT::Util::Common::characterReplace($leader,6,'j');
		$leader = MMT::Util::Common::characterReplace($leader,7,'a');
	}
	else {
		$leader = MMT::Util::Common::characterReplace($leader,6,'i');
		$leader = MMT::Util::Common::characterReplace($leader,7,'m');
	}
};

sub ät {
	#print("Ääni+Teksti docid ".$r->docId()." not in use!\n");
};


sub forceProperFinMARCStructureFromPPMaterialType($$) {
	$r = shift;
    $statistics = shift;
	
	if ($r->isComponentPart()) {
		return;
	}
	
	sub throwError($) {
		print('Couldn\'t force proper FinMARC leader codes for docid '.shift->docid().' based on PP material type. Leader is malformed.');
	}
	sub updateStatistics() {
		$statistics->{'forceProperFinMARCStructureFromPPMaterialType'}++;
	}
	
	my $materialType = $r->materialType();
	$leader = $r->leader();
    my $field008 = $r->getUnrepeatableSubfield('008','a');
	if (!(defined $leader) || !(defined $materialType) || !(defined $field008) ) {
		print("Docid ".$r->docId()." has no leader or materialType or field008");
		return;
	}
	$f008 = $field008->content();
	
	try {
		
		switch(  $materialType  ) {
			case 'al' {	al() }
			case 'at' {}
			case 'br' { br() }
			case 'cd' { cd() }
			case 'cr' { cr() }
			case 'di' { di() }
			case 'dr' { dr() }
			case 'dv' { dv() }
			case 'el' {}
			case 'es' { es() }
			case 'ka' { ka() }
			case 'kr' { kr() }
			case 'ki' { ki() }
			case 'ko' { ko() }
			case 'kp' { kp() }
			case 'ku' { ku() }
			case 'k|' {}
			case 'll' {}
			case 'mf' { mf() }
			case 'mk' { mk() }
			case 'mo' {}
			case 'mp' { mp() }
			case 'mm' { mm() }
			case 'nu' { nu() }
			case 'n|' { nä() }
			case 'sl' { sl() }
			case 'sk' { sk() }
			case 'ty' { ty() }
			case 'va' { va() }
			case 'vi' { vi() }
			case '|t' { ät() }
			case '|k' { ka() }
			case 'le' {}
			case '|n' { än() }
			case 'CA' { mp() } #Celia audiobooks material type override check
			case 'KP' { kp() } #Console games material type override check
			else {}
		}
		
		$r->leader( $leader );
		$field008->content( $f008 );
	}
	catch {
		print $_ . "Bad materialType:".$materialType;
	}
	
}

1;
