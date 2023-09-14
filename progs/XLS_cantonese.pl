#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_r, $opt_I, $opt_O, %W, %USED, %F, $DoLink);

#
require "./utils.pl";
require "./restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
$DoLink = 0;
our($workbook, $worksheet);
our($unlocked_fmt, $hidden_fmt, $centered_fmt, $header_fmt, $red_fmt, $black_fmt, %FREQ, $opt_c);

&main;

sub main
{
    getopts('uf:L:IODr:c:');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    use open qw(:std :utf8);
    unless ($opt_r)
    {
	$opt_r = "fk_test.xlsx";
    }
    unless ($opt_c)
    {
	$opt_c = "Cantonese";
    }
    &open_debug_files;
    if ($opt_D) {binmode DB::OUT,":utf8";}

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();

    &create_format_objects;
    my $row = 0;
    &load_file($ARGV[0]);
    $row = 0;
    my $lct = 0;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	
	if ($lct++ < 1)
	{	    
	    my @HDR = split(/\t/, $_);
	    $worksheet->write_row( $row++, 0, \@HDR);
	    next line;
	}
	# 0  'Word'
	# 1  'Context'
	# 2  'HW'
	# 3  'HW_Trans'
	# 4  'tag'
	# 5  'More Context'
	# 6  'Derogatory'
	# 7  'Offensive'
	# 8  'Vulgar'
	# 9  'Sensitivity classes'
	# 10  'def'
	# 11  'EntryId'
	# 12  'id'
	# 13  'dbid'
	# 14  'wdsens'
	# 15  'Times Used'
	my($wd, $cp, $h, $h_trans, $tag, $more_context, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens) = split(/\t/);	
	my @FLDS = split(/\t/);
	$FLDS[5] =~ s|&nl;|\n|g;
	$FLDS[15] = $FREQ{$wd};
	$worksheet->write_row( $row, 0, \@FLDS);	
	&write_context($cp, $row);

	if ($DoLink)
	{
	    my $link = sprintf("https://dws-dps.idm.fr/web/browser/view/\?projectCode=%s&entryId=%s&elementId=%s", $opt_c, $dbid, $eid); 
	    $worksheet->write_url($row, 4, $link, undef, "See xpath");
	}
	$row++;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
  }
    $worksheet->freeze_panes( 1, 0 );    # Freeze the first row
    # Format the columns
    ##    $worksheet->set_column( 'A:A', 45, $unlocked );
    ##    $worksheet->set_column( 'C:D', 45, $unlocked );
    # Protect the worksheet
    ##    $worksheet->protect({autofilter => 1});
    if (1)
    {
	$worksheet->set_column( 'A:A', 20 );   # Columns F-H width set to 30
	$worksheet->set_column( 'B:B', 80 );   # Columns F-H width set to 30
	$worksheet->set_column( 'C:C', 20 );   # Columns F-H width set to 30
	$worksheet->set_column( 'D:D', 20);   # Columns F-H width set to 30
	$worksheet->set_column( 'E:E', 10, $centered_fmt  );   # Columns F-H width set to 30
	$worksheet->set_column( 'F:F', 80 );   # Columns F-H width set to 30
	$worksheet->set_column( 'G:I', 10, $centered_fmt );   # Columns F-H width set to 30
	$worksheet->set_column( 'J:J', 40 );   # Columns F-H width set to 30
	$worksheet->set_column( 'K:N', 10 );   # Columns F-H width set to 30
    }
    $worksheet->autofilter( 'A1:W99999' );
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


sub parse_sensitivity
{
    my($e) = @_;
    my ($derogatory, $offensive, $vulgar, $wdsens);
    my $sens = restructure::get_tag_contents($e, "WDSENS");
    $sens =~ s|(<sens[ >].*?</sens>)|&split;&fk;$1&split;|g;
    my @BITS = split(/&split;/, $sens);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $type = restructure::get_tag_attval($bit, "sens", "type");
	    my $content = restructure::get_tag_contents($bit, "sens"); 
	    if ($type =~ m|derogatory|)
	    {
		$derogatory = $content;
	    }
	    elsif ($type =~ m|offensive|)
	    {
		$offensive = $content;
	    }
	    elsif ($type =~ m|vulgar|)
	    {
		$vulgar = $content;
	    }
	    else {
		$wdsens .= sprintf("%s:%s ", $type, $content); 
	    }
	}
    }
    return($derogatory, $offensive, $vulgar, $wdsens);
}


sub load_file
{
    my($f) = @_;
    my ($res, $bit, $info, $lc);
    my @BITS;
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
  wline:
    while (<in_fp>){
	chomp;
	s|||g;
	# my ($eid, $info) = split(/\t/);
	# $W{$_} = 1;
	if ($lc++ < 1)
	{
	    next wline;
	}
	s|\t.*$||;
	#	printf("%s\n", $FLDS[7]);
	$FREQ{$_}++;
  }
    close(in_fp);
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
