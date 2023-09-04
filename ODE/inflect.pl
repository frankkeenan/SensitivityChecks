#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $opt_D, $opt_d, %W, %F);
if (1)
{
    require "/NEWdata/dicts/generic/progs/utils.pl";
    require "/NEWdata/dicts/generic/progs/restructure.pl";
}
else {
    require "./utils.pl";
    require "./restructure.pl";
}
# require "/data_new/VocabHub/progs/VocabHub.pm";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IODd');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
#   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    binmode DB::OUT,":utf8" if ($opt_D);
    my %STORE;
    if ($LOAD){&load_file($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# s|<!--.*?-->||gio;
#	unless (m|<e |){print $_; next line;}
	# my $eid = &get_tag_attval($_, "e", "e:id");
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	my %USED;
	undef %USED;
	my $hw = restructure::get_tag_contents($_, "hw");
	s|(</FORMS>)|<infl>$hw</infl>$1|;
	my $forms = restructure::get_tag_contents($_, "FORMS");
	$_ = restructure::tag_delete($_, "FORMS"); 
	my $cp = $_;
	$forms =~ s|(<infl[ >].*?</infl>)|&split;&fk;$1&split;|gi;
	@BITS = split(/&split;/, $forms);
	$res = "";
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $infl = restructure::get_tag_contents($bit, "infl");
		unless ($USED{$infl}++)
		{
		    $_ = $cp;
		    $_ =~ s|<e *>|<e><wd>$infl</wd>|;
		    $STORE{$infl} .= $_; 
		}
	    }
	}
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    foreach my $wd (sort keys %STORE)
    {
	my $e = $STORE{$wd};
	if ($e =~ m|</e>.*</e>|)
	{
	    $e = &merge($e, "SENS-G");
	    $e = &merge($e, "DEF");
	    $e =~ s|</SENS-G> *<SENS-G *>||gi;
	    $e =~ s|</DEF> *<DEF *>|; |gi;
	    $e =~ s|</e>.*$|</e>|;
	}
	print $e;
    }
    &close_debug_files;
}


sub merge{
    my($e, $tag) = @_;
    my($res, $eid);	
    my($res2, $res);
    my(@BITS);
    
    $e =~ s|(<$tag[ >].*?</$tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $res2 .= $bit;
	    $bit = ""
	}
	$res .= $bit;
    }    
    $res =~ s|</e>|$res2</e>|;
    return $res;
}


sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
#    printf(STDERR "\t-x:\t\n"); 
    exit;
}


sub load_file
{
    my($f) = @_;
    my ($res, $bit, $info);
    my @BITS;
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
    while (<in_fp>){
	chomp;
	s|||g;
	# my ($eid, $info) = split(/\t/);
	# $W{$_} = 1;
    }
    close(in_fp);
} 
