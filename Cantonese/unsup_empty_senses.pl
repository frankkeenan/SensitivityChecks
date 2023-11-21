#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_d, $opt_D, $opt_I, $opt_O, $PDIR, %W, %USED, %F, %INFO);
#$PDIR = ".";
$PDIR = "/usr/local/bin/";

require "$PDIR/utils.pl";
require "$PDIR/restructure.pl";

# require "/data_new/VocabHub/progs/VocabHub.pm";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$LOAD = 1;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IOD');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    if ($LOAD){&load_file($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}	
	# s|<!--.*?-->||gio;
	#	next line if (m|<entry[^>]*sup=\"y|io);
	unless (m|<entry|){print $_; next line;}
	# my $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# my $tagname = restructure::get_tagname($bit);    
	$_ = &unsup_senses($_);
	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub unsup_senses
{
    my($e) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<sense[ >].*?</sense>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $note = sprintf("<?dps_comment content=\"%s\" status=\"Imported\" topic=\"FK: Empty sense\"?>"); 
	    my $eid = restructure::get_tag_attval($bit, "sense", "e:id");
	    if ($W{$eid})
	    {
		$bit =~ s| suppressed=\"true\"||gi;
		$bit =~ s|>|>$note|;
	    }
	}
	$res .= $bit;
    }    
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
	# $INFO{$eid} = $info;
	$W{$_} = 1;
    }
    close(in_fp);
} 
