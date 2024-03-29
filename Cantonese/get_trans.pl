#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $PDIR, %W, %USED, %F, %INFO);
#$PDIR = ".";
$PDIR = "/usr/local/bin/";

require "$PDIR/utils.pl";
require "./rest2.pl";

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
	#	unless (m|<entry|){print $_; next line;}
	# my $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# my $tagname = restructure::get_tagname($bit);    
	my $e_eid = restructure::get_tag_attval($_, "entryGroup", "lexid");
	my $hw = restructure::get_tag_contents($_, "headword");
	my $_ = restructure::del_sup($_);
	my $e_info = &get_e_info($_);
	printf("%s\t%s\t%s\n", $hw, $e_info, $e_eid);
	$_ =~ s|(<exampleUnit[ >].*?</exampleUnit>)|&split;&fk;$1&split;|gi;
	my @BITS = split(/&split;/, $_);
	my $res = "";
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $eid = restructure::get_tag_attval($bit, "exampleUnit", "lexid"); 
		my $x = restructure::get_tag_contents($bit, "example");
		my $tx = restructure::get_tag_contents($bit, "translation"); 
		printf("%s\t%s\t%s\n", $x, $tx, $eid);
	    }
	    $res .= $bit;
	}
	
	#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub get_e_info
{
    my($e) = @_;
    my($res, $eid);	
    $e = restructure::tag_delete($e, "pronunciations");
    $e = restructure::tag_delete($e, "xrefs");
    $e = restructure::tag_delete($e, "examples");
    $e = restructure::tag_delete($e, "note"); 
    $e = &fmt_dict_xml($e);
    return $e;
}

sub fmt_dict_xml
{
    my($e) = @_;
    my($res, $eid);	
    my @TAGS = ("sense", "entry", "posUnit", "note", "exampleUnit", "s1", "s2", "s3", "gramb", "semb", "exg", "idmb", "pvg", "trg", "xrefs");
    $e =~ s|£|&\#x00A3;|g;
    foreach my $tag (@TAGS)
    {
	$e =~ s|(<$tag[ >])|£\1|gi;
    }
    $e =~ s|<.*?>| |gi;
    $e =~ s| +| |g;
    $e =~ s|£+|£|g;
    $e =~ s|[ £]*£[ £]*|£|g;
    $e =~ s|^£||g;
    $e =~ s|£|&nl;|g;
    $e =~ s|&\#x00A3;|£|g;
    return $e;

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
    }
    close(in_fp);
} 
