package BibliosImportChain::MarcRepair::MaterialTypeRepair;

use strict;
use warnings;
use utf8;
use Switch;
use Try::Tiny;

use CommonRoutines;

my $log;
my $statistics;

#EGDATA-116
## Initializing anonymous sanitation functions
my $leader;
my $f008;
my $r;

sub al {
	$leader = CommonRoutines::characterReplace($leader,6,'a');
	$leader = CommonRoutines::characterReplace($leader,7,'s');
	$f008 = CommonRoutines::characterReplace($f008,21,'p');
};

sub br {
	$leader = CommonRoutines::characterReplace($leader,6,'g');
	$f008 = CommonRoutines::characterReplace($f008,23,'x');
	$f008 = CommonRoutines::characterReplace($f008,26,'m');
};

sub cd {
	$f008 = CommonRoutines::characterReplace($f008,23,'r');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = CommonRoutines::characterReplace($leader,6,'j');
	}
	else {
		$leader = CommonRoutines::characterReplace($leader,6,'i');
	}
};

sub cr {
	$leader = CommonRoutines::characterReplace($leader,6,'l');
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
};

sub di {
	$leader = CommonRoutines::characterReplace($leader,6,'g');
	$f008 = CommonRoutines::characterReplace($f008,23,'a');
};

sub dv {
	$leader = CommonRoutines::characterReplace($leader,6,'g');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
	$f008 = CommonRoutines::characterReplace($f008,23,'z'); #Replaced with 'm' in USEMARCON after having signalled that this is a DVD
	$f008 = CommonRoutines::characterReplace($f008,26,'m');
};

sub dr {
	$leader = CommonRoutines::characterReplace($leader,6,'l');
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
};

sub es {
	$leader = CommonRoutines::characterReplace($leader,6,'r');
	$f008 = CommonRoutines::characterReplace($f008,23,'p');
};

sub ka {
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = CommonRoutines::characterReplace($leader,6,'j');
		$leader = CommonRoutines::characterReplace($leader,7,'a');
	}
	else {
		$leader = CommonRoutines::characterReplace($leader,6,'i');
		$leader = CommonRoutines::characterReplace($leader,7,'m');
	}
};

sub kr {
	$leader = CommonRoutines::characterReplace($leader,6,'e');
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
};

sub ki {
	$leader = CommonRoutines::characterReplace($leader,6,'a');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
};
sub ko {
	$leader = CommonRoutines::characterReplace($leader,6,'m');
	$f008 = CommonRoutines::characterReplace($f008,23,'y');
};

sub kp {
	$leader = CommonRoutines::characterReplace($leader,6,'l');
	$f008 = CommonRoutines::characterReplace($f008,21,'g');
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
};

sub ku {
	$leader = CommonRoutines::characterReplace($leader,6,'k');
	$f008 = CommonRoutines::characterReplace($f008,23,'g');
};

sub ll {
	$log->warning("Lehtileike docid ".$r->docId()." not in use!\n");
};

sub mf {
	$leader = CommonRoutines::characterReplace($leader,6,'h');
	$f008 = CommonRoutines::characterReplace($f008,23,'c');
};

sub mk {
	$leader = CommonRoutines::characterReplace($leader,6,'h');
	$f008 = CommonRoutines::characterReplace($f008,23,'d');
};

sub mp {
	$leader = CommonRoutines::characterReplace($leader,6,'l');
	$f008 = CommonRoutines::characterReplace($f008,21,'h');
	$f008 = CommonRoutines::characterReplace($f008,23,'s');
};

sub mm {
	$log->warning("Muu mikrotallenne docid ".$r->docId()." not in use!\n");
};

sub mo {
	$log->warning("Moniviestin docid ".$r->docId()." not in use!\n");
};

sub nu {
	$leader = CommonRoutines::characterReplace($leader,6,'c');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
	$f008 = CommonRoutines::characterReplace($f008,21,'m');
};

sub nä {
	#$log->warning("Nuotti+Äänite docid ".$r->docId()." not in use!\n");
};

sub pa {
	$leader = CommonRoutines::characterReplace($leader,6,'c');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
	$f008 = CommonRoutines::characterReplace($f008,21,'a');
};

sub sk {
	$leader = CommonRoutines::characterReplace($leader,6,'a');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
	$f008 = CommonRoutines::characterReplace($f008,23,'f');
};

sub sl {
	$leader = CommonRoutines::characterReplace($leader,6,'a');
	$leader = CommonRoutines::characterReplace($leader,7,'s');
	$f008 = CommonRoutines::characterReplace($f008,21,'n');
};

sub ty {
	$leader = CommonRoutines::characterReplace($leader,6,'k');
	$f008 = CommonRoutines::characterReplace($f008,23,'j');
};

sub va {
	$leader = CommonRoutines::characterReplace($leader,6,'l');
	$f008 = CommonRoutines::characterReplace($f008,21,'j');
	$f008 = CommonRoutines::characterReplace($f008,23,'i');
};

sub vi {
	$leader = CommonRoutines::characterReplace($leader,6,'g');
	$leader = CommonRoutines::characterReplace($leader,7,'m');
	$f008 = CommonRoutines::characterReplace($f008,23,'n');
	$f008 = CommonRoutines::characterReplace($f008,26,'a');
};

sub le {
	$f008 = CommonRoutines::characterReplace($f008,23,'q');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = CommonRoutines::characterReplace($leader,6,'j');
		$leader = CommonRoutines::characterReplace($leader,7,'a');
	}
	else {
		$leader = CommonRoutines::characterReplace($leader,6,'i');
		$leader = CommonRoutines::characterReplace($leader,7,'m');
	}
};

sub än {
	$f008 = CommonRoutines::characterReplace($f008,23,'o');
	#Musical recording or speech!
	if (  $r->getCallNumberClass() =~ /78/  ) {
		$leader = CommonRoutines::characterReplace($leader,6,'j');
		$leader = CommonRoutines::characterReplace($leader,7,'a');
	}
	else {
		$leader = CommonRoutines::characterReplace($leader,6,'i');
		$leader = CommonRoutines::characterReplace($leader,7,'m');
	}
};

sub ät {
	#$log->warning("Ääni+Teksti docid ".$r->docId()." not in use!\n");
};


sub forceProperFinMARCStructureFromPPMaterialType($$$) {
	$r = shift;
    $log = shift;
    $statistics = shift;
	
	if ($r->isComponentPart()) {
		return;
	}
	
	sub throwError($) {
		$log->warning('Couldn\'t force proper FinMARC leader codes for docid '.shift->docid().' based on PP material type. Leader is malformed.');
	}
	sub updateStatistics() {
		$statistics->{'forceProperFinMARCStructureFromPPMaterialType'}++;
	}
	
	my $materialType = $r->materialType();
	$leader = $r->leader();
    my $field008 = $r->getUnrepeatableSubfield('008','a');
	if (!(defined $leader) || !(defined $materialType) || !(defined $field008) ) {
		$log->warning("Docid ".$r->docId()." has no leader or materialType or field008");
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
=head
	
	sub leader6Rewriter($$$) {
		my $r = shift;
		my $allowedCharacters = shift;
		my $replacement = shift;
		
		if ($r->leader() =~ /^.{6}[$allowedCharacters].*$/) {}
		else {
			if ($r->leader() =~ /^(.{6})(.)(.*)$/) {
				$r->leader($1.$replacement.$3);
				updateStatistics();
			}
			else {  throwError($r)  }
		}
	}
	# 008 (CR) CONTINUING RESOURCES = JATKUVAT JULKAISUT
	#if (@000/7-8/ = 'ab' Or @000/7-8/ = 'as')
	sub toCR($) {
		my $r = shift;
		
		if ($r->leader() =~ /^.{6}a[bs].*$/) {}
		else {
			if ($r->leader() =~ /^(.{6})(..)(.*)$/) {
				$r->leader($1.'as'.$3);
				updateStatistics();
			}
			else {  throwError($r)  }
		}
	}
	# 008 (VM) VISUAL MATERIALS = VISUAALINEN AINEISTO
	#if (@000/7/ = 'g' Or @000/7/ = 'k' Or @000/7/ = 'r')
	sub toVM($$) {
		leader6Rewriter(shift,'gkr',shift)
	}
	# 008 (MU) MUSIC = MUSIIKKI
	#if (@000/7/ = 'c' Or @000/7/ = 'd' Or @000/7/ = 'i' Or @000/7/ = 'j')
	sub toMU {
		my $r = shift;
		my $replacement = shift;
		
		if (defined $replacement && $replacement eq 'c') {
			leader6Rewriter($r,'c',$replacement);
		}
		elsif ($r->leader() =~ /^.{6}[cdij].*$/) {}
		else {
			if ($r->leader() =~ /^(.{6})(.)(.*)$/) {
				my $beginning = $1;
				my $end = $3;
				
				#Musical recording!
				if (  $r->getCallNumberClass() =~ /78/  ) {
					$r->leader($beginning.'j'.$end);
				}
				else {
					$r->leader($beginning.'i'.$end);
				}
				updateStatistics();
			}
			else {  throwError($r)  }
		}
	}
	# 008 (CF) COMPUTER FILES = ELEKTRONINEN AINEISTO
	#if (@000/7/ = 'l' And (@000/8/ = 'a' Or @000/8/ = 'm') And @008/22/ = 'd')
	sub toCF($$) {
		leader6Rewriter(shift,'lamd',shift);
	}
	# 008 (MP) MAPS = KARTAT
	#if (@000/7/ = 'e' Or @000/7/ = 'f')
	sub toMP($$) {
		leader6Rewriter(shift,'ef',shift);
	}
	# 008 (BK) BOOKS = KIRJAT
	#if (InTable(@000/7-8/, '000-06-07.tbl'))
	sub toBK($$) {
		leader6Rewriter(shift,'at',shift);
	}

	my $materialType = $r->materialType();
	if (! defined $materialType) {
		$log->warning('Record docid '.$r->docId().' has no PP material type!');
		return;
	}
		
	switch(  $materialType  ) {
		
		case 'al' {	toCR($r) }
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
		case 'n|' { n|() }
		case 'sl' { sl() }
		case 'sk' { sk() }
		case 'ty' { ty() }
		case 'va' { va() }
		case 'vi' { vi() }
		case '|t' { |t() }
		case '|k' {}
		case 'le' {}
		case '|n' { |n() }
		else {}
	}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    my $leader = $r->leader();
    my $f007 = $r->getUnrepeatableSubfield('007','a');
    my $f008 = $r->getUnrepeatableSubfield('008','a');
    
    switch(  $materialType  ) {
		
		case 'al' {	toCR($r) }
		case 'at' {}
		case 'br' { toVM($r,'g')
                    $f007 = enforceCharacterPresence($f007, 4, 's'); }
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
		case 'n|' { n|() }
		case 'sl' { sl() }
		case 'sk' { sk() }
		case 'ty' { ty() }
		case 'va' { va() }
		case 'vi' { vi() }
		case '|t' { |t() }
		case '|k' {}
		case 'le' {}
		case '|n' { |n() }
		else {}
	}
    
    #@param1 String
    #@param2 Location from 0
    #@param3 String of valid characters
    #@param4 Replacement
    
    sub enforceCharacterPresence($$$$) {
        if (! ($_[0] =~ m/^(?<=.{$_[1]})[$_[2]]/)) {
            
            if (undef $_[3]) {
                $_[3] = $_[2];
            }
            
            
            return CommonRoutines::characterReplace( $_[0], $_[1], $_[3] );
        }
        else {
            return $_[0];
        }
    }

}
=cut

1;