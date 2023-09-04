#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_v, $opt_D, $opt_I, $opt_O, $VERBOSE);
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
our %STORE;
our %WTAG;
our @ITAGS = ("lev", "slev", "label"); # Tags to inherit
our @TTAGS = ("trg"); # Where to inherit them to
foreach my $itag (@ITAGS){$WTAG{$itag} = 1;}
#foreach my $ttag (@TTAGS){$TTAG{$ttag} = 1;}
our $MAXLEVEL;

&main;

sub main
{
    getopts('uf:L:IOvD');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    $VERBOSE = 1 if ($opt_v);
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
	unless (m|<e |)
	{
	    print $_;
	    next line;
	}
	undef %STORE;
	$MAXLEVEL = 1;
	$_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	foreach my $tag (@ITAGS)
	{
	    $_ = &add_value_as_attribute($_, $tag);
	}
	$_ = restructure::tag_delete($_, "prx"); 
	$_ = restructure::delabel($_);	
	$_ = &duplicate_hwg_levs_to_grambs($_);
	foreach my $ttag (@TTAGS)
	{
	    s|(</$ttag>)|<IGRP ></IGRP>$1|gi;
	}
	$_ = restructure::add_levels_info($_, "e");
	print $_ if ($VERBOSE);
	$_ = &inherit_down($_);
	s|<IGRP[^>]*> *</IGRP>||gi;
	s| level=\".*?\"||g unless ($VERBOSE);
	print $_;
	printf("\n"); 
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub inherit_down
{
    my($e) = @_;
    my($res, $eid);	
    my($bit, $level, $maxlevel, $value);
    my(@BITS);
    $e =~ s|(<[^/].*?>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $tagname = restructure::get_tagname($bit);    
	    $level = restructure::get_tag_attval($bit, $tagname, "level"); 
	    if ($level > $MAXLEVEL)
	    {
		$MAXLEVEL = $level;
	    }
	    &delete_stored_below($level);
	    if ($WTAG{$tagname} == 1)
	    {
		$value = restructure::get_tag_attval($bit, $tagname, "tval"); 
		printf("STORE: %s\t%s\t%s\n", $tagname, $level, $value) if ($VERBOSE);  
		$STORE{$level} .= sprintf("<$tagname>%s</$tagname>", $value); 
	    }
	    if ($tagname =~ m|IGRP|)
	    {
		my $ilevs = &get_levs_above($level);
		$bit = sprintf("%s%s", $bit, $ilevs); 
	    }
	    printf("%s\t%s\t%s\n", $level, $tagname, $bit)  if ($VERBOSE); 
	}
	$res .= $bit;
    }    
    return $res;
}

sub get_levs_above
{
    my($level) = @_;
    my($res, $eid);	
    for (my $i=0; $i <= $level; $i++)
    {
	$res .= $STORE{$i};
    }    
    return $res;
}

sub delete_stored_below
{
    my($level) = @_;
    my($res, $eid);	
    for (my $i=$level+1; $i <= $MAXLEVEL; $i++)
    {
	delete $STORE{$i};
    }
    return $res;
}

sub duplicate_hwg_levs_to_grambs
{
    my($e) = @_;
    my($res, $hlevs);	
    my $hwg = restructure::get_tag_contents($e, "hwg");
    if ($hwg =~ m|<lev|)
    {
	my $hlevs = &get_levs($hwg);
	$e =~ s|(<gramb[^>]*>)|$1$hlevs|;
    }
    return $e;
}


sub get_levs
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    my(@BITS);
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $lev = restructure::get_tag_contents($bit, "lev"); 
	    unless ($USED{$lev}++)
	    {
		$res .= $bit;
	    }
	}
    }    
    return $res;
}

sub add_value_as_attribute
{
    my($e, $tag) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$tag[ >].*?</$tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $txt = restructure::get_tag_contents($bit, $tag);
	    $txt =~ s|<.*?>||gi;
	    $txt =~ s|[\"\']||gi;
	    $bit = restructure::set_tag_attval($bit, $tag, "tval", $txt); 
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
	# $W{$_} = 1;
    }
    close(in_fp);
} 
