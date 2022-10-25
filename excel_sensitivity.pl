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

    my $workbook  = Excel::Writer::XLSX->new( $opt_r );
    my $worksheet = $workbook->add_worksheet();

    # Create some format objects
    my $unlocked = $workbook->add_format( locked => 0 );
    my $hidden   = $workbook->add_format( hidden => 1 );
    my $red      = $workbook->add_format( color => 'red' );

    # Format the columns
##    $worksheet->set_column( 'A:A', 45, $unlocked );
##    $worksheet->set_column( 'C:D', 45, $unlocked );
#    $worksheet->autofilter( 'A1:K1' );
    # Protect the worksheet
    ##    $worksheet->protect({autofilter => 1});
    $worksheet->set_column( 'E:E', 20 );   # Column  E   width set to 20
    $worksheet->set_column( 'A:L', 30 );   # Columns F-H width set to 30
    $worksheet->set_column( 'E:G', 20, undef, 1 );   # Columns E-G width set to 20 and hidden
    $worksheet->set_column( 'A:A', 20 );   # Columns F-H width set to 30
    $worksheet->set_column( 'B:B', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'I:I', 50 );   # Columns F-H width set to 30
    $worksheet->set_column( 'M:M', 50 );   # Columns F-H width set to 30
    $row = 0;
    if ($LOAD){&load_file($opt_f, \%WANTED);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($lc++ < 1)
	{
	    # First line has the header
	    $HDR = $_;
	    @HDR = split(/\t/, $_);
	    $HDR_ref = \@HDR;
	    $worksheet->write_row( $row++, 0, $HDR_ref );
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
	    $pre = $1;
	    $spell = $2;
	    $end = $3;
	    $worksheet->write_rich_string($row, 1,  $pre, $red, $spell, $end);
	}
	for ($i=2; $i<13; $i++)
	{
	    $worksheet->write_string($row, $i, $FLDS[$i]);
	}
	    #	$worksheet->write_string($row, 3, $tag);
#	$worksheet->write_string($row, 4, $lexid);
	$row++;
#	$array_ref = \@array;
#	$worksheet->write_row( $row++, 0, $array_ref );
#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    $workbook->close();
    exit;
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
