perl  drop_sup_att.pl dps_elf.xml  | perl inherit_lexids.pl | perl add_priorities.pl | perl getDataForChecking_midlow.pl  -f elf.cfg  > ../TMP/dataForChecking.dat

perl caps_check_xml.pl ../TMP/dataForChecking.dat > TMP/capsELF.dat 
perl XLS_new_general_caps.pl -f dps_elf.xml -r ELF_caps_midlow.xlsx TMP/capsELF.dat > junk.res
