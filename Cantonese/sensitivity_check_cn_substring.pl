#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_i, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $opt_x);
our (%DEROG, %OFFENSIVE, %VULGAR, %SENSITIVE, %CLASSES, %DEF, %SENS, %TYPES, %CPDS, %FSCORE, %DSCORE, %SCORE, %EXCLUDE, %IGNORE);
#
# Input: File that has been split into the tags that are to be checked - as with the Spell Check input
# Data file: -f sensitiityInfo.xml - data extracted from ODE in tagged format
# Output - tabular data of possible issues, context tagged with <red> surrounding the content to be highlighted
#
$FSCORE{"low"} = 1;
$FSCORE{"medium"} = 5;
$FSCORE{"high"} = 10;
#
$DSCORE{"low"} = 1;
$DSCORE{"medium"} = 10;
$DSCORE{"high"} = 20;
#
#$PDIR = ".";
my $PDIR = "/usr/local/bin/";
require "./substring_sensitivity.pl";
require "$PDIR/utils.pl";
require "$PDIR/restructure.pl";

$LOG = 0;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IODo:x:i:');
    &usage if ($opt_u);
    my($e, $res, $bit, $tag);
    my %WD_USED;
    #   $opt_L = ""; # name of file for the log_fp output to go to
    use open qw(:utf8 :std);
    unless ($opt_f)
    {
	$opt_f = "SensitiveInfoWithFreqs.xml";
    }
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    if ($opt_x)
    {
	&load_exclusions($opt_x);
    }
    if ($opt_i)
    {
	&load_inclusions($opt_i);
    }
    &load_file($opt_f);    
    my $hdr = join("\t", "Word", "HW", "Context", "More Context", "tag", "Derogatory, Offensive or Vulgar", "Derogatory", "Offensive", "Vulgar", "Sensitivity classes", "def", "lexid", "EntryId", "e:id", "dbid", "word score", "total score", "Times seen");
    printf("%s\n", $hdr); 
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	my ($maxwd, $maxscore, $totscore);
	my @FLDS = split(/\t/);
	my($hw, $context, $tag, $lexid, $EntryId, $eid, $dbid) = split(/\t/);
	#	$context = &join_cpds($context);
	($context, $maxwd, $maxscore, $totscore) = &sensitivity_check_cn($context);
	next line unless ($context =~ m| score=|);
	my $info = &get_sensitivity_info($maxwd);	
	my $def = $DEF{$maxwd};
	my $ct = 1;
	undef %WD_USED;
	&print_row($maxwd, $hw, $context, $tag, $info, $def, $lexid, $EntryId, $eid, $dbid, $maxscore, $totscore, $ct++); ## TO DO
	$WD_USED{$maxwd} = 1;
	my $cp = $context;
	$cp =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
	my @BITS = split(/&split;/, $cp);
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $wd = restructure::get_tag_contents($bit, "wd"); 
		unless ($WD_USED{$wd}++)
		{
		    my $def = $DEF{$wd};
		    my $wd_context = &get_wd_context($context, $wd);
		    my $wdscore = $SCORE{$wd};
		    my $info = &get_sensitivity_info($wd);	
		    &print_row($wd, $hw, $wd_context, $tag, $info, $def, $lexid, $EntryId, $eid, $dbid, $wdscore, $totscore, $ct++); ## TO DO
		}
	    }
	    $res .= $bit;
	}	
  }
}

sub print_row
{
    my($wd, $h, $context, $tag, $info, $def, $lexid, $EntryId, $eid, $dbid, $maxscore, $totscore, $ct) = @_;
    my $e = join("\t", $wd, $h, $context, "", $tag, $info, $def, $lexid, $EntryId, $eid, $dbid, $maxscore, $totscore, $ct);
    printf("%s\n", $e);     
}

sub get_wd_context
{
    my($e, $twd) = @_;
    my($res);	
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $wd = restructure::get_tag_contents($bit, "wd");
	    unless ($wd eq $twd)
	    {
		$bit = restructure::lose_tag($bit, "wd"); # lose the tags but not the contents		
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub get_sensitivity_info
{
    my($wd) = @_;
    my($res);	
    my $wdsens = "";		    
    foreach my $type (sort keys %TYPES) 
    {
	my $wd_type = sprintf("%s\t%s", $wd, $type); 
	my $sens = $SENS{$wd_type};
	unless ($sens =~ m|^ *$|)
	{
	    #			    printf(STDERR "%s\n", $sens); 
	}
	unless ($sens =~ m|^ *$|)
	{
	    $wdsens .= sprintf("<$type>%s</$type>",  $sens);
	}
    }
    # Should have now built up a tab delimited set of classes for the word for each type in wdsens
    my $classes = $CLASSES{$wd};
    my $derog = $DEROG{$wd};
    my $offensive = $OFFENSIVE{$wd};
    my $vulgar = $VULGAR{$wd};
    $classes =~ s|; *$||;
    my $derog_off_vulgar;
    if (($derog =~ m|^ *$|) && ($offensive =~ m|^ *$|) && ($vulgar =~ m|^ *$|))
    {
	$derog_off_vulgar = "";
    } else {
	$derog_off_vulgar = "yes";
    }
    my $info = sprintf("$derog_off_vulgar\t$derog\t$offensive\t$vulgar\t$classes"); 
    $wdsens =~ s|\t$||;
    return $info;
}

sub sensitivity_check_cn
{
    my($e) = @_;
    my($maxwd, $maxscore, $totscore);	
    $e = &do_must($e);
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    while ($e =~ s|(<wd[^>]*>[^<]*)<wd[^>]*>([^<]*)</wd>|\1\2|g)
    {};
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	unless ($bit =~ s|&fk;||gi){
	    $bit = &do_should($bit);
	}
	$res .= $bit;
    }
    $e = $res;
    while ($e =~ s|(<wd[^>]*>[^<]*)<wd[^>]*>([^<]*)</wd>|\1\2|g)
    {};        
    if (0)
    {
	my @BITS = split(/&split;/, $e);
	my $res = "";
	foreach my $bit (@BITS){
	    unless ($bit =~ s|&fk;||gi){
		$bit = &do_could($bit);
	    }
	    $res .= $bit;
	}
	$e = $res;
	while ($e =~ s|(<wd[^>]*>[^<]*)<wd[^>]*>([^<]*)</wd>|\1\2|g)
	{};
    }
    #    $e = &tokenise($e);
    ($e, $maxwd, $maxscore, $totscore) = &add_cn_sensitivity_scores($e);
    return($e, $maxwd, $maxscore, $totscore);
}

sub add_cn_sensitivity_scores
{
    my($e) = @_;
    my($res, $eid);	
    my $maxwd = "";
    my $maxscore = "";
    my $totscore = "";
    
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score");
	    $totscore += $score;
	    if ($score > $maxscore)
	    {
		$maxscore = $score;
		$maxwd = restructure::get_tag_contents($bit, "wd"); 
	    }
	}
	$res .= $bit;
    }    
    return($res, $maxwd, $maxscore, $totscore);    
}


sub add_sensitivity_scores
{
    my($e) = @_;
    my($res, $maxwd, $maxscore, $totscore);	
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $wd = restructure::get_tag_contents($bit, "wd");
	    my $score = $SCORE{$wd};
	    if ($score =~ m|^ *$|)
	    {
		my $lcwd = $wd;
		$lcwd =~ tr|A-Z|a-z|;
		$score = $SCORE{$lcwd};
	    }
	    if ($score =~ m|^ *$|)
	    {
		$bit =~ s|<.*?>||gi;
	    } else {
		$bit = restructure::set_tag_attval($bit, "wd", "score", $score); 
	    }
	}
	$res .= $bit;
    }    
    if ($res =~ m|<wd|)
    {
	($res, $maxwd, $maxscore, $totscore) = &mark_max_scoring($res);
    }
    return($res, $maxwd, $maxscore, $totscore);
}

sub tokenise
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|<.*?>| |gi;
    $e =~ s|([, …\?\!\:\;]+)|<nonwd>\1</nonwd>|gi;
    #    $e =~ s|([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]+)|<nonwd>\1</nonwd>|gi;
    $e =~ s|(<nonwd[ >].*?</nonwd>)|&split;&fk;$1&split;|gi;
    # Cantonese = &#x95FF; 4E00–9FFF
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::get_tag_contents($bit, "nonwd"); 
	} else {
	    if ($bit =~ m|[\N{U+4E00}-\N{U+9FFF}]|)
	    {
		$bit = sprintf("<wd>%s</wd>", $bit);
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub mark_max_scoring
{
    my($e) = @_;
    my($res, $maxscore, $totscore, $maxwd, $done);	
    my ($maxscore, $totscore) = &get_maxscore($e);
    $maxwd = "zyzyz"; # just garbage that won't be matched - to allow for marking all occurrences of max word in sentence
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score");
	    my $wd = restructure::get_tag_contents($bit, "wd"); 
	    if (($score == $maxscore) || ($wd eq $maxwd))
	    {
		$maxwd = $wd;
		unless ($done++)
		{
		    $bit = restructure::set_tag_attval($bit, "wd", "max", "y");
		}
	    }
	}
	$res .= $bit;
    }    
    return ($res, $maxwd, $maxscore, $totscore);
}

sub get_maxscore
{
    my($e) = @_;
    my ($maxscore, $totscore);
    $maxscore = 0;
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score"); 
	    $totscore += $score;
	    if ($score > $maxscore)
	    {
		$maxscore = $score;
	    }
	}
    }
    return($maxscore, $totscore);
}


sub join_cpds
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|£| |g;
    $e = sprintf("£%s£", $e); 
    foreach my $cpd (sort keys %CPDS)
    {
	if ($e =~ m|[^a-z]$cpd[^a-z]|i)
	{
	    my $joined_cpd = $cpd;
	    $joined_cpd =~ s| +|_|g;
	    $e =~ s|([^a-z])$cpd([^a-z])|\1$joined_cpd\2|gi;
	}
    }
    $e =~ s|£||g;
    return $e;
}

sub join_cpds_old
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|£| |g;
    my($h, $context, $tag, $EntryId, $eid, $dbid) = split(/\t/);
    $context = sprintf("£%s£", $context); 
    foreach my $cpd (sort keys %CPDS)
    {
	if ($context =~ m|[^a-z]$cpd[^a-z]|i)
	{
	    my $joined_cpd = $cpd;
	    $joined_cpd =~ s| +|_|g;
	    $context =~ s|([^a-z])$cpd([^a-z])|\1$joined_cpd\2|gi;
	}
    }
    $context =~ s|£||g;
    $res = join("\t", $h, $context, $tag, $EntryId, $eid, $dbid); 
    return $res;
}


sub usage
{
    printf(STDERR "USAGE: $0 -u \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}



sub load_exclusions
{
    my($f) = @_;
    my ($res, $bit, $info);
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
    while (<in_fp>){
	chomp;
	s|| |g;
	# my ($eid, $info) = split(/\t/);
	if (m|[a-z]|i)
	{
	    s|^ *||;
	    s| *$||;
	    $IGNORE{$_} = 1;
	}
    }
    close(in_fp);
} 

sub load_inclusions
{
    my($f) = @_;
    my ($res, $bit, $info);
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
  wloop2:
    while (<in_fp>){
	chomp;
	s|| |g;
	# my ($eid, $info) = split(/\t/);
	if (m|[a-z]|i)
	{
	    s|^ *||;
	    s| *$||;
	    my $wd;
	    next wloop2 unless (m|<hw|);
	    $wd = restructure::get_tag_contents($_, "hw");
	    my $def = restructure::get_tag_contents($_, "def"); 
	    my $vulgar = restructure::get_tag_contents($_, "vulgar");
	    my $derog = restructure::get_tag_contents($_, "derogatory");
	    my $offensive = restructure::get_tag_contents($_, "offensive");
	    my $vulgar_offensive_avoid = restructure::get_tag_contents($_, "vulgar_offensive_avoid");
	    unless ($offensive =~ m|^ *$|)
	    {
		$OFFENSIVE{$wd} = $offensive;
	    }
	    unless ($derog =~ m|^ *$|)
	    {
		$DEROG{$wd} = $derog;
	    }
	    unless ($vulgar =~ m|^ *$|)
	    {
		$VULGAR{$wd} = $vulgar;
	    }
	    $DEF{$wd} = sprintf("%s%s; ", $DEF{$wd}, $def);
	    $SCORE{$wd} = 15;

	}
  }
    close(in_fp);
} 


sub load_file
{
    my($f) = @_;
    my ($res, $bit, $info);
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
  wloop:
    while (<in_fp>){
	chomp;
	s|| |g;
	# my ($eid, $info) = split(/\t/);
	my $wd = restructure::get_tag_contents($_, "wd");	
	my $def = restructure::get_tag_contents($_, "DEF");
	next wloop if ($IGNORE{$wd});
	if ($wd =~ m| |)
	{
	    # Only mark the compounds that have degree added as cpds - otherwise get too many and it's v slow
	    if (m| degree=|)
	    {
		$CPDS{$wd} = 1;
		$wd =~ s| +|_|g;
	    }
	}	
	$SENSITIVE{$wd} = 1;
	my ($wdfreq, $wddegree);
	if (m| freq=\"(.*?)\"|)
	{
	    $wdfreq = $1;
	} else {
	    $wdfreq = "medium";
	}
	if (m| degree=\"(.*?)\"|)
	{
	    $wddegree = $1;
	} else {
	    $wddegree = "medium";
	}
	$_ =~ s|(<sens[ >].*?</sens>)|&split;&fk;$1&split;|g;
	my @BITS = split(/&split;/, $_);
	my $res = "";
      floop2:
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $type = restructure::get_tag_attval($bit, "sens", "type");
		my $freq = "";
		my $degree = "";
		unless ($type =~ m|^ *$|)
		{		    
		    my $contents = restructure::get_tag_contents($bit, "sens"); 
		    $freq = restructure::get_tag_attval($bit, "sens", "freq");
		    $degree = restructure::get_tag_attval($bit, "sens", "degree"); 
		    if ($type =~ m|offensive|)
		    {
			$OFFENSIVE{$wd} = $contents;
		    }
		    elsif ($type =~ m|derogatory|)
		    {
			$DEROG{$wd} = $contents;
		    }
		    elsif ($type =~ m|vulgar|)
		    {
			$VULGAR{$wd} = $contents;
		    }
		    else{
			if ($contents =~ m|^[ y]*$|)
			{
			    $contents = $type;
			}
			my $wd_type = sprintf("%s\t%s", $wd, $type);
			$CLASSES{$wd} .= sprintf("%s:%s ", $type, $contents); 
			$TYPES{$type}++;
		    }
		}
		if ($freq =~ m|^ *$|)
		{
		    $freq = $wdfreq;
		}
		if ($degree =~ m|^ *$|)
		{
		    $degree = $wddegree;
		}
		my $fscore = $FSCORE{$freq};
		my $dscore = $DSCORE{$degree};
		my $score = $fscore + $dscore;
		$score++ if ($OFFENSIVE{$wd});
		$score++ if ($DEROG{$wd});
		$score++ if ($VULGAR{$wd});
		if ($score > $SCORE{$wd})
		{
		    $SCORE{$wd} = $score;
		}
	    }
      }
	$DEF{$wd} = sprintf("%s%s; ", $DEF{$wd}, $def);
  }
    close(in_fp);
} 


