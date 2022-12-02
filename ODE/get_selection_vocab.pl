#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $opt_D, $opt_d, %W, %F, %TYPES);
if (1)
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
$LOAD = 1;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IODd');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my %USED;
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    binmode DB::OUT,":utf8" if ($opt_D);
    printf("<dict>\n"); 
    if ($LOAD){&load_file($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# s|<!--.*?-->||gio;
	#	unless (m|<e |){print $_; next line;}
	# my $eid = &get_tag_attval($_, "e", "e:id");
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	my $wanted_sensitivities = &check_wanted($_);
	if ($wanted_sensitivities =~ m|^ *$|)
	{
	    next line;
	}
	my $def = restructure::get_tag_contents($_, "DEF");
	undef %USED;
	my $hw = restructure::get_tag_contents($_, "hw");
	printf("<e><wd>%s</wd><SENS>%s</SENS><def>%s</def><hw>%s</hw></e>\n", $hw, $wanted_sensitivities, $def, $hw);
	$USED{$hw}++;
	$_ =~ s|(<infl[ >].*?</infl>)|&split;&fk;$1&split;|gi;
	@BITS = split(/&split;/, $_);
	$res = "";
	foreach my $bit (@BITS){
	    if ($bit =~ s|&fk;||gi){
		my $infl = restructure::get_tag_contents($bit, "infl");
		unless ($USED{$infl}++)
		{
		    printf("<e><wd>%s</wd><SENS>%s</SENS><def>%s</def><hw>%s</hw></e>\n", $infl, $wanted_sensitivities, $def, $hw);
		}
	    }
	}
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    printf("</dict>\n");
    &close_debug_files;
}

sub check_wanted
{
    my($e) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    my %TYPES;
    undef %TYPES;
    $e =~ s|(<sens[ >].*?</sens>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $type = restructure::get_tag_attval($bit, "sens", "type"); 
	    my $class = restructure::get_tag_contents($bit, "sens"); 
	    my $type_class = sprintf("%s\t%s", $type, $class);      
	    if ($W{$type_class})
	    {
		$TYPES{$type} .= sprintf("$class, "); 
	    }
	}
    }
    foreach my $type (sort keys %TYPES)
    {
	my $info = $TYPES{$type};
	$info =~ s|, *$||;
	$res .= sprintf("<sens type=\"$type\">$info</sens>"); 
    }
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
  wloop:    while (<in_fp>){
      chomp;
      s|||g;
      # my ($eid, $info) = split(/\t/);
      next wloop unless (m|<Select[^>]*> *y *</Select>|i);
      my $type = restructure::get_tag_contents($_, "Type");
      my $class = restructure::get_tag_contents($_, "Class"); 
      my $type_class = sprintf("%s\t%s", $type, $class);      
      $TYPES{$type} = 1; # Going to be the column header
      $W{$type_class} = 1;
  }
    close(in_fp);
} 
