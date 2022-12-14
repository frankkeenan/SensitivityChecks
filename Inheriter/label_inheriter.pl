#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O);
our (%STORE, @LABELS, $maxlevel);

require "./utils.pl";
require "./restructure.pl";

# require "/data_new/VocabHub/progs/VocabHub.pm";
#require "/NEWdata/dicts/generic/progs/xsl_lib_fk.pl";
$LOG = 0;
$LOAD = 0;
$, = ' ';               # set output field separator
$\ = "\n";              # set output record separator
#undef $/; # read in the whole file at once

our @TOPLIST_TAGS = ("hwg", "idmsec", "pvsec", "gramb");
our @TAGS_TO_INHERIT = ("lev", "reg");
#our @TARGET_TAGS = ("sense", "sn-g", "msCore", "semb", "trg");
our @TARGET_TAGS = ("trg"); # Only works with one target tag - otherwise it won't inherit from the parent to the child if both are targets - e.g. not from <sense> down to <trg>
our (%INHERIT, %DUMP);

# rename the tags_to_inherit tags in the @TARGET_TAGS - to avoid them being inherited - with <TMP_
# Create "inherited-g" tags in the @TARGET_TAGS
# Foreach of the toplist tags inherit each of the @TAGS_TO_INHERIT into the inherited-g tags - prefix tagname with <i_
# rename <TMP_ tags back to what they were

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
    my $entry_tag = "e";
    foreach my $tag (@TAGS_TO_INHERIT)     {$INHERIT{$tag} = 1;}
    foreach my $tag (@TARGET_TAGS) {$DUMP{$tag} = 1;}
    if ($LOAD){&load_file($opt_f);}
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}
	$_ = restructure::delabel($_);
	$_ = &rename_target_tags($_);
	$_ = &create_inherited_groups($_);
	$_ = restructure::add_levels_info($_, $entry_tag);
	s| e:[^ =]*=\".*?\"||gi;
	s| xmlns[^ =]*=\".*?\"||gi;
	my $level;
	if (m|<$entry_tag[ >]|)
	{
	    $_ =~ s|(<[^/].*?>[^<]*)|&split;&fk;$1&split;|gi;
	    $_ =~ s|(</.*?>)|&split;&fk;$1&split;|gi;
	    @BITS = split(/&split;/, $_);
	    $res = "";
	    foreach $bit (@BITS){
		if ($bit =~ s|&fk;||gi){
		    my $tagname = restructure::get_tagname($bit);    
		    my $info;
		    if ($tagname =~ m|^ *inherited|)
		    {
			$info = &get_labels_from_above($level);
			$bit .= $info;
			#			$bit =~ s|^(.*)</|
		    }
		    unless ($tagname =~ m|^ */|)
		    {
			$level = restructure::get_tag_attval($bit, $tagname, "level"); 
			if ($level > $maxlevel)
			{
			    $maxlevel = $level;
			}
			&remove_labels_from_below($level, $maxlevel);
		    }
		    if ($INHERIT{$tagname})
		    {
			$info = sprintf("%s</%s>", $bit, $tagname); 
			my $newtag = $tagname;
			$newtag =~ s|^ *|i_|;
			$info = restructure::tag_rename($info, $tagname, $newtag); #, "TOFIX", "PSGCOMMENT"); 
			$LABELS[$level-1] = $info;
		    }
		    printf("%s\t%s\n", $tagname, $level); 
		}
		$res .= $bit;
	    }	
	    print $res;
	    exit;
	}
	foreach my $toplist_tag (@TOPLIST_TAGS) 
	{
	    if (m|<$toplist_tag[ ]|)
	    {
		$_ = &inherit_tags($_, $toplist_tag);
	    }
	}
	s|<(/?)TMP_|<\1|g;
	s|<inherited-g *> *</inherited-g>||gi;
	print $_;
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    &close_debug_files;
}

sub remove_labels_from_below
{
    my($level, $maxlevel) = @_;
    for (my $i = $level+1; $i <= $maxlevel; $i++)
    {
	delete $LABELS[$i];
    }
}

sub get_labels_from_above
{
    my($level) = @_;
    my($res, $eid);	
    for (my $i = 0; $i <= $level; $i++)
    {
	$res .= $LABELS[$i];
    }
    return $res;
}

sub inherit_tags
{
    my($e, $toplist_tag) = @_;
    my($res, $eid);	
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$toplist_tag[ >].*?</$toplist_tag>)|&split;&fk;$1&split;|gi;    
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    my $inherit_dat = &store_tags_to_inherit($bit);
	    $bit =~ s|(</inherited-g>)|$inherit_dat$1|g;
	}
	$res .= $bit;
    }
    return $res;
}

sub store_tags_to_inherit
{
    my($e) = @_;
    undef %STORE;
    foreach my $tag_to_inherit (@TAGS_TO_INHERIT)
    {
	&store_tag_to_inherit($e, $tag_to_inherit);
    }
    my $res;
    foreach my $tag (sort keys %STORE)
    {
	$res .= $tag;
    }
    return $res;
}

sub store_tag_to_inherit
{
    my($e, $tag) = @_;
    my $newtag = $tag;
    $newtag =~ s|^ *|i_|;
    my($bit, $res);
    my(@BITS);
    $e =~ s|(<$tag[ >].*?</$tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit =~ s| e:[^ =]*=\".*?\"||gi;
	    $bit =~ s| lexid[^ =]*=\".*?\"||gi;
	    $bit =~ s| xmlns[^ =]*=\".*?\"||gi;
	    $bit = restructure::tag_rename($bit, $tag, $newtag);
	    $bit =~ s|\s+| |g;
	    $STORE{$bit} = 1;
	}
    }    
}

sub inherit_tags_to_chunk
{
    my($e, $tag_to_inherit) = @_;
    my($res, $eid);
    my($bit, $res);
    my(@BITS);
    return $res;
}

sub create_inherited_groups
{
    my($e) = @_;
    my($res, $eid);	
    foreach my $target_tag (@TARGET_TAGS)
    {
	$e =~ s|(</$target_tag>)|<inherited-g ></inherited-g>$1|gi;
    }
    return $e;
}

sub rename_target_tags
{
    my($e) = @_;
    my($res, $eid);	
    $res = "";
    foreach my $target_tag (@TARGET_TAGS)
    {
	foreach my $tag_to_inherit (@TAGS_TO_INHERIT)
	{
	    my $tmp_tag = $tag_to_inherit;
	    $tmp_tag =~ s|^|TMP_|;
	    if ($e =~ m|<$target_tag[ >]|)
	    {
		$e = &rename_tags_inside_target_tags($e, $target_tag, $tag_to_inherit, $tmp_tag);
	    }
	}
    }
    return $e;
}

sub rename_tags_inside_target_tags
{
    my($e, $target_tag, $old_tag, $new_tag) = @_;
    my($res, $eid);	
    my(@BITS);
    $e =~ s|(<$target_tag[ >].*?</$target_tag>)|&split;&fk;$1&split;|gi;
    @BITS = split(/&split;/, $e);
    $res = "";
    foreach my $bit (@BITS){
	if ($bit =~ s|&fk;||gi){
	    $bit = restructure::tag_rename($bit, $old_tag, $new_tag);
	}
	$res .= $bit;
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
    while (<in_fp>){
	chomp;
	s|||g;
	# my ($eid, $info) = split(/\t/);
	# $W{$_} = 1;
    }
    close(in_fp);
} 
