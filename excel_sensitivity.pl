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

our($workbook, $worksheet);
our($unlocked_fmt, $hidden_fmt, $centered_fmt, $header_fmt, $red_fmt, $black_fmt);

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

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();

    &create_format_objects;

    # Format the columns
    ##    $worksheet->set_column( 'A:A', 45, $unlocked );
    ##    $worksheet->set_column( 'C:D', 45, $unlocked );
    # Protect the worksheet
    ##    $worksheet->protect({autofilter => 1});
    $worksheet->set_column( 'A:A', 20 );   # Columns F-H width set to 30
    $worksheet->set_column( 'B:B', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'C:C', 20 );   # Columns F-H width set to 30
    $worksheet->set_column( 'D:D', 10, $centered_fmt );   # Columns F-H width set to 30
    $worksheet->set_column( 'E:F', 20, undef, 1 );   # Columns E width set to 20 and hidden
    $worksheet->set_column( 'G:I', 10, $centered_fmt );   # Columns F-H width set to 30
    $worksheet->set_column( 'J:J', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'K:K', 50 );   # Columns F-H width set to 30
    $row = 0;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($lc++ < 1)
	{
	    # First line has the header
	    s|^ *\# *||;
	    @HDR = split(/\t/, $_);
	    for ($i=0; $i<13; $i++)
	    {
		$worksheet->write_string($row, $i, $HDR[$i], $header_fmt);
	    }
	    $row++;
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
	if ($context =~ m|<red|)
	{
	    &write_context($context, $row);
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

sub write_context
{
    my($e, $row) = @_;
    $e = sprintf(" %s ", $e); 
    if ($e =~ m|^(.*?)<red>(.*?)</red>(.*)$|)
    {
	my $pre = $1;
	my $redwd = $2;
	my $end = $3;
	$end =~ s|<red>(.*?)</red>|{{\1}}|gi;
	$pre =~ s|^ *||;
	$end =~ s| *$||;
	$worksheet->write_rich_string($row, 1,  $pre, $red_fmt, $redwd, $end);
    }
}

sub get_rich_string_excel_unhappy
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<red>.*?</red>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $bit = restructure::get_tag_contents($bit, "red"); 
	    $res = sprintf("%s\$red_fmt, \"%s\", ", $res, $bit); 
	} else {
	    $res = sprintf("%s\$black_fmt, \"%s\", ", $res, $bit); 
	}
    }	
    $res =~ s|, *$||;
    return $res;
}

sub create_format_objects
{
    # Create some format objects
    $unlocked_fmt = $workbook->add_format( locked => 0 );
    $hidden_fmt   = $workbook->add_format( hidden => 1 );
    $centered_fmt      = $workbook->add_format( center_across => 1 );
    $header_fmt      = $workbook->add_format( color => 'black', bold => 1, bg_color => 'silver', center_across => 1 );
    $red_fmt      = $workbook->add_format( color => 'red' );
    $black_fmt      = $workbook->add_format( color => 'black' );
}
sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}
