echo 'perl  getDataForChecking_XML.pl  -f ../Configs/cantonese.cfg ../Cantonese/dict2.xml > TMP/dataForChecking.dat'
perl  getDataForChecking_XML.pl  -f ../Configs/cantonese.cfg ../Cantonese/dict2.xml > TMP/dataForChecking.dat
echo 'perl sensitivity_check_xml.pl -f sensitive_info.xml TMP/dataForChecking.dat | perl add_hw_trans.pl -f TranslationsForHdwdsGoogle.dat > TMP/sensitiveCantonese.dat'
perl sensitivity_check_xml.pl -f sensitive_info.xml TMP/dataForChecking.dat | perl add_hw_trans.pl -f TranslationsForHdwdsGoogle.dat > TMP/sensitiveCantonese.dat
echo 'perl  XLS_cantonese.pl -f ../Cantonese/dict2.xml -r Cantonese_sensitivity.xlsx  TMP/sensitiveCantonese.dat'
perl  XLS_cantonese.pl -f ../Cantonese/dict2.xml -r Cantonese_sensitivity.xlsx  TMP/sensitiveCantonese.dat
