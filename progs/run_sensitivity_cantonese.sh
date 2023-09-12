echo 'perl  getDataForChecking.pl  -f Configs/elt.cfg OAAD/dps.xml > TMP/dataForChecking.dat'
#perl  getDataForChecking.pl  -f Configs/elt.cfg jdps.xml > TMP/dataForChecking.dat
perl  getDataForChecking.pl  -f Configs/elt.cfg OAAD/dps.xml > TMP/dataForChecking.dat
echo 'perl sensitivity_check.pl -f englishSensitiveSmaller.xml TMP/dataForChecking.dat > TMP/sensitiveOAAD.dat'
perl sensitivity_check.pl -f englishSensitiveSmaller.xml TMP/dataForChecking.dat > TMP/sensitiveOAAD.dat
echo 'perl  XLS.pl -r OAAD_sensitivity.xlsx  TMP/sensitiveOAAD.dat'
perl  XLS.pl -r OAAD_sensitivity.xlsx  TMP/sensitiveOAAD.dat
#perl get_src_context.pl -f ENG/en_gr_sensitive.dat en_gr.xml > get_src_context.pl.engr
#perl add_context.pl -f get_src_context.pl.engr ENG/en_gr_sensitive.dat > ENG/en_gr_sensitive_context.dat
