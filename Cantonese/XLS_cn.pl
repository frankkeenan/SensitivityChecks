#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use utf8;
use Excel::Writer::XLSX;
use strict;
our ($LOAD, $opt_f, $opt_u, $opt_D, $opt_r, $opt_I, $opt_O, %W, %USED, %F, $DoLink, %LINK, %TimesSeen, %E_EIDS, %DICT);
our $LOG;
#
my $PDIR = "/usr/local/bin/";

require "$PDIR/utils.pl";
require "$PDIR/restructure.pl";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
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
    if ($opt_f)
    {
	&load_dict($opt_f);
    }
    &open_debug_files;
    if ($opt_D) {binmode DB::OUT,":utf8";}

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet('Sensitivity');
    $worksheet_dict = $workbook->add_worksheet('Dict');

    &create_format_objects;
    my $row = 0;
    my $dict_row = 0;
    my $lct = 0;
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# set the max attribute
	my $coloured;
	my ($wd, $h, $context, $context_ts, $more_context, $tag, $info, $def, $lexid, $EntryId, $eid, $dbid, $maxscore, $totscore, $ct) = split(/\t/);
	my @FLDS = split(/\t/, $_);
# 0  'Word'
# 1  'HW'
# 2  'Context'
# == SPLICING Context Trans
# 3  'More Context'
# 4  'tag'
# 5  'Derogatory, Offensive or Vulgar'
# 6  'Derogatory'
# 7  'Offensive'
# 8  'Vulgar'
# 9  'Sensitivity classes'
# 10  'def'
# 11  'lexid'
# 12  'EntryId'
# 13  'e:id'
# 14  'dbid'
# 15  'word score'
# 16  'total score'
# 17  'Times seen'
	$FLDS[3] =~ s|&nl;|\n|g;
	$EntryId = $FLDS[12];
	$EntryId =~ s|\..*$||;
	$FLDS[10] =~ s|^ *sensitive:||i;
	$worksheet->write_row( $row, 0, \@FLDS);	
	$context = $FLDS[2];
	if ($context =~ m| max=\"y\"|)
	{
	    $coloured =  &colorize_max($context);
	} else {
	    $coloured =  &colorize($context);
	}
	my $comm = sprintf("\$worksheet->write_rich_string(%d, 2, %s)", $row, $coloured); 
	eval $comm;
#	printf("%d\t%s\n", $row, $comm); 
	unless ($LINK{$EntryId})
	{
	    # Not created this entry before
	    $worksheet_dict->write($dict_row, 0, $EntryId);
	    $worksheet_dict->write($dict_row, 1, $DICT{$EntryId});
	    my $lrow = $dict_row + 1;
	    $LINK{$EntryId} = sprintf("internal:Dict!B$lrow"); 	    
	    $dict_row++;
	}
	$more_context = $LINK{$EntryId};
	unless ($more_context =~ m|^ *$|)
	{
	    $worksheet->write_url($row, 4, $more_context, undef, "Full Entry");
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
	$worksheet->set_column( 'A:T', 20 );   # Set default column width
	$worksheet->set_column( 'C:D', 60 );   # Columns F-H width set to 30
	$worksheet->set_column( 'J:J', 40 );   # Columns F-H width set to 30
	$worksheet->set_column( 'L:L', 20, $hidden_fmt);   # Columns F-H width set to 30
	$worksheet->set_column( 'N:T', 20, $hidden_fmt);   # Columns F-H width set to 30
	$worksheet_dict->set_column( 'B:B', 160 );   # Columns F-H width set to 30
    }
    $worksheet->autofilter( 'A1:W99999' );
    $workbook->close();
    &close_debug_files;
    exit;
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

sub load_dict_old
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

sub colorize_max
{
    my($e) = @_;
    my($res, $eid);	
    $res = "";
    $e = sprintf(" %s ", $e); 
    $e =~ s|\'|&apos;|gi;
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $max = restructure::get_tag_attval($bit, "wd", "max"); 
	    my $bit = restructure::get_tag_contents($bit, "wd"); 
	    $bit =~ s|\"|&dquo;|gi;
	    if ($max =~ m|y|)
	    {
		$res .= sprintf("\$red_fmt, \'%s\', ", $bit);
	    } else {
		$res .= sprintf("\$green_fmt, \'%s\', ", $bit);
	    }
	}
	else {
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
    $e =~ s|\'|&apos;|gi;
    $e =~ s|\"|&dquo;|gi;
    $e = sprintf(" %s ", $e); 
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $bit = restructure::get_tag_contents($bit, "wd"); 
	    $res .= sprintf("\$red_fmt, \'%s\', ", $bit);
	}
	else {
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
	next wline2 unless (m|<entry|);
	my $EntryId = restructure::get_tag_attval($_, "entryGroup", "lexid");
	$_ = restructure::tag_delete($_, "pronunciations");
	$_ = restructure::tag_delete($_, "prx"); 
	if (m| suppressed=\"true\"|)
	{
	    $_ = &lose_suppressed($_);
	}
	$_ = &fmt_dict_xml($_);
	s|&nl;|\n|g;
	$DICT{$EntryId} = $_;
    }
    close(in_fp);
} 

sub lose_suppressed
{
    my($e) = @_;
    my($res, $eid);	
    while ($e =~ m|(<[^>]* suppressed=\"true\".*?>)|)
    {
	my $tagname = restructure::get_tagname($1);
	my $cp = $e;
	$e = &lose_suppressed_tag($e, $tagname);
	last if ($cp eq $e);
    }
    return $e;
}

sub lose_suppressed_tag
{
    my($e, $tag) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$tag[ >].*?</$tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $sup = restructure::get_tag_attval($bit, $tag, "suppressed");
	    if ($sup =~ m|true|i)
	    {
		$bit = "";
	    }
	}
	$res .= $bit;
    }    
    return $res;
}
