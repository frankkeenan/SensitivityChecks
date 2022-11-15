#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
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
    if ($LOAD){&load_file($opt_f);}
    printf("Headword\tLabels\tHeadword Group\tEntry\tLexid\n"); 
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	# s|<!--.*?-->||gio;
	#	next line if (m|<entry[^>]*sup=\"y|io);
	#	unless (m|<entry|){print $_; next line;}
	# $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# $tagname = restructure::get_tagname($bit);    
	my $levs = &get_levs($_);
	my $hw = restructure::get_tag_contents($_, "hw");
	my $lexid = restructure::get_tag_attval($_, "e", "lexid"); 
	my ($hwg, $body) = &sep_hwd_body($_);
	$hwg = &punc($hwg, $hw);
	$body = &punc($body, $hw);
	unless ($body =~ m|^ *$|)
	{
	    printf("%s\t%s\t%s\t%s\t%s\n", $hw, $levs, $hwg, $body, $lexid);
	}
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
  }
    &close_debug_files;
}

sub sep_hwd_body
{
    my($e) = @_;
    my($res, $eid);	
    my $hwg = restructure::get_tag_contents($e, "hwg");
    my $e = restructure::tag_delete($e, "hwg"); 
    return($hwg, $e);
}

sub punc
{
    my($e, $hw) = @_;
    my($res, $eid);	
    $e =~ s| *<rf[ >].*?</rf> *| $hw |gi;
    $e =~ s| *<ind[^>]*>(.*?)</ind> *| (\1) |gi;
    $e =~ s| *<co[^>]*>(.*?)</co> *| (\1) |gi;
    $e =~ s|(<trg)| \1|gi;
    $e =~ s|(<gramb)| \1|gi;
    $e =~ s|(</hw>)|\1 |gi;
    $e =~ s|(<exg)|&nl;\1|gi;
    $e =~ s|(<semb)|&nl;\1|gi;
    $e =~ s|(<ex)| \1|gi;
    $e =~ s|(</trg>) *(<trg[ <])|\1: \2|gi;
    $e =~ s|(</lev>) *(<label)|\1, \2|gi;
    $e =~ s|(</label>) *(<label)|\1, \2|gi;
    $e =~ s|(</lev>) *(<lev)|\1, \2|gi;
    $e =~ s|(</tr>) *(<tr[ >])|\1, \2|gi;
    $e =~ s|(</tr>) *(<tgr)|\1 \2|gi;
    $e =~ s|(<semb[^>]* ngnum=\"(.*?)\")| (\2) \1|gi;
    if ($e =~ m|</gramb> *<gramb|)
    {
	$e =~ s| *(<gramb)|&nl;◼ \1|g;
    }
    $e =~ s|<.*?>| |g;
    $e =~ s| +([\,\.\?\!\:])|\1|g;
    $e =~ s| +| |g;   
    $e =~ s| *&nl; *|&nl;|gi;
    return $e;
}



sub get_levs
{
    my($e) = @_;
    my($res, $eid);	
    my %USED;
    $e =~ s|(<lev[ >].*?</lev>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $lev = restructure::get_tag_contents($bit, "lev"); 
	    unless ($USED{$lev}++)
	    {
		$res = sprintf("%s%s, ", $res, $lev); 
	    }
	}
    }    
    $res =~ s|[, ]*$||;
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
