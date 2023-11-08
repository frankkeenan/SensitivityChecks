#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $PDIR, %W, %USED, %F, %INFO, %TS);
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
    my $hdr = 1;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# s|<!--.*?-->||gio;
#	next line if (m|<entry[^>]*sup=\"y|io);
#	unless (m|<entry|){print $_; next line;}
	# $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);
	my @FLDS = split(/\t/, $_);
	#my @line = qw( foo bar baz etc etc etc );
	#splice @line, 1, 0, '';  # Insert at position 1, replace 0 elements.
	# 0  'Word'
#	1  'HW'
#	2  'Context'
#	3  'More Context'
#	4  'tag'
#	5  'Derogatory, Offensive or Vulgar'
#	6  'Derogatory'
#	7  'Offensive'
#	8  'Vulgar'
#	9  'Sensitivity classes'
#	10  'def'
#	11  'lexid'
#	12  'EntryId'
#	13  'e:id'
#	14  'dbid'
#	15  'word score'
#	16  'total score'
#	17  'Times seen'

#	my($wd, $cp, $h, $h_trans, $tag, $more_context, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens) = split(/\t/);
	my $wd = $FLDS[2];
	my $id = $FLDS[11];
	my $tag = $FLDS[4];
	$wd =~ s|<.*?>||gi;
	if ($tag =~ m|headword|)
	{
	    $id =~ s|\..*$||;		 
	}
	my $wd_id = sprintf("%s\t%s", $wd, $id); 
	my $trans = $TS{$wd_id};
	$trans =~ s|[; ]*$||;
#	unless ($trans =~ m|^ *$|)
#	{
#	    $trans = sprintf("[[%s]]", $trans); 
#	}
	if ($hdr)
	{
	    $hdr = 0;
	    splice @FLDS, 3, 0, 'Context Trans';  # Insert at position 3, replace 0 elements.

	} else{
	    splice @FLDS, 3, 0, $trans;  # Insert at position 3, replace 0 elements.
	}
	my $e = join("\t", @FLDS);
	print $e;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
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
	my($wd, $eng, $id) = split(/\t/);
	my $wd_id = sprintf("%s\t%s", $wd, $id); 
	$TS{$wd_id} = $eng;
    }
    close(in_fp);
} 
