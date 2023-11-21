#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $opt_D, $opt_d, %W, %F);
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
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once
&main;

sub main
{
    getopts('uf:L:IODd');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
#   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    binmode DB::OUT,":utf8" if ($opt_D);
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
	my $hw = restructure::get_tag_contents($_, "hw"); 
	if (m|[^a-z](vulg\.)|i)
	{
	    printf("%s\t%s\tvulgar\n", $hw, $1); 
	}
	if (m|[^a-z](obsc\.)|i)
	{
	    printf("%s\t%s\tobscene\n", $hw, $1); 
	}
	if (m|[^a-z](coll\.)|i)
	{
	    printf("%s\t%s\tcolloquial\n", $hw, $1); 
	}
	if (m|[^a-z](depr\.)|i)
	{
	    printf("%s\t%s\tdepractory\n", $hw, $1); 
	}
	if (m|[^a-z](derog\.)|i)
	{
	    printf("%s\t%s\tderogactory\n", $hw, $1); 
	}
	if (m|[^a-z](sl\.)|i)
	{
	    printf("%s\t%s\tslang\n", $hw, $1); 
	}
	if (m|[^a-z](fam\.)|i)
	{
	    printf("%s\t%s\tfamiliar\n", $hw, $1); 
	}
	if (m|[^a-z](imp\.)|i)
	{
	    printf("%s\t%s\timpolite\n", $hw, $1); 
	}
	if (m|[^a-z](off\.)|i)
	{
	    printf("%s\t%s\toffensive\n", $hw, $1); 
	}
#	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
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
