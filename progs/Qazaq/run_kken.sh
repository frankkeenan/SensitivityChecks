perl getDataForChecking_XML.pl  -f spell_kk_en.cfg dps_kken.xml > TMP/dataForChecking.dat
perl sensitivity_check_new.pl -x exclusions.dat -f SensitiveInfoWithFreqs.xml TMP/dataForChecking.dat | perl add_hw_trans.pl -f DTRANS.dat > TMP/sensitive_kken.dat
perl  XLS_lexml2_hwts.pl -f dps_kken.xml -r KKEN_English_sensitivity.xlsx  TMP/sensitive_kken.dat > junk.txt

