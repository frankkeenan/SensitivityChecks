#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
our (%DEROG, %OFFENSIVE, %VULGAR, %SENSITIVE, %CLASSES, %DEF);
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
    printf("\#Word\tContext\tH\tTag\tEntryId\tDerogatory\tOffensive\tVulgar\tSensitivity Classes\tDef\n"); 
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	my($h, $context, $tag, $EntryId) = split(/\t/);
	&sensitivity_check($context, $tag, $h, $EntryId);
  }
}

sub sensitivity_check
{
    my($e, $tag, $h, $EntryId) = @_;
    my($res, $eid);	
    my $context = $e;
    my $original = $context;
    $context =~ s|<.*?>| |g;
    $e = sprintf(" %s ", $e); 
    $context =~ s| +| |g;
    $e =~ s|<.*?>| |g;
    $e =~ s| +| |g;
    $e =~ s|[^A-Za-z0-9\-\'ÁÅÆÉÎÖÜàáâãäåæçèéêëíîïñòóôõöøùúûüýāăćČčęěŁłńňōœřśşŠšţūźž]+| |g;
    $e =~ s|\' | |g;
    $e =~ s| \'| |g;
    $e =~ s|/| |g;
    my($bit, $res);
    my %USED;
    my @WDS = split(/ +/, $e);
    $res = "";
  floop:
    foreach my $wd (@WDS){
	if ($wd =~ m|^[a-z]|){
	    $wd =~ tr|A-Z|a-z|;
	    if ($SENSITIVE{$wd})
	    {
		unless ($USED{$wd}++)
		{
		    my $cp = $context;
		    $cp =~ s|^ *| |g;
		    $cp =~ s| *$| |g;
		    $cp =~ s|([^a-z])$wd([^a-z])|\1<red>$wd</red>\2|g;
		    $cp =~ s|^ *||;
		    $cp =~ s| *$||;
		    my $cp2 = $cp;
		    $cp2 =~ s|</?red>||gi;
		
		    my $def = $DEF{$wd};
		    my $classes = $CLASSES{$wd};
		    my $derog = $DEROG{$wd};
		    my $offensive = $OFFENSIVE{$wd};
		    my $vulgar = $VULGAR{$wd};
		    $def =~ s|; *$||;
		    $classes =~ s|; *$||;
		    my $info = sprintf("$derog\t$offensive\t$vulgar\t$classes\t$def"); 
		    printf("%s\t%s\t%s\t%s\t%s\t%s\t%s\n", $wd, $cp, $h, $tag, $EntryId, $info);
		}
	    }
	}
  }    
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
	my $wd = restructure::get_tag_contents($_, "hw");	
	my $def = restructure::get_tag_contents($_, "def");
	my $derog = restructure::get_tag_contents($_, "derogatory");
	my $classes = restructure::get_tag_contents($_, "sensitivity_classes");
	my $offens = restructure::get_tag_contents($_, "offensive");
	my $vulgar = restructure::get_tag_contents($_, "vulgar");
	#
	$DEROG{$wd} = "y" if ($derog =~ m|y|i);
	$OFFENSIVE{$wd} = "y" if ($offens =~ m|y|i);
	$VULGAR{$wd} = "y" if ($vulgar =~ m|y|i);
	$SENSITIVE{$wd} = 1;
	$CLASSES{$wd} = sprintf("%s%s; ", $CLASSES{$wd}, $classes);
	$DEF{$wd} = sprintf("%s%s; ", $DEF{$wd}, $def);
    }
    close(in_fp);
} 
