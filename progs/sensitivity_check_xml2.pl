#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
our (%DEROG, %OFFENSIVE, %VULGAR, %SENSITIVE, %CLASSES, %DEF, %SENS, %TYPES, %CPDS, %FSCORE, %DSCORE, %SCORE);
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
if (1)
{
    require "/NEWdata/dicts/generic/progs/utils.pl";
    require "/NEWdata/dicts/generic/progs/restructure.pl";
}
else {
    require "./utils.pl";
    require "./restructure.pl";
}
$LOG = 0;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IODo:');
    &usage if ($opt_u);
    my($e, $res, $bit, $tag);
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
    &load_file($opt_f);    
    my $hdr = join("\t", "Word", "Context", "HW", "HW_Trans", "tag", "More Context", "Derogatory", "Offensive", "Vulgar", "Sensitivity classes", "def", "EntryId", "id", "dbid", "wdsens");
    printf("%s\n", $hdr); 
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	$_ = &join_cpds($_);
	my($h, $context, $tag, $EntryId, $eid, $dbid) = split(/\t/);
	$context = &sensitivity_check_new($context, $tag, $h, $EntryId, $eid, $dbid);
	#	&sensitivity_check($context, $tag, $h, $EntryId, $eid, $dbid);
	next line unless ($context =~ m| score=|);
	print $context;
  }
}


sub sensitivity_check_new
{
    my($e, $tag, $h, $EntryId, $eid, $dbid) = @_;
    my($res);	
    my $context = $e;
    my $original = $context;
    $e = &tokenise($e);
    $e = &add_sensitivity_scores($e);
    return $e;
}

sub add_sensitivity_scores
{
    my($e) = @_;
    my($res, $eid);	
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
	$res = &mark_highest_scoring($res);
    }
    return $res;
}

sub tokenise
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|<.*?>| |gi;
    $e =~ s|([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]+)|<nonwd>\1</nonwd>|gi;
    $e =~ s|(<nonwd[ >].*?</nonwd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::get_tag_contents($bit, "nonwd"); 
	} else {
	    if ($bit =~ m|[A-Za-z\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]|)
	    {
		$bit = sprintf("<wd>%s</wd>", $bit);
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub sensitivity_check
{
    my($e, $tag, $h, $EntryId, $eid, $dbid) = @_;
    my($res);	
    my($bit, $res);
    my %USED;
    # CHANGE TO MARK ALL SENSITIVE WDS WITH THE HIGHEST SCORING ONE THE ONE THAT IS DONE FIRST
    $e = &mark_highest_scoring($e);
    

    my @WDS = split(/ +/, $e);
    $res = "";
  floop:
    foreach my $wd (@WDS){
	if ($wd =~ m|^[A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]|){
	    my $lcwd = $wd;
	    $lcwd =~ tr|A-Z|a-z|;
	    if ($SENSITIVE{$lcwd})
	    {
		unless ($USED{$lcwd}++)
		{
		    #		    my $cp = $context;
		    my $cp = $e;
		    $cp =~ s|^ *| |g;
		    $cp =~ s| *$| |g;
		    $cp =~ s|([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}])$wd([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}])|\1<red>$wd</red>\2|g;
		    unless ($cp =~ m|<red|)
		    {
			$cp =~ s|([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}])($wd)([^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}])|\1<red>$wd/red>\3|gi;
		    }
		    $cp =~ s|^ *||;
		    $cp =~ s| *$||;
		    my $cp2 = $cp;
		    $cp2 =~ s|</?red>||gi;
		    #
		    # Just deal with lower case
		    $wd = $lcwd;
		    my $def = $DEF{$wd};
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
		    $def =~ s|; *$||;
		    $classes =~ s|; *$||;
		    my $info = sprintf("$derog\t$offensive\t$vulgar\t$classes\t$def"); 
		    $wdsens =~ s|\t$||;
		    #		    my $row = sprintf("<wd>$wd</wd><cp>$cp</cp><h>$h</h><tag>$tag</tag><EntryId>$EntryId</EntryId><eid>$eid</eid><dbid>$dbid</dbid><WDSENS>$wdsens</WDSENS><def>$def</def>"); 
		    my $row = join("\t", $wd, $cp, $h, "", $tag, "", $derog, $offensive, $vulgar, $classes, $def, $EntryId, $eid, $dbid, $wdsens);
		    #		    printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $wd, $cp, $h, $tag, $wdsens, $def,  $EntryId, $dbId);
		    print $row;
		}
	    }
	}
  }    
}

sub mark_highest_scoring
{
    my($e) = @_;
    my($res, $max);	
    my $max = &get_highest_score($e);
    $e =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $score = restructure::get_tag_attval($bit, "wd", "score"); 
	    if ($score == $max)
	    {
		$max = 9999; # only want the first word to be max
		$bit = restructure::set_tag_attval($bit, "wd", "max", "y"); 
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub get_highest_score
{
    my($e) = @_;
    my($res, $max);	
    $max = 0;
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
    return $max;
}


sub join_cpds
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
    $res = sprintf("%s\t%s\t%s\t%s\t%s\t%s", $h, $context, $tag, $EntryId, $eid, $dbid); 
    return $res;
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
    my($f) = @_;
    my ($res, $bit, $info);
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
    while (<in_fp>){
	chomp;
	s|| |g;
	# my ($eid, $info) = split(/\t/);
	my $wd = restructure::get_tag_contents($_, "wd");	
	my $def = restructure::get_tag_contents($_, "DEF");
	if ($wd =~ m| |)
	{
	    $CPDS{$wd} = 1;
	    $wd =~ s| +|_|g;
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
