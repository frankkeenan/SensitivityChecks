perl  getDataForChecking_XML.pl  -f ../Configs/cantonese.cfg Cantonese/jdict2.xml > TMP/dataForChecking.dat
perl sensitivity_check.pl -f englishSensitiveSmaller.xml TMP/dataForChecking.dat > TMP/sensitiveCantonese.dat
perl  XLS.pl -r Cantonese_sensitivity.xlsx  TMP/sensitiveCantonese.dat
