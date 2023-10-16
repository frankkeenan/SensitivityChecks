echo "perl  getDataForChecking_XML.pl  -f ../Configs/oxbi_enxx.cfg  dps_elf.xml > TMP/dataForChecking.dat"
perl  getDataForChecking_XML.pl  -f ../Configs/oxbi_enxx.cfg  dps_elf.xml > TMP/dataForChecking.dat

echo "perl sensitivity_check_xml.pl -f sensitive_info.xml TMP/dataForChecking.dat > TMP/sensitiveELF.dat"
perl sensitivity_check_xml.pl -f sensitive_info.xml TMP/dataForChecking.dat > TMP/sensitiveELF.dat

echo "perl  XLS_elf.pl -f dps_elf.xml -r ELF_sensitivity.xlsx  TMP/sensitiveELF.dat"
perl  XLS_elf.pl -f dps_elf.xml -r ELF_sensitivity.xlsx  TMP/sensitiveELF.dat

