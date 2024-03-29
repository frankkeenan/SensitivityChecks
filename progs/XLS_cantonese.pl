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
$LOG = 1;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
$DoLink = 0;
our($workbook, $worksheet, $worksheet_dict);
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
    unless ($opt_f)
    {
	$opt_f = "jdict2.xml";
    }
    &open_debug_files;
    if ($opt_D) {binmode DB::OUT,":utf8";}

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();
    $worksheet_dict = $workbook->add_worksheet('Dict');

    &create_format_objects;
    my $derog_offens_vulgar;
    my $row = 0;
    &load_file($ARGV[0]);
    &load_dict($opt_f);
    $row = 0;
    my $lct = 0;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	my @FLDS = split(/\t/);
	if ($lct++ < 1)
	{	    
	    my $hdr = join("\t", "Word", "Context", "Suppress example and example trans", "HW", "HW_Trans", "tag", "More Context", "Derogatory OR Offensive OR Vulgar", "Derogatory", "Offensive", "Vulgar", "Sensitivity classes", "def", "EntryId", "id", "dbid", "wdsens", "Times Used", "Times Seen");
	    my @HDR = split(/\t/, $hdr);	    
	    $worksheet->write_row( $row++, 0, \@HDR);
	    next line;
	}
	# 0  'Word'
	# 1  'Context'
	# 2  'Suppress example and example trans'
	# 3  'HW'
	# 4  'HW_Trans'
	# 5  'tag'
	# 6  'More Context'
	# 7  'Derogatory OR Offensive OR Vulgar'
	# 8  'Derogatory'
	# 9  'Offensive'
	# 10  'Vulgar'
	# 11  'Sensitivity classes'
	# 12  'def'
	# 13  'EntryId'
	# 14  'id'
	# 15  'dbid'
	# 16  'wdsens'
	# 17  'Times Used'
	# 18  'Which Occurrence of context'
	my @FLDS = split(/\t/);
	my $lexid = $FLDS[11];
	$lexid =~ s|\..*$||;
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
	my $lexid = $FLDS[11];
	$lexid =~ s|\..*$||;
	$EntryId = $lexid;
	my @FLDS = ($wd, $context, "", $h, $h_trans, $tag, $more_context, $derog_offens_vulgar, $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens, $TimesUsed, $TimesSeen);
	$worksheet->write_row( $row, 0, \@FLDS);	
	&write_context($context, $row);
	$more_context = $LINK{$EntryId};
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
	my $EntryId = restructure::get_tag_attval($_, "entryGroup", "lexid");
#	my $EntryId = restructure::get_tag_attval($_, "entry", "eid");
	unless ($E_EIDS{$EntryId})
	{
	    next wline2;
	}
	$_ = &fmt_dict_xml($_);
	
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

sub fmt_dict_xml
{
    my($e) = @_;
    my($res, $eid);	
    my @TAGS = ("sense", "entry", "posUnit", "note", "exampleUnit", "s1", "s2", "s3", "gramb", "semb", "exg", "idmb", "pvg", "trg", "xrefs");
    $e =~ s|£|&\#x00A3;|g;
    foreach my $tag (@TAGS)
    {
	$e =~ s|(<$tag[ >])|£\1|gi;
    }
    $e =~ s|<.*?>| |gi;
    $e =~ s| +| |g;
    $e =~ s|£+|£|g;
    $e =~ s|[ £]*£[ £]*|£|g;
    $e =~ s|^£||g;
    $e =~ s|£|&nl;|g;
    $e =~ s|&\#x00A3;|£|g;
    return $e;

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
	$EntryId =~ s|\..*$||;
	$FREQ{$wd}++;
	$E_EIDS{$EntryId} = 1;
  }
    close(in_fp);
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
