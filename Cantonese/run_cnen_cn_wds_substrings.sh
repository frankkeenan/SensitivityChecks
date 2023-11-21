cat $0
perl pre_cn.pl   yue_en_lexml2_dict_inline_supx.xml | perl getDataForSensitivityChecking.pl  -f cantonese_cn.cfg > TMP/dataForChecking.dat
perl get_trans.pl yue_en_lexml2_dict_inline_supx.xml > get_trans.pl.res
perl sensitivity_check_cn_substring.pl -f SensitiveInfoWithFreqs_cantonese.xml TMP/dataForChecking.dat | perl add_context_trans.pl -f get_trans.pl.res  > TMP/sensitiveCn.dat
perl  XLS_cn.pl -f yue_en_lexml2_dict_inline_supx.xml -r sensitivity_yue_en.xlsx  TMP/sensitiveCn.dat > junk.txt

