#!/usr/local/bin/perl
use Getopt::Std;
use autodie qw(:all);
use open qw(:std :utf8);
use utf8;
use strict;
our ($LOG, $LOAD, $opt_f, $opt_u, $opt_D, $opt_I, $opt_O, $PDIR, %W, %USED, %F, %INFO);
#$PDIR = ".";
$PDIR = "/usr/local/bin/";

require "$PDIR/utils.pl";
require "$PDIR/restructure.pl";

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
  line:    
    while (<>){
	chomp;       # strip record separator
	s|||g;
	if ($opt_I){printf(bugin_fp "%s\n", $_);}	
	# s|<!--.*?-->||gio;
	#	next line if (m|<entry[^>]*sup=\"y|io);
	#	unless (m|<entry|){print $_; next line;}
	# my $h = &get_hex_h($_, "hex", 1); # the 1 says to remove stress etc
	# $eid = &get_tag_attval($_, "entry", "eid");
	# $EntryId = &get_dps_entry_id($_);
	# $_ = &reduce_idmids($_);
	# s|£|&\#x00A3;|g;
        # $_ = restructure::delabel($_);	
	# my $tagname = restructure::get_tagname($bit);    
	s|丟|<FK>丟</FK>|g;
	s|丟那媽|<FK>丟那媽</FK>|g;
	s|仆街|<FK>仆街</FK>|g;
	s|仆街死!|<FK>仆街死!</FK>|g;
	s|你老母|<FK>你老母</FK>|g;
	s|做架兩|<FK>做架兩</FK>|g;
	s|做鴨|<FK>做鴨</FK>|g;
	s|冚家拎|<FK>冚家拎</FK>|g;
	s|出嘢|<FK>出嘢</FK>|g;
	s|出火|<FK>出火</FK>|g;
	s|叫雞|<FK>叫雞</FK>|g;
	s|叫鴨|<FK>叫鴨</FK>|g;
	s|叫鴨仔|<FK>叫鴨仔</FK>|g;
	s|同志鴨|<FK>同志鴨</FK>|g;
	s|含𨶙|<FK>含𨶙</FK>|g;
	s|含𨶙啦你|<FK>含𨶙啦你</FK>|g;
	s|吹喇叭|<FK>吹喇叭</FK>|g;
	s|吹簫|<FK>吹簫</FK>|g;
	s|唔好咁𨶙串|<FK>唔好咁𨶙串</FK>|g;
	s|喼汁|<FK>喼汁</FK>|g;
	s|基|<FK>基</FK>|g;
	s|基仔|<FK>基仔</FK>|g;
	s|基佬|<FK>基佬</FK>|g;
	s|基吧|<FK>基吧</FK>|g;
	s|基基哋|<FK>基基哋</FK>|g;
	s|基場|<FK>基場</FK>|g;
	s|基民|<FK>基民</FK>|g;
	s|基鴨|<FK>基鴨</FK>|g;
	s|好閪|<FK>好閪</FK>|g;
	s|好𨳊|<FK>好𨳊</FK>|g;
	s|好𨳊𨳍|<FK>好𨳊𨳍</FK>|g;
	s|好𨳍|<FK>好𨳍</FK>|g;
	s|好𨶙戇𨳊|<FK>好𨶙戇𨳊</FK>|g;
	s|好𨶙閪|<FK>好𨶙閪</FK>|g;
	s|好𨶙𨳊|<FK>好𨶙𨳊</FK>|g;
	s|好𨶙𨳍|<FK>好𨶙𨳍</FK>|g;
	s|妖那媽|<FK>妖那媽</FK>|g;
	s|屌那媽|<FK>屌那媽</FK>|g;
	s|戇𨳊|<FK>戇𨳊</FK>|g;
	s|戇𨳊仔|<FK>戇𨳊仔</FK>|g;
	s|戇𨳊𨳊|<FK>戇𨳊𨳊</FK>|g;
	s|戇𨶙|<FK>戇𨶙</FK>|g;
	s|戇𨶙𨳊|<FK>戇𨶙𨳊</FK>|g;
	s|扑|<FK>扑</FK>|g;
	s|扑一鑊|<FK>扑一鑊</FK>|g;
	s|扑嘢|<FK>扑嘢</FK>|g;
	s|扑濕|<FK>扑濕</FK>|g;
	s|打我飛機|<FK>打我飛機</FK>|g;
	s|打飛機|<FK>打飛機</FK>|g;
	s|扯旗|<FK>扯旗</FK>|g;
	s|扯晒旗|<FK>扯晒旗</FK>|g;
	s|扯爆旗|<FK>扯爆旗</FK>|g;
	s|扯硬|<FK>扯硬</FK>|g;
	s|把𨶙|<FK>把𨶙</FK>|g;
	s|把𨶙咩|<FK>把𨶙咩</FK>|g;
	s|挑|<FK>挑</FK>|g;
	s|挑那媽|<FK>挑那媽</FK>|g;
	s|挑那星|<FK>挑那星</FK>|g;
	s|插|<FK>插</FK>|g;
	s|支那人|<FK>支那人</FK>|g;
	s|支那蝗蟲|<FK>支那蝗蟲</FK>|g;
	s|放屁|<FK>放屁</FK>|g;
	s|朘朘仔|<FK>朘朘仔</FK>|g;
	s|死蠢閪|<FK>死蠢閪</FK>|g;
	s|碌𨳊|<FK>碌𨳊</FK>|g;
	s|老同|<FK>老同</FK>|g;
	s|老閪|<FK>老閪</FK>|g;
	s|臭閪|<FK>臭閪</FK>|g;
	s|蝗話|<FK>蝗話</FK>|g;
	s|話𨶙之|<FK>話𨶙之</FK>|g;
	s|閪|<FK>閪</FK>|g;
	s|閪人|<FK>閪人</FK>|g;
	s|閪冧|<FK>閪冧</FK>|g;
	s|閪毛|<FK>閪毛</FK>|g;
	s|閪水|<FK>閪水</FK>|g;
	s|閪罅|<FK>閪罅</FK>|g;
	s|閪面|<FK>閪面</FK>|g;
	s|阿三|<FK>阿三</FK>|g;
	s|雞|<FK>雞</FK>|g;
	s|𡲢|<FK>𡲢</FK>|g;
	s|𦧺屎𦡆|<FK>𦧺屎𦡆</FK>|g;
	s|𦧺閪|<FK>𦧺閪</FK>|g;
	s|𨳊|<FK>𨳊</FK>|g;
	s|𨳊毛|<FK>𨳊毛</FK>|g;
	s|𨳊頭|<FK>𨳊頭</FK>|g;
	s|𨳍|<FK>𨳍</FK>|g;
	s|𨳍毛|<FK>𨳍毛</FK>|g;
	s|𨳍頭|<FK>𨳍頭</FK>|g;
	s|𨳍頭皮|<FK>𨳍頭皮</FK>|g;
	s|𨳒|<FK>𨳒</FK>|g;
	s|𨳒你|<FK>𨳒你</FK>|g;
	s|𨳒你老味!|<FK>𨳒你老味!</FK>|g;
	s|𨳒你老母!|<FK>𨳒你老母!</FK>|g;
	s|𨳒你老母臭化閪|<FK>𨳒你老母臭化閪</FK>|g;
	s|𨳒你老母臭閪!|<FK>𨳒你老母臭閪!</FK>|g;
	s|𨳒你老豆|<FK>𨳒你老豆</FK>|g;
	s|𨳒佢|<FK>𨳒佢</FK>|g;
	s|𨳒佢老母|<FK>𨳒佢老母</FK>|g;
	s|𨳒那媽|<FK>𨳒那媽</FK>|g;
	s|𨳒那星|<FK>𨳒那星</FK>|g;
	s|𨳒開!|<FK>𨳒開!</FK>|g;
	s|𨳒閪|<FK>𨳒閪</FK>|g;
	s|𨳒𨳊人|<FK>𨳒𨳊人</FK>|g;
	s|𨳒𨳊你|<FK>𨳒𨳊你</FK>|g;
	s|𨳒𨳊佢|<FK>𨳒𨳊佢</FK>|g;
	s|𨳒𨳊我|<FK>𨳒𨳊我</FK>|g;
	s|𨳒𨳍人|<FK>𨳒𨳍人</FK>|g;
	s|𨳒𨳍你|<FK>𨳒𨳍你</FK>|g;
	s|𨳒𨳍佢|<FK>𨳒𨳍佢</FK>|g;
	s|𨳒𨳍我|<FK>𨳒𨳍我</FK>|g;
	s|𨳒𨶙你|<FK>𨳒𨶙你</FK>|g;
	s|𨶙|<FK>𨶙</FK>|g;
	s|𨶙樣|<FK>𨶙樣</FK>|g;
	s|𨶙蛋|<FK>𨶙蛋</FK>|g;
	s|𫵱|<FK>𫵱</FK>|g;
	print $_;
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
	# $INFO{$eid} = $info;
    }
    close(in_fp);
} 
