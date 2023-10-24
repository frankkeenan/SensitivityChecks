cat run_caps_elf.sh
perl  drop_sup_att.pl dps_elf.xml | perl getDataForChecking_XML.pl  -f ../Configs/oxbi_enxx.cfg  > TMP/dataForChecking.dat

perl caps_check_xml.pl TMP/dataForChecking.dat > TMP/capsELF.dat

perl  XLS_new_general.pl -f caps_elf.xml -r ELF_caps.xlsx  TMP/capsELF.dat > junk.res

