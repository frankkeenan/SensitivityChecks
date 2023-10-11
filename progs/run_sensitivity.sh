perl getDataForChecking.pl -f Configs/oxbi_enxx.cfg /data/data_c/Projects/OL/B-EN-IT-00001/dps.xml > en_it_check.dat
perl  sensitivity_check_interchange.pl  -c B-EN-IT-00001 -s /data/data_c/Projects/OL/B-EN-IT-00001/dps.xml -f sensitive_vocab_info.dat en_it_check.dat > sensitivity_check_B-EN-IT-00001.xml
