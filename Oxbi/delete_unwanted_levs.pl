#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, %W);
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
	#	unless (m|<entry|){print $_; next line;}
	# $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	unless ((m|<e |) || (m|<cn |))
	{
	    print $_;
	    next line;
	}
	$_ = &delete_unwanted_levs($_);
	$_ = restructure::tag_delete($_, "nlp");
	#	$_ = restructure::tag_delete($_, "xrg");
	$_ = restructure::tag_delete($_, "pr");
	$_ = restructure::tag_delete($_, "infg");
	$_ = restructure::tag_delete($_, "gr");
	$_ = &add_sense_numbers($_);
#	s| *<ind[^>]*>(.*?)</ind> *| (\1) |gi;
	s| e:[^ =]*=\".*?\"||gi;
	if (m|<lev|)
	{
	    if (m|<rf|)
	    {
		$_ = &replace_rfs($_);
	    }
	    if (m| suppressed=\"true\"|)
	    {
		$_ = &lose_suppressed($_);
	    }
	    print $_;
	}
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub lose_suppressed
{
    my($e) = @_;
    my($res, $eid);	
    while ($e =~ m|(<[^>]* suppressed=\"true\".*?>)|)
    {
	my $tagname = restructure::get_tagname($1);
	$e = &del_sup_tag($e, $tagname);
    }
    return $e;
}

sub del_sup_tag
{
    my($e, $tagname) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$tagname[ >].*?</$tagname>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $sup = restructure::get_tag_attval($bit, $tagname, "suppressed");
	    if ($sup =~ m|true|i)
	    {
		$bit = "";
	    }
	}
	$res .= $bit;
    }    
    return $res;
}



sub replace_rfs
{
    my($e) = @_;
    my($res, $eid);	
    my $hw = restructure::get_tag_contents($e, "hw");
    $e =~ s|(<rf)([^a-z])|\1 \2|g;
    $e =~ s|<rf [^/]*/>|<rf ></rf>|gi;
    $e =~ s|<rf [^>]*> *</rf>|$hw|g;
    return $e;
}

sub add_sense_numbers
{
    my($e) = @_;
    my($res, $eid);	
    my @GTAGS = ("gramb");
    foreach my $gtag (@GTAGS)
    {
	$e = &add_sngs($e, $gtag);
    }
    return $e;
}

sub add_sngs
{
    my($e, $gtag) = @_;
    my($res, $eid);	
    $e =~ s|(<$gtag[ >].*?</$gtag>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = &add_semb_numbers($bit);
	}
	$res .= $bit;
    }    
    return $res;
}

sub add_semb_numbers
{
    my($e) = @_;
    my($res, $eid);
    my $ct;
    return $e unless ($e =~ m|</semb>.*</semb>|);
    $e =~ s|(<semb[ >].*?</semb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::set_tag_attval($bit, "semb", "ngnum", ++$ct); 
	}
	$res .= $bit;
    }    
    return $res;
}

sub delete_unwanted_levs
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $label = restructure::get_tag_contents($bit, "lev");
	    unless ($W{$label})
	    {
		$bit = restructure::tag_rename($bit, "lev", "label");
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
	unless (m|^ *$|)
	{
	    $W{$_} = 1;
	}
    }
    close(in_fp);
} 
