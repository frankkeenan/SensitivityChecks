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
our ($workbook, $worksheet);
our ($unlocked, $locked, $hidden, $format1, $format2, $fmt_wrap);

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
    $row = 0;
    if ($LOAD){&load_file($opt_f, \%WANTED);}
    my @HDR = ("Headword", "Additional labels", "Comment DE", "PoS", "Sense", "Comment DE", "Translation", "Comment EN", "Example", "Comment DE", "Example Translation", "Comment EN");
    my $HDR_ref = \@HDR;
    $worksheet->write_row( $row++, 0, $HDR_ref);
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	if (m|<e |)
	{
	    $hw = restructure::get_tag_contents($_, "hw");
	    $worksheet->write( $row, 0, $hw, $fmt_wrap );
	    $hwg = restructure::get_tag_contents($_, "hwg"); 
	    if ($hwg =~ m|<lev|)
	    {
		my $levs = &get_levs($hwg);
		$worksheet->write( $row, 1, $levs, $fmt_wrap );		
	    }
	    $row = &do_gramgs($_, $row);
	}
	#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
  }
    $workbook->close();
    exit;
    &close_debug_files;
}

sub do_gramgs
{
    my($e, $srow) = @_;
    my($res, $eid);	
    $row = $srow; # $srow = the starting row for the grammar group
    $e =~ s|(<gramb[ >].*?</gramb>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $pos = restructure::get_tag_contents($bit, "ps");
	    $worksheet->write($row, 3, $pos, $fmt_wrap);
	    $srow = &do_senses($bit, $srow);
	}
    }    
    return $srow;
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
	    $bit =~ s| *<label[^>]*>(.*?)</label> *| (\1) |gi;
	    $trans = restructure::get_tag_contents($bit, "trans-gs");
	    $exas = restructure::get_tag_contents($bit, "x-gs");
	    $xrefs = restructure::get_tag_contents($bit, "xr-gs");
	    $bit = restructure::tag_delete($bit, "x-gs");
	    $bit = restructure::tag_delete($bit, "xr-gs");
	    $bit = restructure::tag_delete($bit, "trans-gs");	    
	    $def = restructure::get_tag_contents($bit, "semb"); 	    
	    $worksheet->write($row, 4, $def, $fmt_wrap);
	    $maxrow = &do_trans($trans, $srow, $maxrow);
	    $maxrow = &do_examples($exas, $srow, $maxrow);
	    $srow = $maxrow + 1;
	}
    }    
    return $maxrow;
}

sub do_examples
{
    my($e, $row, $maxrow) = @_;
    my($res, $eid);	
    $e =~ s|(<exg[ >].*?</exg>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit =~ s|</tx><tx[^>]*>|; |gi;
	    $ex = restructure::get_tag_contents($bit, "ex");
	    $tx = restructure::get_tag_contents($bit, "tx"); 
	    $worksheet->write($row, 8, $ex, $fmt_wrap);
	    $worksheet->write($row, 10, $tx, $fmt_wrap);
	    $row++;
	}
    }    
    if ($row > $maxrow)
    {
	$maxrow = $row;
    } 
    return $maxrow;
}


sub do_trans
{
    my($e, $row, $maxrow) = @_;
    my($res, $eid);	
    $e =~ s|(<trg[ >].*?</trg>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::tag_delete($bit, "tgr"); 
	    my $ts = restructure::get_tag_contents($bit, "tr");
	    $worksheet->write($row, 6, $ts, $fmt_wrap);
	    $row++;
	}
    }    
    if ($row > $maxrow)
    {
	$maxrow = $row;
    } 
    return $maxrow;
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
    $worksheet->set_column( 'A:A', 20, $unlocked );
    $worksheet->set_column( 'B:B', 20, $unlocked );
    $worksheet->set_column( 'C:C', 20, $unlocked );
    $worksheet->set_column( 'D:D', 40, $unlocked );
    $worksheet->set_column( 'E:E', 80, $unlocked );
    $worksheet->set_column( 'G:G', 80, $unlocked );
    $worksheet->set_column( 'F:F', 25, $unlocked );
    $worksheet->set_column( 'I:I', 80, $unlocked );
    $worksheet->set_column( 'J:K', 25, $unlocked );
    $worksheet->set_column( 'K:K', 80, $unlocked );
    #    $worksheet->autofilter( 'A1:K1' );
    #    # Protect the worksheet
    $worksheet->protect("", {autofilter => 1});
    #    $worksheet->protect({autofilter => 1});
    #    protectWorksheet(wb, sheet = i, protect = TRUE, password = "Password") #Protect each sheet
}

