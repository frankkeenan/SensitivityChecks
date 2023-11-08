perl getDataForChecking_XML.pl  -f spell_en_kk.cfg dps_enkk.xml > TMP/dataForChecking.dat
perl sensitivity_check_new.pl -x exclusions.dat -f SensitiveInfoWithFreqs.xml TMP/dataForChecking.dat > TMP/sensitive_enkk.dat
perl  XLS_lexml2.pl -f dps_enkk.xml -r ENKK_English_sensitivity.xlsx  TMP/sensitive_enkk.dat > junk.txt

