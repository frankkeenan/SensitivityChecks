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
	s|£|&\#x00A3;|g;
	s|<semb|£<semb|g;
	s|</semb>|</semb>£|g;
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
	    s|<co>|<co >|gi;
	    s| *<co [^>]*>(.*?)</co> *| (\1) |gi;

	    # Just an OxBi piece of crap to put the labels into the gramg's as well
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
	    $pos = restructure::get_tag_contents($bit, "ps");
	    $worksheet->write($row, 3, $pos, $fmt_wrap);
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


sub do_formats
{    # Create some format objects
    $unlocked = $workbook->add_format( locked => 0 );
    $locked = $workbook->add_format( locked => 1 );
    $hidden   = $workbook->add_format( hidden => 1 );
    # Light red fill with dark red text.
    $format1 = $workbook->add_format(
	bg_color => '#E6FFFF',
	color    => '#9C0006',
	
	);
    
    # Green fill with dark green text.
    $format2 = $workbook->add_format(
	bg_color => '#C6EFCE',
	color    => '#006100',
	
	);
    $fmt_wrap = $workbook->add_format();
    $fmt_wrap->set_text_wrap();
    # Format the columns
    $worksheet->autofilter( 'A1:I9999' );
    $worksheet->freeze_panes( 1 );    # Freeze the first row
    if (0)
    {
	$worksheet->set_column( 'A:A', 20, $unlocked );
	$worksheet->set_column( 'B:B', 20, $unlocked );
	$worksheet->set_column( 'C:C', 30, $unlocked );
	$worksheet->set_column( 'D:D', 80, $unlocked );
	$worksheet->set_column( 'E:E', 80, $unlocked );
	$worksheet->set_column( 'F:F', 25, $locked );
	$worksheet->set_column( 'G:I', 25, $locked );
	$worksheet->set_column( 'G:I', undef, undef, 1);
    }
    #    $worksheet->autofilter( 'A1:K1' );
    #    # Protect the worksheet
    $worksheet->protect("", {autofilter => 1});
    #    $worksheet->protect({autofilter => 1});
    #    protectWorksheet(wb, sheet = i, protect = TRUE, password = "Password") #Protect each sheet
}

