#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;

#
require "/usrdata3/dicts/NEWSTRUCTS/progs/utils.pl";
require "/NEWdata/dicts/generic/progs/restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$LOAD = 0;
$UTF8 = 1;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once

&main;

sub main
{
    getopts('uf:L:IODr:');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    use open qw(:std :utf8);
    unless ($opt_r)
    {
	$opt_r = "fk_test.xlsx";
    }
    &open_debug_files;
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    if ($LOAD){&load_file($opt_f, \%WANTED);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	for (my $i=0; $i < 5; $i++)
	{
	    $_ = restructure::move_back_out_of($_, "trg", "lev");
	    $_ = restructure::move_back_into($_, "tr", "lev");
	}
	$_ = restructure::rename_tag_in_tag($_, "exg", "lev", "levx");
	$_ = restructure::rename_tag_in_tag($_, "trg", "lev", "levt");
	# $e = restructure::rename_tag_in_tag($e, $container, $oldtag, $newtag);
	s|£|&\#x00A3;|g;
	s|<semb|£<semb|g;
	s|</semb>|</semb>£|g;
	s|<([a-z-]+)>|<\1 >|gi;
	if (m|<semb[^£]*£<semb|)
	{
	    s|<semb([^£]*)</semb>|<subsemb\1</subsemb>|gi;
	}
	s|£||g;
	if (m|<e |)
	{
	    $hw = restructure::get_tag_contents($_, "hw");
	    s|<rf[^>]*>|$hw|gi;
	    s|</rf>||gi;
	    $_ = restructure::rename_tag_in_tag($_, "exg", "trg", "tx-g");
	    $_ = restructure::rename_tag_in_tag($_, "exg", "tr", "tx");
	    $_ = restructure::add_group_tag_outsidegroup($_, "exg", "x-gs", "x-gs");
	    $_ = restructure::add_group_tag_outsidegroup($_, "trg", "trans-gs", "trans-gs");
	    $_ = restructure::add_group_tag_outsidegroup($_, "xrg", "xr-gs", "xr-gs");
	    $_ = restructure::move_back_into($_, "tr", "co");
	    $_ = &add_form_info($_);

	    s|(<semb[^>]*ngnum=\"(.*?)\"[^>]*>) *|\1\2. |gi;
	    s|<([a-z0-9\-_]+)>|<\1 >|gi;
	    s|<co>|<co >|gi;
	    s| *<fld [^>]*>(.*?)</fld> *| (\1) |gi;
	    s| *<co [^>]*>(.*?)</co> *| (\1) |gi;
	    s| *<cs [^>]*>(.*?)</cs> *| (\1) |gi;
	    s| *<gr [^>]*>(.*?)</gr> *| (\1) |gi;
	    s| *(<reg [^>]*>.*?</reg>) *| (\1) |gi;
	    s| *(<ind [^>]*>.*?</ind>) *| (\1) |gi;
	    s| *(<label [^>]*>.*?</label>) *| (\1) |gi;
	    s| *(<lev[^>]*>.*?</lev[^>]*>) *| (\1) |gi;
	    s|</tr><tr [^>]*>|, |gi;
	    $_ = &do_xrefs($_);
	    # Rename levs in examples
	    $_ = restructure::rename_tag_in_tag($_, "lev", "x-gs", "txlev");
	    if ($hwg =~ m|<lev|)
	    {
		my $lev_tags = &get_lev_tags($hwg);
		my $levs = &get_levs($hwg);
	    }	    
	}
	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

###
sub add_form_info
{
    my($e) = @_;
    my($res, $eid);	
    $e = &add_semb_forms($e);
    $e = &add_gramb_forms($e);
    my $hw = restructure::get_tag_contents($e, "hw");
    $e = &add_form_atts($e, $hw);
    return $e;
}

sub add_form_atts
{
    my($e, $frm) = @_;
    my($res, $eid);	
    $e =~ s|(<semb[ >].*?>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $sfrm = restructure::get_tag_attval($bit, "semb", "form");
	    if ($sfrm =~ m|^ *$|)
	    {
		$bit = restructure::set_tag_attval($bit, "semb", "form", $frm); 
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub add_gramb_forms
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<gramb[ >].*?</gramb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    if ($bit =~ m|<frm|)
	    {
		my $form = restructure::get_tag_contents($bit, "frm");
		$bit = &add_form_atts($bit, $form);
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub add_semb_forms
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<semb[ >].*?</semb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    if ($bit =~ m|<frm|)
	    {
		my $form = restructure::get_tag_contents($bit, "frm");
		$bit = restructure::set_tag_attval($bit, "semb", "form", $form); 
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

###

sub do_xrefs
{
    my($e) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e = restructure::tag_delete($e, "xrlabelGroup"); 
    $e =~ s|(<xr-gs[ >].*?</xr-gs>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit =~ s|</xrg><xrg[^>]*>|, |gi;
	    $bit =~ s|</xr><xr[^>]*>| |gi;
	    $bit = restructure::lose_tag($bit, "xrg"); # lose the tags but not the contents	    
	    $bit =~ s| *(<xr-gs[^>]*>) *| ➔ \1|gi;
	    $bit = restructure::lose_tag($bit, "xr"); # lose the tags but not the contents
	    $bit = restructure::lose_tag($bit, "xr-gs"); # lose the tags but not the contents	    
	}
	$res .= $bit;
    }    
    return $res;
}

sub do_gramgs
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<gramb[ >].*?</gramb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $pos = restructure::get_tag_contents($bit, "ps");
	    $bit = &do_senses($bit);
	}
	$res .= $bit;
    }    
}

sub do_senses
{
    my($e, $srow) = @_;
    my($res, $eid);	
    $row = $srow; # $srow = the starting row for the grammar group
    $e =~ s|(<semb[ >].*?</semb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $ngnum = restructure::get_tag_attval($bit, "semb", "ngnum");
	    s|(<semb[^>]*>)|$ngnum. |;
	    $bit = restructure::add_group_tag_outsidegroup($bit, "trg", "trans-gs", "trans-gs");
	    $bit = restructure::add_group_tag_outsidegroup($bit, "x-gs", "exg", "x-gs");
	    $maxrow = &do_trans($bit, $srow, $maxrow);
	    $maxrow = &do_examples($bit, $srow, $maxrow);
	}
	$res .= $bit;
    }    
    return $maxrow;
}

sub do_trans
{
    my($e, $srow, $maxrow) = @_;
    my($res, $eid);	
    my $trans = restructure::get_tag_contents($e, "trans-gs");
    
    return $res;
}

sub inherit_levs_to_gramgs
{
    my($e) = @_;
    my($res, $eid);	
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
    my($f, $WANTED) = @_;
    my ($res, $bit, $info);
    my @BITS;
    open(in_fp, "$f") || die "Unable to open $f"; 
    if ($UTF8){
	binmode(in_fp, ":utf8");
    }
    while (<in_fp>){
	chomp;
	s|||g;
	# my ($eid, $info) = split(/\t/);
	# $W{$_} = 1;
    }
    close(in_fp);
} 

sub get_levs
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $lev = restructure::get_tag_contents($bit, "lev"); 
	    unless ($USED{$lev}++)
	    {
		$res = sprintf("%s%s, ", $res, $lev); 
	    }
	}
    }    
    $res =~ s|, *$||;
    return $res;
}

sub get_lev_tags
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $lev = restructure::get_tag_contents($bit, "lev"); 
	    unless ($USED{$lev}++)
	    {
		$res = sprintf("%s%s", $res, $bit); 
	    }
	}
    }    
    return $res;
}



