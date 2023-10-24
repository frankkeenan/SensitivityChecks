echo "perl  drop_sup_att.pl dps_elf.xml | getDataForChecking_XML.pl  -f ../Configs/oxbi_enxx.cfg  > TMP/dataForChecking.dat"
perl  drop_sup_att.pl dps_elf.xml | perl getDataForChecking_XML.pl  -f ../Configs/oxbi_enxx.cfg  > TMP/dataForChecking.dat

echo "perl sensitivity_check_new.pl -x ../data/exclusions.dat -f SensitiveInfoWithFreqs.xml TMP/dataForChecking.dat > TMP/sensitiveELF.dat"
perl sensitivity_check_new.pl -x ../data/exclusions.dat -f SensitiveInfoWithFreqs.xml TMP/dataForChecking.dat > TMP/sensitiveELF.dat

echo "perl  XLS_new.pl -f dps_elf.xml -r ELF_sensitivity.xlsx  TMP/sensitiveELF.dat > junk.txt"
perl  XLS_new.pl -f dps_elf.xml -r ELF_sensitivity_sup.xlsx  TMP/sensitiveELF.dat > junk.txt

