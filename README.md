# ERM data migration

Stylesheets, etc. for migrating ERM data from Sierra to Alma.

## Licenses

Download [Saxon-HE 9.8](https://sourceforge.net/projects/saxon/files/Saxon-HE/9.8/) XSLT processor. Transform licenses exported from Sierra as CSV data:

java -jar ./lib/saxon9he.jar -xsl:license-csv-to-xml.xsl -s:test.xml

Processor and stylesheet tested with Java 8. Validate XML files with Ex Libris schema [ERM licenses](https://knowledge.exlibrisgroup.com/Alma/Implementation_and_Migration/Migration_Guides/ERM_to_Alma_Data_Delivery_Specification):

xmllint --noout --schema ERM_license.xsd \*.xml
