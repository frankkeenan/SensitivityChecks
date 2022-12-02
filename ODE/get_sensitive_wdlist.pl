#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, @SCLASSES, %SINFO);
if (0)
{
    require "/NEWdata/dicts/generic/progs/utils.pl";
    require "/NEWdata/dicts/generic/progs/restructure.pl";
}
else {
    require "./utils.pl";
    require "./restructure.pl";
}
# require "/data_new/VocabHub/progs/VocabHub.pm";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
@SCLASSES = ("derogatory", "offensive", "vulgar", "age", "crime", "disability", "ethnicity", "gendered", "geography", "other", "politics", "religion", "sex", "socioeconomic", "substance", "suicide", "trademark");
&main;

sub main
{
    getopts('uf:L:IOD');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    if ($opt_D)
    {
	binmode DB::OUT,":utf8";
    }
    my @HDR = ("Word", @SCLASSES, "Inflections", "Definition");
    my $hdr = join("\t", @HDR);
    print $hdr;
    if ($LOAD){&load_file($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# s|£|&\#x00A3;|g;
	$_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	$_ =~ s|(<entry[ >].*?</entry>)|&split;&fk;$1&split;|gi;
	my @BITS = split(/&split;/, $_);
	my $res = "";
      floop:
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $hw = restructure::get_tag_contents($bit, "headword");
		my $scs = &get_sensitivity_classes($bit);
		my $forms = &get_forms($bit);
		my $def = &get_def($bit);
		printf("%s\t%s\t%s\t%s\n", $hw, $scs, $forms, $def); 
	    }
	    $res .= $bit;
      }
	
	#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub get_def
{
    my($e) = @_;
    my($res, $eid);	
    $res = restructure::get_tag_contents($e, "shortDefinition"); 
    if ($res =~ m|^ *$|)
    {
	$res = restructure::get_tag_contents($e, "definition"); 
    }
    $res =~ s|<.*?>| |g;
    $res =~ s| +| |g;
    return $res;
}


sub get_forms
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    $e =~ s|(<infl[ >].*?</infl>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    unless ($USED{$bit}++)
	    {
		$res .= $bit;
	    }
	}
    }    
    return $res;
}


sub get_sensitivity_classes
{
    my($e) = @_;
    my($res, $eid);	
    undef %SINFO;
    my %USED;
    $e =~ s|(<classSensitivity[ >].*?</classSensitivity>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $type = restructure::get_tag_attval($bit, "classSensitivity", "value"); 
	    my $class = restructure::get_tag_contents($bit, "classSensitivity");
	    if ($class =~ m|^ *$|)
	    {
		$class = "y";
	    }
	    my $tc = sprintf("%s\t%s", $type, $class); 
	    unless ($USED{$tc}++)
	    {
		$SINFO{$type} .= sprintf("%s, ", $class); 
	    }
	}
    }    
    foreach my $type (@SCLASSES)
    {
	my $sinfo = $SINFO{$type};
	$sinfo =~ s|, *$||;
	$res .= sprintf("%s£", $sinfo); 
    }
    $res =~ s|£$||;
    $res =~ s|£|\t|g;
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
    my @BITS;
    open(in_fp, "$f") || die "Unable to open $f"; 
    binmode(in_fp, ":utf8");
    while (<in_fp>){
	chomp;
	s|||g;
	# my ($eid, $info) = split(/\t/);
	# $W{$_} = 1;
    }
    close(in_fp);
} 
