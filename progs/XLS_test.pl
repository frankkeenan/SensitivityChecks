#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_r, $opt_I, $opt_O, %W, %USED, %F, $DoLink, %LINK, %TimesSeen, %E_EIDS);

#
require "./utils.pl";
require "./restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
$DoLink = 0;
our($workbook, $worksheet, $worksheet_dict);
our($unlocked_fmt, $hidden_fmt, $centered_fmt, $header_fmt, $red_fmt, $green_fmt, $black_fmt, %FREQ, $opt_c);

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
	$opt_r = "fk_test3.xlsx";
    }
    &open_debug_files;
    if ($opt_D) {binmode DB::OUT,":utf8";}

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();
    $worksheet_dict = $workbook->add_worksheet('Dict');

    &create_format_objects;
    my $derog_offens_vulgar;
    my $row = 0;
    $row = 0;
    my $lct = 0;
#    my $coloured = "\'Frank a word that you\', \$red_fmt, \'use\', \'before the when\', \$green_fmt, \'it\', \' is what \', \$green_fmt, \'person\'";
    
#    my $coloured =  &colorize($_);
    
#    print $comm;
#    eval $comm;
    #    $worksheet->write_rich_string('A1',  'a word that you', $red_fmt, 'use', 'before the when', $green_fmt, 'it', ' is what ', $green_fmt, 'person');
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# set the max attribute
	$_ = &mark_highest_scoring($_);
	my $coloured_max =  &colorize_max($_);	
	my $comm = sprintf("\$worksheet->write_rich_string(%d, 1, %s)", $row, $coloured_max); 
	eval $comm;
	if (0)
	{
	    my ($wd, $context, $h, $h_trans, $tag, $more_context, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens) = split(/\t/);	
	    my $TimesUsed = $FREQ{$wd};
	    my $cp = $context;
	    $cp =~ s|<.*?>||g;
	    my $TimesSeen = ++$TimesSeen{$cp};
	    if (($derog =~ m|^ *$|) && ($offensive =~ m|^ *$|) && ($vulgar =~ m|^ *$|))
	    {
		$derog_offens_vulgar = "";
	    } else {
		$derog_offens_vulgar = "Yes";
	    }

	    my @FLDS = ($wd, $context, "", $h, $h_trans, $tag, $more_context, $derog_offens_vulgar, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens, $TimesUsed, $TimesSeen);
	    $worksheet->write_row( $row, 0, \@FLDS);	
	    &write_context($context, $row);
	    $more_context = $LINK{$EntryId}; # = sprintf("internal:Dict!B$row"); 
	    if ($more_context =~ m|^ *$|)
	    {
		printf(log_fp "%s\n", $EntryId); 
	    } else {
		$worksheet->write_url($row, 6, $more_context, undef, "Full Entry");
	    }
	    if ($DoLink)
	    {
		my $link = sprintf("https://dws-dps.idm.fr/web/browser/view/\?projectCode=%s&entryId=%s&elementId=%s", $opt_c, $dbid, $eid); 
		$worksheet->write_url($row, 4, $link, undef, "See xpath");
	    }
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
	$worksheet->set_column( 'C:C', 10 );   # Columns F-H width set to 30
	$worksheet->set_column( 'D:D', 20);   # Columns F-H width set to 30
	$worksheet->set_column( 'E:E', 20, $centered_fmt  );   # Columns F-H width set to 30
	$worksheet->set_column( 'F:F', 10 );   # Columns F-H width set to 30
	$worksheet->set_column( 'G:K', 10, $centered_fmt );   # Columns F-H width set to 30
	$worksheet->set_column( 'L:L', 40 );   # Columns F-H width set to 30
	$worksheet->set_column( 'M:M', 40 );   # Columns F-H width set to 30
	$worksheet->set_column( 'N:S', 10 );   # Columns F-H width set to 30
    }
    $worksheet->autofilter( 'A1:W99999' );
    $workbook->close();
    exit;
    &close_debug_files;
}

sub mark_highest_scoring
{
    my($e) = @_;
    my($res, $max);	
    my $cp = $e;
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score"); 
	    if ($score > $max)
	    {
		$max = $score;
	    }
	}
	$res .= $bit;
    }
    $e = $cp;
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score"); 
	    if ($score == $max)
	    {
		$max = 9999;
		$bit = restructure::set_tag_attval($bit, "wd", "max", "y"); 
	    }
	}
	$res .= $bit;
    }    
    return $res;
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




sub load_dict
{
    my($f) = @_;
    my ($res, $bit, $info);
    my @BITS;
    my %USED;
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
    my $row = 0;
  wline2:
    while (<in_fp>){
	chomp;
	s|||g;
	my($hw, $eng) = split(/\t/);
	#	my $hw = restructure::get_tag_contents($_, "hw");
	#	my $eng = restructure::get_tag_contents($_, "eng");
	next wline2 unless (m|<entry|);
	my $EntryId = restructure::get_tag_attval($_, "entry", "eid");
	unless ($E_EIDS{$EntryId})
	{
	    next wline2;
	}
	s|(<s[0-9][^>]*>)|&nl;$1|gi;
	s|</tx>|: |gi;
	s|<[^>]*>| |gi;
	s| +| |g;
	
	unless ($USED{$EntryId}++)
	{
	    $worksheet_dict->write($row, 0, $EntryId);
	    s|&nl;|\n|gi;
	    $worksheet_dict->write($row, 1, $_);
	    $row++;
	    $LINK{$EntryId} = sprintf("internal:Dict!B$row"); 
	}
  }
    close(in_fp);
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
	my ($wd, $context, $h, $h_trans, $tag, $more_context, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens) = split(/\t/);	

	s|\t.*$||;
	#	printf("%s\n", $FLDS[7]);
	$FREQ{$wd}++;
	$E_EIDS{$EntryId} = 1;
  }
    close(in_fp);
} 

sub colorize_max
{
    my($e) = @_;
    my($res, $eid);	
    $res = "";
    $e = sprintf(" %s ", $e); 
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $max = restructure::get_tag_attval($bit, "wd", "max"); 
	    my $bit = restructure::get_tag_contents($bit, "wd"); 
	    $bit =~ s|\'|&apos;|gi;
	    $bit =~ s|\"|&dquo;|gi;
	    if ($max =~ m|y|)
	    {
		$res .= sprintf("\$red_fmt, \'%s\', ", $bit);
	    } else {
		$res .= sprintf("\$green_fmt, \'%s\', ", $bit);
	    }
	}
	else {
	    $bit =~ s|\'|&apos;|gi;
	    $bit =~ s|\"|&dquo;|gi;
	    $res .= sprintf("\'%s\', ", $bit);
	}
    }    
    $res =~ s|, *$||;    
    $res =~ s|&apos;|\\'|g;
    $res =~ s|&dquo;|\"|g;
    return $res;
}

sub colorize
{
    my($e) = @_;
    my($res, $eid);	
    $res = "";
    $e = sprintf(" %s ", $e); 
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $max = restructure::get_tag_attval($bit, "wd", "max"); 
	    my $bit = restructure::get_tag_contents($bit, "wd"); 
	    $bit =~ s|\'|&apos;|gi;
	    $bit =~ s|\"|&dquo;|gi;
	    if ($max =~ m|y|)
	    {
		$res .= sprintf("\$red_fmt, \'%s\', ", $bit);
	    } else {
		$res .= sprintf("\$green_fmt, \'%s\', ", $bit);
	    }
	}
	else {
	    $bit =~ s|\'|&apos;|gi;
	    $bit =~ s|\"|&dquo;|gi;
	    $res .= sprintf("\'%s\', ", $bit);
	}
    }    
    $res =~ s|, *$||;    
    $res =~ s|&apos;|\\'|g;
    $res =~ s|&dquo;|\"|g;
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
    $green_fmt      = $workbook->add_format( color => 'green' );
    $black_fmt      = $workbook->add_format( color => 'black' );
}
sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}
