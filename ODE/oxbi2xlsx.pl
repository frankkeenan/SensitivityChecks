#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;
use strict;
our ($LOG, $LOAD, $opt_r, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
our ($MAXROW, %TOPLEVS);
#
require "/usrdata3/dicts/NEWSTRUCTS/progs/utils.pl";
require "/NEWdata/dicts/generic/progs/restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 1;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; 
our ($workbook, $worksheet);
our ($unlocked, $locked, $hidden, $format1, $format2, $fmt_wrap);
our($opt_u);

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

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();
    &do_formats;
    my $row = 0;
    my @HDR = ("Headword", "HW label", "Additional labels", "Comment DE", "PoS", "Sense", "Comment DE", "Translation", "Comment EN", "Example", "Comment DE", "Example Translation", "Comment EN");
    my $HDR_ref = \@HDR;
    $worksheet->write_row( $row, 0, $HDR_ref);
    $MAXROW = $row;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	if (m|<e |)
	{
	    $MAXROW++;
	    $row = $MAXROW;
	    my $hw = restructure::get_tag_contents($_, "hw");
	    $worksheet->write( $row, 0, $hw, $fmt_wrap );
	    printf(log_fp "\n##\nr$row c0 [HW] $hw\n") if ($LOG); 
	    my $hwg = restructure::get_tag_contents($_, "hwg"); 
	    unless ($hwg =~ m|<lev|)
	    {
		$_ = &remove_grambs_without_lev($_);		
	    }
	    if ($hwg =~ m|<lev|){
		my $levs = &get_levs($hwg);
		my $labels = &get_labels($hwg);
		$worksheet->write( $row, 1, $levs, $fmt_wrap );
		$worksheet->write( $row, 2, $labels, $fmt_wrap );		
		printf(log_fp "r$row c1 [LEVS] $levs\n") if ($LOG); 
	    }
	    $row = &do_grambs($_, $row);
	}
	#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
  }
    $workbook->close();
    exit;
    &close_debug_files;
}

sub remove_grambs_without_lev
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<gramb[ >].*?</gramb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    undef %TOPLEVS;
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    if ($bit =~ m|<lev|)
	    {
		&store_toplevs($bit);
	    } else {
		$bit = "";
	    }
	}
	$res .= $bit;
    }
    my $levs = "";
    foreach my $lev (sort keys %TOPLEVS)
    {
	$levs = sprintf("%s%s", $levs, $lev); 
    }
    $res =~ s|(</hwg>)|$levs$1|;
    return $res;
}

sub store_toplevs
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|<semb.*||;
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $TOPLEVS{$bit} = 1;
	}
    }    
}



sub do_grambs
{
    my($e, $row) = @_;
    my($res, $eid);	
    $e =~ s|(<gramb[ >].*?</gramb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $pos = restructure::get_tag_contents($bit, "ps");
	    $worksheet->write($row, 4, $pos, $fmt_wrap);
	    printf(log_fp "r$row c4 [POS] $pos\n") if ($LOG);
	    &do_senses($bit, $row);
	    $row = $MAXROW+1;
	}
    }    
}

sub do_senses
{
    my($e, $srow) = @_;
    my($res, $eid);	
    $e =~ s|(<semb[ >].*?</semb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
#	    $bit =~ s| *<label[^>]*>(.*?)</label> *| (\1) |gi;
	    my $trans = restructure::get_tag_contents($bit, "trans-gs");
	    my $exas = restructure::get_tag_contents($bit, "x-gs");
	    my $xrefs = restructure::get_tag_contents($bit, "xr-gs");
	    $bit = restructure::tag_delete($bit, "x-gs");
	    $bit = restructure::tag_delete($bit, "xr-gs");
	    $bit = restructure::tag_delete($bit, "trans-gs");	    
	    my $def = restructure::get_tag_contents($bit, "semb"); 	    
	    $worksheet->write($srow, 5, $def, $fmt_wrap);
	    printf(log_fp "r$srow c5 [DEF] $def\n") if ($LOG);
	    &do_trans($trans, $srow);
	    &do_examples($exas, $srow);
	    $srow = $MAXROW + 1;
	}
    }    
}

sub do_examples
{
    my($e, $row) = @_;
    my($res, $eid);	
    $e =~ s|(<exg[ >].*?</exg>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit =~ s|</tx><tx[^>]*>|; |gi;
	    my $ex = restructure::get_tag_contents($bit, "ex");
	    my $tx = restructure::get_tag_contents($bit, "tx"); 
	    $worksheet->write($row, 9, $ex, $fmt_wrap);
	    $worksheet->write($row, 11, $tx, $fmt_wrap);
	    printf(log_fp "r$row c9 [EX] $ex\n") if ($LOG);
	    printf(log_fp "r$row c11 [TX] $tx\n") if ($LOG);
	    $row++;
	}
    }    
    $row--; # blank row added for next example
    if ($row > $MAXROW)
    {
	$MAXROW = $row;
    } 
}


sub do_trans
{
    my($e, $row) = @_;
    my($res, $eid);	
    $e =~ s|(<trg[ >].*?</trg>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::tag_delete($bit, "tgr"); 
	    my $ts = restructure::get_tag_contents($bit, "trg");
	    $ts =~ s|<.*?>| |gi;
	    $ts =~ s| +| |g;
	    $ts =~ s|^ +||g;
	    $ts =~ s| +$||g;
	    $worksheet->write($row, 7, $ts, $fmt_wrap);
	    printf(log_fp "r$row c7 [TS] $ts\n") if ($LOG);
	    $row++;
	}
    }    
    $row--; # blank row added for next trans
    if ($row > $MAXROW)
    {
	$MAXROW = $row;
    } 
}

sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}

sub get_labels
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    $e =~ s|(<label[ >].*?</label>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $label = restructure::get_tag_contents($bit, "label"); 
	    unless ($USED{$label}++)
	    {
		$res = sprintf("%s%s, ", $res, $label); 
	    }
	}
    }    
    $res =~ s|, *$||;
    return $res;
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
    $worksheet->set_column( 'A:A', 20, $unlocked );
    $worksheet->set_column( 'B:B', 20, $unlocked );
    $worksheet->set_column( 'C:C', 20, $unlocked );
    $worksheet->set_column( 'D:D', 20, $unlocked );
    $worksheet->set_column( 'E:E', 40, $unlocked );
    $worksheet->set_column( 'F:F', 80, $unlocked );
    $worksheet->set_column( 'G:G', 20, $unlocked );
    $worksheet->set_column( 'H:H', 80, $unlocked );
    $worksheet->set_column( 'I:I', 20, $unlocked );
    $worksheet->set_column( 'J:J', 80, $unlocked );
    $worksheet->set_column( 'K:K', 20, $unlocked );
    $worksheet->set_column( 'L:L', 80, $unlocked );
    $worksheet->set_column( 'M:M', 80, $unlocked );
    
    #    $worksheet->autofilter( 'A1:K1' );
    #    # Protect the worksheet
    #    $worksheet->protect("", {autofilter => 1});
    #    $worksheet->protect({autofilter => 1});
    #    protectWorksheet(wb, sheet = i, protect = TRUE, password = "Password") #Protect each sheet
}

