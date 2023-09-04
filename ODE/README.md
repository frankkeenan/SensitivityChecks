The idea is to select the sensitive info directly from ODE-NOAD.

The problems are:
1. that there is too much of it and we need to be able to select
2. Structure is very dense
3. Morphology isn't in place

Firstly remove the stuff we're not interested in and add in the morphology
perl get_sensitive_items.pl dps.xml | perl replace_morphology.pl -f wordforms.dat | perl red.pl > dps_sensitive_infls.xml

Now create a spreadsheet that details the information that is in there.
This also goes into an XML file and there is a _classes SELECTION spreadsheet created which shows which sensitivity categories are available and how many items there are of them.
The selection spreadsheet is the name of the -r file with _classes appended.

perl  get_sensitive_xlsx.pl -P -r ode_noad_sensitivity_info_non_genperson.xlsx dps_sensitive_infls.xml  > ode_noad_sensitivity_info_non_genperson.xml

Here the editor can remove the sensitivity classes that are no required. This then is supplied to a program that creates the sensitivity lokup data
# This creates ode_noad_sensitivity_info_non_genperson_classes.xlsx
# The editor can then edit this to remove any info they don't want
# Get the tagged version of that selection with:
perl ~/perl/xlsx2xml.pl -f ode_noad_sensitivity_info_non_genperson_classes.xlsx | perl ~/perl/name_cols.pl > selection.xml

# Now use this info to generate the XML data that will feed the sensitivity checking
perl  get_selection_vocab.pl -f selection.xml ode_noad_sensitivity_info_non_genperson.xml > sensitive_vocab_info.dat

