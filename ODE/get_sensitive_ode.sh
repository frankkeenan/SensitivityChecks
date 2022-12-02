perl get_sensitive_items.pl dps.xml | perl replace_morphology.pl -f wordforms.dat | perl red.pl > dps_sensitive_infls.xml
perl  get_sensitive_xlsx.pl -P -r ode_noad_sensitivity_info_non_genperson.xlsx dps_sensitive_infls.xml | perl inflect.pl > ode_noad_sensitivity_info_non_genperson.xml
# This creates ode_noad_sensitivity_info_non_genperson_classes.xlsx
# The editor can then edit this to remove any info they don't want
# Get the tagged version of that selection with:
perl ~/perl/xlsx2xml.pl -f ode_noad_sensitivity_info_non_genperson_classes.xlsx | perl ~/perl/name_cols.pl > selection.xml
# Now use this info to generate the XML data that will feed the sensitivity checking
perl  get_selection_vocab.pl -f selection.xml ode_noad_sensitivity_info_non_genperson.xml > sensitive_vocab_info.dat
