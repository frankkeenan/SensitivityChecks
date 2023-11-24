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
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    #    &load_file($opt_f);    
    my $hdr = join("\t", "Word", "Context", "HW", "tag", "Sentence Initial?", "lexid", "EntryId", "id", "dbid", "wdsens");
    printf("%s\n", $hdr); 
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	#	$_ = &join_cpds($_);
	my($h, $context, $tag, $EntryId, $eid, $dbid) = split(/\t/);
	$context = sprintf(" %s ", $context);
	$context =~ s|([^a-zA-Z])I([^a-zA-Z])|\1&i;\2|g;
	next line unless ($context =~ m|[A-Z]|);
	&caps_check($context, $tag, $h, $EntryId, $eid, $dbid);
  }
}

sub caps_check
{
    my($e, $tag, $h, $EntryId, $eid, $dbid) = @_;
    my($res);	
    my $context = $e;
    my $original = $context;
    $e = sprintf(" %s ", $e); 
    $context =~ s|<.*?>| |g;
    $context =~ s| +| |g;
    $e =~ s|<.*?>| |g;
    $e =~ s| +| |g;
    #    $e =~ s|[^A-Za-z0-9_\-\'ÁÅÆÉÎÖÜàáâãäåæçèéêëíîïñòóôõöøùúûüýāăćČčęěŁłńňōœřśşŠšţūźž]+| |g;
    $e =~ s|[^A-Za-z0-9_\-\'\N{U+370}-\N{U+3FF}\N{U+C0}-\N{U+CFF}]+| |g;
    $e =~ s|\' | |g;
    $e =~ s| \'| |g;
    $e =~ s|/| |g;
    $context =~ s|([^A-Za-z0-9]*)([A-Z]+[A-Za-z0-9\-]*)|\1<wd>\2</wd>|g;    
    my $cp = $context;
    my($bit, $res);
    my %USED;
    $cp =~ s|&i;|I|g;
    $context =~ s|^ *<wd>|<wd start=\"y\">|;
    $context =~ s|([\.\:\-\?\!]) *<wd>|\1 <wd start=\"y\">|;
    $context =~ s|(<wd[ >].*?</wd>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $context);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $wd = restructure::get_tag_contents($bit, "wd");
	    unless ($USED{$wd}++)
	    {
		my $start = "";
		if ($bit =~ m|start=\"y\"|)
		{
		    $start = "y";
		}
		my $row = join("\t", $wd, $cp, $h, $tag, $start, $EntryId, $eid, $dbid);
		print $row;
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
	    }
      }
	$DEF{$wd} = sprintf("%s%s; ", $DEF{$wd}, $def);
    }
    close(in_fp);
} 
