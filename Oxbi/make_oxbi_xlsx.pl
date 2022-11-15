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
    my $locked = $workbook->add_format( locked => 1 );
    my $hidden   = $workbook->add_format( hidden => 1 );
    # Light red fill with dark red text.
    my $format1 = $workbook->add_format(
	bg_color => '#E6FFFF',
	color    => '#9C0006',
	
	);
    
    # Green fill with dark green text.
    my $format2 = $workbook->add_format(
	bg_color => '#C6EFCE',
	color    => '#006100',
	
	);
    my $fmt_wrap = $workbook->add_format();
    $fmt_wrap->set_text_wrap();
    # Format the columns
    $worksheet->autofilter( 'A1:I9999' );
    $worksheet->freeze_panes( 1 );    # Freeze the first row
    $worksheet->set_column( 'A:A', 20, $unlocked );
    $worksheet->set_column( 'B:B', 20, $unlocked );
    $worksheet->set_column( 'C:C', 30, $unlocked );
    $worksheet->set_column( 'D:D', 80, $unlocked );
    $worksheet->set_column( 'E:E', 80, $unlocked );
    $worksheet->set_column( 'F:F', 25, $locked );
    $worksheet->set_column( 'G:I', 25, $locked );
    $worksheet->set_column( 'G:I', undef, undef, 1);
    #    $worksheet->autofilter( 'A1:K1' );
#    # Protect the worksheet
    $worksheet->protect("", {autofilter => 1});
#    $worksheet->protect({autofilter => 1});
    #    protectWorksheet(wb, sheet = i, protect = TRUE, password = "Password") #Protect each sheet  }
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
	($hw, $label, $hwg, $e, $exs, $lexid) = split(/\t/, $_);
	$_ =~ s|&nl;|\n|gi;
	@array = split(/\t/, $_);
	$array_ref = \@array;
	$worksheet->write_row( $row, 0, $array_ref );
	$e =~ s|^ *&nl; *||;
	$exs =~ s|^ *&nl; *||;
	$hwg =~ s|^ *&nl; *||;
	$e =~ s|&nl;|\n|gi;
	$hwg =~ s|&nl;|\n|gi;
	$exs =~ s|&nl;|\n|gi;
	$worksheet->write( $row, 2, $hwg, $fmt_wrap );
	$worksheet->write( $row, 3, $e, $fmt_wrap );
	$worksheet->write( $row, 4, $exs, $fmt_wrap );
	$row++;
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
