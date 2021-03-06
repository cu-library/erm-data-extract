# ERM data migration

Stylesheets, etc. for migrating ERM data from Sierra to Alma.

## Licenses

Download [Saxon-HE 9.8](https://sourceforge.net/projects/saxon/files/Saxon-HE/9.8/) XSLT processor. Run XSL transform on licenses exported from Sierra as CSV data. Identify initial template (-it) to be executed on CSV data instead of matching document root.

```
java -jar ./lib/saxon9he.jar -xsl:license-csv-to-xml.xsl -it:csv2xml csv-uri="file://[path to CSV file]"
```

Processor and stylesheet tested with Oracle JDK 8. 

Validate XML files with Ex Libris schema for [ERM licenses](https://knowledge.exlibrisgroup.com/Alma/Implementation_and_Migration/Migration_Guides/ERM_to_Alma_Data_Delivery_Specification):

```
xmllint --noout --schema ERM_license.xsd *.xml
```
