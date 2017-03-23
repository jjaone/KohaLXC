package PreProcess::LoadExternalRepositories;

use strict;
use warnings;
use utf8;

use LiteLogger;
use Ontologiat::Asiasanat;

sub load {
    my $print = LiteLogger->new({package => 'PreProcess::LoadExternalRepositories'});
        
    if ($CFG::CFG->{LoadExternalRepositories} == 1) {
    
        $print->info('Loading external repositories');
    
        $print->info('Loading Kauno, Musa, Ysa');
        my $onki = Ontologiat::Asiasanat->init($CFG::CFG->{sourceDataDirectory});
        $onki->download_default_files();
        
    }
}

#Aiming to please... the compiler.
return 'Jippikayee! MF!';