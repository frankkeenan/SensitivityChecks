cat run_elf_midlow.sh
perl  drop_sup_att.pl dps_elf.xml  | perl inherit_lexids.pl | perl add_priorities.pl | perl getDataForChecking_midlow.pl  -f elf.cfg  > ../TMP/dataForChecking.dat

perl sensitivity_check_new.pl -x ./exclusions.dat -f SensitiveInfoWithFreqs.xml ../TMP/dataForChecking.dat > ../TMP/sensitiveELF_midlow.dat

perl  XLS_new.pl -f dps_elf.xml -r ELF_sensitivity_midlow.xlsx  ../TMP/sensitiveELF_midlow.dat > junk.txt

