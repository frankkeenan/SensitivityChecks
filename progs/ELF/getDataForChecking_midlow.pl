#!/usr/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, %USED);
our (%INCLUDES, %EXCLUDES);
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
$LOAD = 1;
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
    use open qw(:std :utf8);
    &open_debug_files;
    if ($opt_D) {binmode DB::OUT,":utf8";}
    if ($LOAD){&load_config($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	unless (m|<e |){print $_; next line;}
	unless (m| priority="[ml]|i)
	{
	    next line;
	}
	# s|<!--.*?-->||gio;
	#	next line if (m|<e [^>]*del=\"y|io);
	#	next line if (m|<e [^>]*sup=\"y|io);
	my ($htag, $etag);
	if (m|<entryGroup|)
	{
	    $htag = "headword";
	    $etag = "entryGroup";
	} elsif (m|<entry |)
	{
	    if (m|</hw>|)
	    {
		$htag = "hw";
	    } else {
		$htag = "h";
	    }
	    $etag = "entry";
	} else {
	    $htag = "hw";
	    $etag = "e";
	}
	s|[‧ˌˈ]||gi;
	my $hw = restructure::get_tag_contents($_, $htag); 
	if (m| lexid=|)
	{
	    $_ = &inherit_lexids($_);
	}
	my $dbid = &get_tag_attval($_, $etag, "e:dbid");
	my $e_eid = restructure::get_tag_attval($_, $etag, "e:id"); 
	$_ = restructure::delabel($_);	
	s|<rf .*?</rf>|$hw|gi;
	$_ = restructure::set_tag_attval($_, "con", "tagname", "con");
	$_ = restructure::set_tag_attval($_, "ex", "tagname", "ex");
	$_ = restructure::tag_rename($_, "con", "ex"); #, "TOFIX", "PSGCOMMENT");
	$_ = &mark_first_examples($_);
	if (0)
	{
	    if (m| suppressed=\"true\"|)
	    {
		$_ = &lose_suppressed($_);
	    }
	}
	$_ = &lose_excludes($_);
	foreach my $tag (keys %INCLUDES)
	{
	    if (m|<$tag[ >]|)
	    {
		$_ = &print_tag($_, $tag, $hw, $e_eid, $dbid);
	    }
	}
	while (s|<[^/][^>]*> *</[^>]*>| |gi)
	{}
	s| e:[^ =]*=\".*?\"| |g;
	s| xmlns[^ =]*=\".*?\"| |g;
	s| +| |g;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub mark_first_examples
{
    my($e) = @_;
    my($res, $eid);	
    $e =~ s|(<ex[ >].*?</ex>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $lexid = restructure::get_tag_attval($bit, "ex", "lexid");
	    unless ($USED{$lexid}++)
	    {
		$bit = restructure::tag_rename($bit, "ex", "ex1"); #, "TOFIX", "PSGCOMMENT"); 
	    }
	}
	$res .= $bit;
    }    
    return $res;
}

sub inherit_lexids
{
    my($e) = @_;
    my($res, $prev_lexid);	
    if (m|^.*? lexid=\"(.*?)\"|)
    {
	$prev_lexid = $1;
    }
    $e =~ s|(<[a-zA-Z].*?>)|&split;&fk;$1&split;|gi;
    my @BITS = split(/&split;/, $e);
    my $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $tagname = restructure::get_tagname($bit);    
	    my $lexid = restructure::get_tag_attval($bit, $tagname, "lexid");
	    if ($lexid =~ m|^ *$|)
	    {
		$bit = restructure::set_tag_attval($bit, $tagname, "lexid", $prev_lexid); 
	    } else {
		$prev_lexid = $lexid;
	    }	    
	}
	$res .= $bit;
    }    
    return $res;
}


sub print_tag
{
    my($e, $tag, $hw, $e_eid, $dbid) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$tag[ >].*?</$tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
  floop:
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $eid = restructure::get_tag_attval($bit, $tag, "e:id");
	    my $lexid = restructure::get_tag_attval($bit, $tag, "lexid");
	    my $priority = restructure::get_tag_attval($bit, $tag, "lexid");
	    if ($priority =~ m|^ *$|)
	    {
		next floop;
	    }
	    my $content = restructure::get_tag_contents($bit, $tag); 
	    $content =~ s|<.*?>| |g;
	    $content =~ s| +| |g;
	    my $row = join("\t", $hw, $content, $tag, $lexid, $e_eid, $eid, $dbid);
	    print $row;
	    #	    printf("%s\t%s\t%s\t%s\t%s\t%s\n", $hw, $content, $tag, $e_eid, $eid, $dbid); 
	    $bit = "";
	}
	$res .= $bit;
  }    
    return $res;
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


sub lose_excludes
{
    my($e) = @_;
    my($res, $eid);	
    foreach my $tag (sort keys %EXCLUDES)
    {
	$e = restructure::tag_delete($e, $tag);
    }
    return $e;
}

sub usage
{
    printf(STDERR "USAGE: $0 -f config_file \n"); 
    printf(STDERR "\t-u:\tDisplay usage\n"); 
    #    printf(STDERR "\t-x:\t\n"); 
    exit;
}


sub load_config
{
    my($f) = @_;
    my ($res, $bit, $info);
    my @BITS;
    open(in_fp, "$f") || die "Unable to open $f"; 
    while (<in_fp>){
	chomp;
	s|||g;
	&load_excludes($_);
	&load_includes($_);
    }
    close(in_fp);
} 

sub load_excludes
{
    my($e) = @_;
    my(@BITS);
    $e =~ s|(<exclude[ >].*?</exclude>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $tag = restructure::get_tag_contents($bit, "exclude");
	    $EXCLUDES{$tag} = 1;
	}
    }
}

sub load_includes
{
    my($e) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<include[ >].*?</include>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $tag = restructure::get_tag_contents($bit, "include");
	    $INCLUDES{$tag} = 1;
	}
    }
}
