cat run_cnen_cn_wds.sh
perl getDataForChecking_Cn.pl  -f cantonese_cn.cfg  yue_en_lexml2_dict_inline_supx.xml > TMP/dataForChecking.dat
perl get_trans.pl yue_en_lexml2_dict_inline_supx.xml > get_trans.pl.res
perl sensitivity_check_cn.pl -f SensitiveInfoWithFreqs_cantonese.xml TMP/dataForChecking.dat | perl add_context_trans.pl -f get_trans.pl.res  > TMP/sensitiveCn.dat
perl  XLS_cn.pl -f yue_en_lexml2_dict_inline_supx.xml -r sensitivity_yue_en.xlsx  TMP/sensitiveCn.dat > junk.txt

