perl getDataForChecking.pl -f /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/spell.cfg /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/dps.xml > /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/DataForChecking.dat
perl  sensitivity_check_interchange.pl  -c EN_MERGEDDICT_A2361_00001 -s /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/dps.xml -f sensitive_vocab_info.dat /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/DataForChecking.dat > /data/data_c/Projects/OL/EN_MERGEDDICT_A2361_00001/EN_MERGEDDICT_A2361_00001_sensitivity.xml