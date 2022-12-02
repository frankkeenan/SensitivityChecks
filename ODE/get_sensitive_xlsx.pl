#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use Excel::Writer::XLSX;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_r, $opt_u, $opt_D, $opt_I, $opt_O, @SCLASSES, %SINFO);
our ($workbook, $worksheet);
our ($unlocked, $locked, $hidden, $format1, $format2, $fmt_wrap);
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
@SCLASSES = ("derogatory", "offensive", "vulgar", "age", "crime", "disability", "ethnicity", "gendered", "geography", "other", "politics", "religion", "sex", "socioeconomic", "substance", "suicide", "trademark");
&main;

sub main
{
    getopts('uf:L:IODr:');
    &usage if ($opt_u);
    my($e, $res, $bit);
    my(@BITS);
    #   $opt_L = ""; # name of file for the log_fp output to go to
    &open_debug_files;
    use open qw(:utf8 :std);
    unless ($opt_r)
    {
	$opt_r = "ode_noad_sensitivity_info.xlsx";
    }
    if ($opt_D){binmode DB::OUT,":utf8";}

    $workbook  = Excel::Writer::XLSX->new( $opt_r );
    $worksheet = $workbook->add_worksheet();
    &do_formats;
    my $row = 0;

    my @HDR = ("Word", @SCLASSES, "Inflections", "Definition");
    $worksheet->write_row( $row++, 0, \@HDR, $format2);
#    my $hdr = join("\t", @HDR);
#    print $hdr;
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
		if ($scs =~ m|^ *$|)
		{
		    # no sensitive terms
		    next floop;
		}
		my $forms = &get_forms($bit);
		my $def = &get_def($bit);
		my $e = sprintf("%s\t%s\t%s\t%s", $hw, $scs, $forms, $def);
		my @E = split(/\t/, $e);
		$worksheet->write_row( $row++, 0, \@E);
	    }
	    $res .= $bit;
      }
	if ($opt_O){printf(bugout_fp "%s\n", $_);}
    }
    $workbook->close();
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
    my $p;
    foreach my $type (@SCLASSES)
    {
	my $sinfo = $SINFO{$type};
	$sinfo =~ s|, *$||;
	unless ($sinfo =~ m|^ *$|)
	{
	    $p = 1;
	}
	$res .= sprintf("%s£", $sinfo); 
    }
    $res =~ s|£$||;
    $res =~ s|£|\t|g;
    unless ($p)
    {
	$res = "";
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

sub do_formats
{    # Create some format objects
    $unlocked = $workbook->add_format( locked => 0 );
    $locked = $workbook->add_format( locked => 1 );
    $hidden   = $workbook->add_format( hidden => 1 );
    # Light red fill with dark red text.
    $format1 = $workbook->add_format(
	bg_color => '#E6FFFF',
	color    => '#9C0006',
	
	);
    
    # Green fill with dark green text.
    $format2 = $workbook->add_format(
	bg_color => '#C6EFCE',
	color    => '#006100',
	
	);
    $fmt_wrap = $workbook->add_format();
    $fmt_wrap->set_text_wrap();
    # Format the columns
    $worksheet->autofilter( 'A1:I9999' );
    $worksheet->freeze_panes( 1 );    # Freeze the first row
    $worksheet->set_column( 'A:A', 30, $unlocked );
    $worksheet->set_column( 'B:R', 10, $unlocked );
    $worksheet->set_column( 'S:S', 10, $unlocked );
    $worksheet->set_column( 'T:T', 10, $unlocked );
    
    #    $worksheet->autofilter( 'A1:K1' );
    #    # Protect the worksheet
    #    $worksheet->protect("", {autofilter => 1});
    #    $worksheet->protect({autofilter => 1});
    #    protectWorksheet(wb, sheet = i, protect = TRUE, password = "Password") #Protect each sheet
}
