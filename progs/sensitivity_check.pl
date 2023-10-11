#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
our (%DEROG, %OFFENSIVE, %VULGAR, %SENSITIVE, %CLASSES, %DEF, %SENS, %TYPES, %CPDS);
#
# Input: File that has been split into the tags that are to be checked - as with the Spell Check input
# Data file: -f sensitiityInfo.xml - data extracted from ODE in tagged format
# Output - tabular data of possible issues, context tagged with <red> surrounding the content to be highlighted
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
	$opt_f = "sensitivityInfo.xml";
    }
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    &load_file($opt_f);    
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	$_ = &join_cpds($_);
	my($h, $context, $tag, $EntryId, $eid, $dbid) = split(/\t/);
	&sensitivity_check($context, $tag, $h, $EntryId, $eid, $dbid);
  }
}

sub sensitivity_check
{
    my($e, $tag, $h, $EntryId, $eid, $dbid) = @_;
    my($res);	
    my $context = $e;
    my $original = $context;
    $context =~ s|<.*?>| |g;
    $e = sprintf(" %s ", $e); 
    $context =~ s| +| |g;
    $e =~ s|<.*?>| |g;
    $e =~ s| +| |g;
#    $e =~ s|[^A-Za-z0-9_\-\'ÁÅÆÉÎÖÜàáâãäåæçèéêëíîïñòóôõöøùúûüýāăćČčęěŁłńňōœřśşŠšţūźž]+| |g;
    $e =~ s|[^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]+| |g;
    $e =~ s|\' | |g;
    $e =~ s| \'| |g;
    $e =~ s|/| |g;
    my($bit, $res);
    my %USED;
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
		    my $cp = $context;
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
		    my $row = sprintf("<wd>$wd</wd><cp>$cp</cp><h>$h</h><tag>$tag</tag><EntryId>$EntryId</EntryId><eid>$eid</eid><dbid>$dbid</dbid><WDSENS>$wdsens</WDSENS><def>$def</def>"); 
#		    my $row = join("\t", $wd, $cp, $h, $tag, "", $EntryId, $eid, $dbid, $wdsens, $def);
		    #		    printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $wd, $cp, $h, $tag, $wdsens, $def,  $EntryId, $dbId);
		    print $row;
		}
	    }
	}
  }    
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
	$_ =~ s|(<sens[ >].*?</sens>)|&split;&fk;$1&split;|g;
	my @BITS = split(/&split;/, $_);
	my $res = "";
      floop2:
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $type = restructure::get_tag_attval($bit, "sens", "type");
		unless ($type =~ m|^ *$|)
		{
		    my $contents = restructure::get_tag_contents($bit, "sens"); 
		    unless (($type =~ m|offensive|) || ($type =~ m|vulgar|))
		    {
			if ($contents =~ m|^[ y]*$|)
			{
			    $contents = $type;
			}
			$type = "SensitivityClass";
			
		    }
		    my $wd_type = sprintf("%s\t%s", $wd, $type);
		    $SENS{$wd_type} = $contents;
		    $TYPES{$type}++;
		}
	    }
      }
	$DEF{$wd} = sprintf("%s%s; ", $DEF{$wd}, $def);
    }
    close(in_fp);
} 
