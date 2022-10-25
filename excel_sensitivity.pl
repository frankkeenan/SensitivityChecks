#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;

#
require "./utils.pl";
require "./restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$UTF8 = 1;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator

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
    if ($opt_D) {binmode DB::OUT,":utf8";}

    my $workbook  = Excel::Writer::XLSX->new( $opt_r );
    my $worksheet = $workbook->add_worksheet();

    # Create some format objects
    my $unlocked = $workbook->add_format( locked => 0 );
    my $hidden   = $workbook->add_format( hidden => 1 );
    my $centered      = $workbook->add_format( center_across => 1 );
    my $header_fmt      = $workbook->add_format( color => 'black', bold => 1, bg_color => 'silver', center_across => 1 );
    my $red      = $workbook->add_format( color => 'red' );
    my $black      = $workbook->add_format( color => 'black' );

    # Format the columns
    ##    $worksheet->set_column( 'A:A', 45, $unlocked );
    ##    $worksheet->set_column( 'C:D', 45, $unlocked );
    # Protect the worksheet
    ##    $worksheet->protect({autofilter => 1});
    $worksheet->set_column( 'A:A', 20 );   # Columns F-H width set to 30
    $worksheet->set_column( 'B:B', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'C:C', 20 );   # Columns F-H width set to 30
    $worksheet->set_column( 'D:H', 10, $centered );   # Columns F-H width set to 30
    $worksheet->set_column( 'E:E', 20, undef, 1 );   # Columns E width set to 20 and hidden
    $worksheet->set_column( 'I:I', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'J:J', 50 );   # Columns F-H width set to 30
    $row = 0;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($lc++ < 1)
	{
	    # First line has the header
	    s|^ *\# *||;
	    $HDR = $_;
	    
	    @HDR = split(/\t/, $_);
	    $HDR_ref = \@HDR;
	    $worksheet->write_row( $row++, 0, $HDR_ref, $header_fmt );
	    next line;
	}
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	@array = split(/\t/, $_);
	@FLDS = split(/\t/);
	$wd = $FLDS[0];
	$context = $FLDS[1];
	$hw = $FLDS[2];
	$lexid = $FLDS[1];
	($wd, $context, $hw, $tag, $lexid, $context_cp, $original_text, $pos, $def, $derogatory, $offensive, $vulgar, $sensitivity_classes) = split(/\t/);
	$worksheet->write_string($row, 0, $wd);
	#	$worksheet->write_string($row, 1, $context);       	
	if ($context =~ m|^(.*?)<red>(.*?)</red>(.*)$|)
	{
	    $context = &get_rich_string($context);
	    $context = sprintf("\$worksheet->write_rich_string( %s, 1, %s)", $row, $context); 
	    eval $context;
	}
	for ($i=2; $i<13; $i++)
	{
	    $worksheet->write_string($row, $i, $FLDS[$i]);
	}
	$row++;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    $worksheet->autofilter( 'A1:K1' );
    $worksheet->freeze_panes( 1, 0 );    # Freeze the first row
    $workbook->close();
    exit;
    &close_debug_files;
}

sub get_rich_string
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<red>.*?</red>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $bit = restructure::get_tag_contents($bit, "red"); 
	    $res = sprintf("%s\$red, \"%s\", ", $res, $bit); 
	} else {
	    $res = sprintf("%s\$black, \"%s\", ", $res, $bit); 
	}
    }	
    $res =~ s|, *$||;
    return $res;
}

sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}
