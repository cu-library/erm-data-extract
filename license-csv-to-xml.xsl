<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="fn" 
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">

    <xsl:output indent="yes"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:param name="csv-encoding" as="xs:string" select="'iso-8859-1'"/>
    <xsl:param name="csv-uri" as="xs:string"/>
    
    <!-- 
        CSV parser from Andrew Welch
        http://andrewjwelch.com/code/xslt/csv/csv-to-xml_v2.html
    -->
    <xsl:function name="fn:getTokens" as="xs:string+">
        <xsl:param name="str" as="xs:string" />
        <xsl:analyze-string select="concat($str, ',')" regex='(("[^"]*")+|[^,]*),'>
            <xsl:matching-substring>
                <xsl:sequence select='replace(regex-group(1), "^""|""$|("")""", "$1")' />
            </xsl:matching-substring>
        </xsl:analyze-string>
    </xsl:function>    
    
    <!-- 
        CSV fields. Function tokenize() returns 1-based list.
        All fields exported from License record except where noted.
        All field names the same as in Sierra except where noted.
        
        1. license_id           (License: Record #)
        2. eresource_id         (Eresource: Record #)
        3. eresource_name       (Eresource
        4. status
        5. licensor_sign_date
        6. contract_start_date
        7. contract_end_date
        8. access_provider      (Eresource)
        9. confidential
        10. auto_renew
        11. breach_cure
        12. perpetual_access
        13. disability_compliance
        14. law_and_venue
        15. concurrent_users
        16. archival_provisions
        17. authentication_method
        18. authorized_users
        19. url
        20. license_code_1
        21. notice_requirement
        22. special_terms
        23. terms_of_use_patron
        24. terms_of_use_staff
        25. terms_of_use_notes_patron
        26. terms_of_use_notes_staff
        27. suppression
        28. type
        29. license_notes
    -->
    <xsl:template match="/" name="csv2xml">
        <xsl:choose>
            <xsl:when test="unparsed-text-available($csv-uri, $csv-encoding)">
                <xsl:variable name="csv" select="unparsed-text($csv-uri, $csv-encoding)"/>
                
                <!-- Define delimiter to split multi-value fields -->
                <xsl:variable name="multi_delimiter">";"</xsl:variable>
                
                <!--Get Header-->
                <xsl:variable name="header-tokens" as="xs:string*">
                    <xsl:analyze-string select="$csv" regex="\r\n?|\n">
                        <xsl:non-matching-substring>
                            <xsl:if test="position() = 1">
                                <xsl:copy-of select='tokenize(., ",")'/>
                            </xsl:if>
                        </xsl:non-matching-substring>
                    </xsl:analyze-string>
                </xsl:variable>
                
                <!-- Process CSV row -->
                <xsl:analyze-string select="$csv" regex="\r\n?|\n">
                    <xsl:non-matching-substring>
                        <xsl:if test="not(position() = 1)">
                            <xsl:variable name="tokens" as="xs:string*" select="fn:getTokens(.)" />
                            
                            <!-- remove delimiters on numeric & text fields -->
                            <xsl:variable name="license_id" select="$tokens[1]"/>
                            <xsl:variable name="eresource_id" select="$tokens[2]"/>
                            <xsl:variable name="eresource_name" select="$tokens[3]"/>

                            <!-- License status: map Sierra code to text -->
                            <xsl:variable name="license_status">
                                <xsl:call-template name="map-license-status">
                                    <xsl:with-param name="license_status" select="$tokens[4]"/>
                                </xsl:call-template>    
                            </xsl:variable> 
                            
                            <!-- reformat Sierra dates -->
                            <xsl:variable name="signed_on">
                                <xsl:call-template name="reformat-date">
                                    <xsl:with-param name="date_string" select="$tokens[5]"/>
                                </xsl:call-template>                                
                            </xsl:variable>
                            <xsl:variable name="start_date">
                                <xsl:call-template name="reformat-date">
                                    <xsl:with-param name="date_string" select="$tokens[6]"/>
                                </xsl:call-template>                                
                            </xsl:variable>
                            <xsl:variable name="end_date">
                                <xsl:call-template name="reformat-date">
                                    <xsl:with-param name="date_string" select="$tokens[7]"/>
                                </xsl:call-template>                                
                            </xsl:variable>
                            
                            <!-- licensor code: links to vendor code? @todo ask Ex Libris --> 
                            <xsl:variable name="access_provider" select="$tokens[8]"/>
                            
                            
                            <!-- Confidential? Map Sierra code to text -->
                            <xsl:variable name="confidential">
                                <xsl:call-template name="map-confidential">
                                    <xsl:with-param name="conf_code" select="$tokens[9]"/>
                                </xsl:call-template>                                
                            </xsl:variable>
                            
                            <!-- Auto-renew? Map Sierra code to yes / no --> 
                            <xsl:variable name="auto-renew">
                                <xsl:call-template name="map-yn">
                                    <xsl:with-param name="yn_code" select="$tokens[10]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- Breach cure: number of days -->
                            <xsl:variable name="breach_cure" select="$tokens[11]"/>
                            
                            <!-- Perpetual access? Map Sierra code to yes / no -->
                            <xsl:variable name="perpetual_access">
                                <xsl:call-template name="map-yn">
                                    <xsl:with-param name="yn_code" select="$tokens[12]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- Disability compliance? Map Sierra code to yes / no -->
                            <xsl:variable name="accessibility">
                                <xsl:call-template name="map-yn">
                                    <xsl:with-param name="yn_code" select="$tokens[13]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- Law and venue? Map Sierra code to text -->
                            <xsl:variable name="law_venue">
                                <xsl:call-template name="map-law-venue">
                                    <xsl:with-param name="venue_code" select="$tokens[14]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- Concurrent users? Number of users -->
                            <xsl:variable name="concurrent_users" select="$tokens[15]"/>
                            
                            <!-- Archival provisions? Map Sierra code to yes / no -->
                            <xsl:variable name="archive">
                                <xsl:call-template name="map-yn">
                                    <xsl:with-param name="yn_code" select="$tokens[16]"/>
                                </xsl:call-template>
                            </xsl:variable>
                                              
                            <!-- Authentication method? May be a multi-value field. -->
                            <xsl:variable name="auth_method" select="replace($tokens[17], $multi_delimiter, '. ')"/>
                            
                            <!-- Authorized users definition. Single text value. May contain quotes. -->
                            <xsl:variable name="auth_users" select="$tokens[18]"/>
                            
                            <!-- License URL. May contain notes. May be multi-value -->
                            <xsl:variable name="license_url" select="replace($tokens[19], $multi_delimiter, ' ')"/> 
                                
                            <!-- Alumni access permitted? Map Sierra code to text -->
                            <xsl:variable name="alumni_access">
                                <xsl:call-template name="map-alumni-access">
                                    <xsl:with-param name="alumni_code" select="$tokens[20]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- Notice requirement -->
                            <xsl:variable name="notice_requirement" select="$tokens[21]"/>
                            
                            <!-- Special terms? May be multi-value. Add a note for each entry. -->
                            <xsl:variable name="special_terms" select="$tokens[22]"/> 
                            
                            <!-- Terms of use (patron). May be multi-value. Add a term for each entry. -->
                            <xsl:variable name="patron_terms" select="$tokens[23]"/>
                            
                            <!-- Terms of use (staff). May be multi-value. Add a note for each entry. -->
                            <xsl:variable name="staff_terms" select="$tokens[24]"/>
                            
                            <!-- Terms of use notes (patron). May be multi-value. Add a term for each entry -->
                            <xsl:variable name="patron_terms_note" select="$tokens[25]"/>
                            
                            <!-- Terms of use notes (staff). May be multi-value. Add a note for each entry -->
                            <xsl:variable name="staff_terms_note" select="$tokens[26]"/>
                            
                            <!-- Suppress license? Map Sierra code to text-->
                            <xsl:variable name="suppress">
                                <xsl:call-template name="map-suppression">
                                    <xsl:with-param name="suppress_code" select="$tokens[27]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- License type? Map Sierra code to text -->
                            <xsl:variable name="license_type">
                                <xsl:call-template name="map-license-type">
                                    <xsl:with-param name="license_type_code" select="$tokens[28]"/>
                                </xsl:call-template>
                            </xsl:variable>
                            
                            <!-- License notes? May be multi-value. Add a note for each entry. -->
                            <xsl:variable name="license_notes" select="$tokens[29]"/>
                            
                            <!-- create license file -->
                            <xsl:result-document method="xml" href="{$license_id}.xml">
                                <license xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                                        xsi:schemaLocation="http://com/exlibris/urm/repository/migration/license/xmlbeans ERM_license.xsd"
                                        xmlns="http://com/exlibris/urm/repository/migration/license/xmlbeans">
                                    <license_details>
                                        <license_code><xsl:value-of select="$license_id"/></license_code>
                                        <license_name><xsl:value-of select="$eresource_name"/></license_name>
                                        <license_status><xsl:value-of select="$license_status"/></license_status>
                                        
                                        <!-- @todo check with David, Pam on review status. -->
                                        <review_status>ACCEPTED</review_status>
                                        
                                        <!-- @todo check with David, Pam on licensor code: access provider? or data provider? Value is required so prefer 'none' to blank or hyphens -->
                                        <licensor_code><xsl:value-of select="$access_provider"/></licensor_code>
                                        
                                        <!-- Blank date elements are not permitted -->
                                        <xsl:if test="$signed_on!=''">
                                            <signed_on><xsl:value-of select="$signed_on"/></signed_on>
                                        </xsl:if>
                                        <!-- start_date is required. If not present, add valid but nonsensical date for later review -->                                        
                                        <start_date>
                                            <xsl:choose>
                                                <xsl:when test="$start_date!=''"><xsl:value-of select="$start_date"/></xsl:when>
                                                <xsl:otherwise>19000101</xsl:otherwise>
                                            </xsl:choose>
                                        </start_date>
                                        <xsl:if test="$end_date!=''">
                                            <end_date><xsl:value-of select="$end_date"/></end_date>
                                        </xsl:if>
                                        
                                        <!-- @todo check with Pam and David on options: LICENSE, ADDENDUM, NEGOTIATION -->
                                        <type>LICENSE</type>
                                        <ownered_entity>
                                            <created_by>Sierra ERM to Alma migration</created_by>
                                        </ownered_entity>
                                    </license_details>
                                    
                                    <!-- Add terms where present -->
                                    <term_list>
                                        <!-- Confidential? -->
                                        <xsl:if test="$confidential!=''">
                                            <term>
                                                <term_code>CONFA</term_code>
                                                <term_value><xsl:value-of select="$confidential"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Breach cure? -->
                                        <xsl:if test="$breach_cure!=''">
                                            <term>
                                                <term_code>CUREBREACH</term_code>
                                                <term_value><xsl:value-of select="$breach_cure"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Perpetual access? -->
                                        <xsl:if test="$perpetual_access!=''">
                                            <term>
                                                <term_code>PERPETUAL</term_code>
                                                <term_value><xsl:value-of select="$perpetual_access"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Accessibility compliance? -->
                                        <xsl:if test="$accessibility!=''">
                                            <term>
                                                <term_code>ACCESSIBILITY</term_code>
                                                <term_value><xsl:value-of select="$accessibility"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Law and venue? -->
                                        <xsl:if test="$law_venue!=''">
                                            <term>
                                                <term_code>GOVLAW</term_code>
                                                <term_value><xsl:value-of select="$law_venue"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Number of concurrent users? -->
                                        <xsl:if test="$concurrent_users!=''">
                                            <term>
                                                <term_code>CONCURUSER</term_code>
                                                <term_value><xsl:value-of select="$concurrent_users"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Archival provision? -->
                                        <xsl:if test="$archive!=''">
                                            <term>
                                                <term_code>ARCHIVE</term_code>
                                                <term_value><xsl:value-of select="$archive"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Authorized users? -->
                                        <xsl:if test="$auth_users!=''">
                                            <term>
                                                <term_code>AUTHUSERDEF</term_code>
                                                <term_value><xsl:value-of select="$auth_users"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- License URL? -->
                                        <xsl:if test="$license_url!=''">
                                            <term>
                                                <term_code>ELECLINKNOTE</term_code>
                                                <term_value><xsl:value-of select="$license_url"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Alumni access permitted? -->
                                        <xsl:if test="$alumni_access!=''">
                                            <term>
                                                <term_code>LAUTHUSERDEF</term_code>
                                                <term_value><xsl:value-of select="$alumni_access"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- Notice requirement? -->
                                        <xsl:if test="$notice_requirement!=''">
                                            <term>
                                                <term_code>LORNOTICE</term_code>
                                                <term_value><xsl:value-of select="$notice_requirement"/></term_value>
                                            </term>
                                        </xsl:if>
                                        <!-- 
                                            Patron terms of use, or patron terms of use notes? Add a note for each 
                                            entry in either of these fields 
                                         -->
                                        <xsl:if test="$patron_terms!=''">
                                            <xsl:for-each select="tokenize($patron_terms, $multi_delimiter)">
                                                <term>
                                                    <term_code>OTHERUSERSTRN</term_code>
                                                    <term_value>Terms of Use (Patrons): <xsl:value-of select="."/></term_value>
                                                </term>                                                
                                            </xsl:for-each>
                                        </xsl:if>
                                        <xsl:if test="$patron_terms_note!=''">
                                            <xsl:for-each select="tokenize($patron_terms_note, $multi_delimiter)">
                                                <term>
                                                    <term_code>OTHERUSERSTRN</term_code>
                                                    <term_value>Terms of Use Notes (Patrons): <xsl:value-of select="."/></term_value>
                                                </term>                                                
                                            </xsl:for-each>
                                        </xsl:if>
                                    </term_list>
                                    
                                    <!-- Add notes where present -->
                                    <note_list>
                                        <!-- License type? -->
                                        <xsl:if test="$license_type!=''">
                                            <xsl:call-template name="generate-note">
                                                <xsl:with-param name="note" select="concat('License type: ', $license_type)"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                        
                                        <!-- License notes? May be multi-value. Add a note for each entry. -->
                                        <xsl:if test="$license_notes!=''">
                                            <xsl:for-each select="tokenize($license_notes, $multi_delimiter)">
                                                <xsl:call-template name="generate-note">
                                                    <xsl:with-param name="note" select="concat('License notes: ', .)"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </xsl:if>
                                       
                                        <!-- Suppress license? -->
                                        <xsl:if test="$suppress!=''">
                                            <xsl:call-template name="generate-note">
                                                <xsl:with-param name="note" select="concat('License suppressed: ', $suppress)"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                        
                                        <!-- Authentication method? -->
                                        <xsl:if test="$auth_method!=''">
                                            <xsl:call-template name="generate-note">
                                                <xsl:with-param name="note" select='concat("Authentication method: ", $auth_method)'/>
                                            </xsl:call-template>
                                        </xsl:if>
                                        
                                        <!-- Auto-renew? -->
                                        <xsl:if test="$auto-renew!=''">
                                            <xsl:call-template name="generate-note">
                                                <xsl:with-param name="note" select="concat('Auto-renew: ', $auto-renew)"/>
                                            </xsl:call-template>
                                        </xsl:if>
                                        
                                        <!-- Terms of use (staff) and Terms of use notes (Staff). Add a note for each entry. -->
                                        <xsl:if test="$staff_terms!=''">
                                            <xsl:for-each select="tokenize($staff_terms, $multi_delimiter)">
                                                <xsl:call-template name="generate-note">
                                                    <xsl:with-param name="note" select="concat('Terms of Use (Staff): ', .)"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </xsl:if>
                                        <xsl:if test="$staff_terms_note!=''">
                                            <xsl:for-each select="tokenize($staff_terms_note, $multi_delimiter)">
                                                <xsl:call-template name="generate-note">
                                                    <xsl:with-param name="note" select="concat('Terms of Use Notes (Staff): ', .)"/>
                                                </xsl:call-template>
                                            </xsl:for-each>
                                        </xsl:if>
                                        
                                        <!-- Special terms? May be multi-value. Add a note for each entry. -->
                                        <xsl:if test="$special_terms!=''">
                                            <xsl:for-each select="tokenize($special_terms, $multi_delimiter)">
                                                <xsl:call-template name="generate-note">
                                                    <xsl:with-param name="note" select="concat('Special terms: ', .)"/>
                                                </xsl:call-template>
                                            </xsl:for-each>                                            
                                        </xsl:if>          
                                        
                                    </note_list>                                    
                                </license>
                            </xsl:result-document>
                        </xsl:if>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="error">
                    <xsl:text>Error reading "</xsl:text>
                    <xsl:value-of select="$csv-uri"/>
                    <xsl:text>" (encoding "</xsl:text>
                    <xsl:value-of select="$csv-encoding"/>
                    <xsl:text>").</xsl:text>
                </xsl:variable>
                <xsl:message>
                    <xsl:value-of select="$error"/>
                </xsl:message>
                <xsl:value-of select="$error"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Named templates -->
    
    <xsl:template name="map-license-status">
        <xsl:param name="license_status"/>
        <xsl:choose>
            <xsl:when test="$license_status='-'">ACTIVE</xsl:when>
            <xsl:when test="$license_status='n'">DRAFT</xsl:when>
            <xsl:when test="$license_status='e'">EXPIRED</xsl:when>
            <xsl:when test="$license_status='u'">ACTIVE</xsl:when>
            <!-- @todo check with Pam on default status -->
            <xsl:otherwise>ACTIVE</xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="map-confidential">
        <xsl:param name="conf_code"/>
        <xsl:choose>
            <xsl:when test="$conf_code='c'">All confidential</xsl:when>
            <xsl:when test="$conf_code='n'">No</xsl:when>
            <xsl:when test="$conf_code='p'">Price only</xsl:when>
            <!-- If code is Sierra default '-' (blank), or 'u' (Unknown), do not map. -->            
            <!-- If code is not present, do not map. -->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="map-law-venue">
        <xsl:param name="venue_code"/>
        <xsl:choose>
            <xsl:when test="$venue_code='c'">Canada</xsl:when>
            <xsl:when test="$venue_code='n'">Ontario</xsl:when>
            <xsl:when test="$venue_code='o'">Other</xsl:when>
            <!-- If code is Sierra default '-' (blank), or 'u' (Unknown), do not map. -->            
            <!-- If code is not present, do not map. -->                      
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="map-alumni-access">
        <xsl:param name="alumni_code"/>
        <xsl:choose>
            <xsl:when test="$alumni_code='1'">Alumni access: no</xsl:when>
            <xsl:when test="$alumni_code='2'">Alumni access: yes</xsl:when>
            <!-- If code is Sierra default '-' (blank), or not present, do not map. -->            
        </xsl:choose>
    </xsl:template>

    <xsl:template name="map-suppression">
        <xsl:param name="suppress_code"/>
        <!-- Display in OPAC = 'n' = License suppressed -->
        <xsl:if test="$suppress_code='n'">yes</xsl:if>
        <!-- no other cases need to be handled: only included if license suppressed -->
    </xsl:template>
    
    <xsl:template name="map-license-type">
        <xsl:param name="license_type_code"/>
        <xsl:choose>
            <xsl:when test="'c'">Consortium</xsl:when>
            <xsl:when test="'s'">Site license</xsl:when>
            <xsl:when test="'x'">Clickthru</xsl:when>
            <xsl:when test="'y'">Shrinkwrap</xsl:when>
            <!-- If code is Sierra default '-' (blank), or 'u' (Unknown), do not map. -->            
            <!-- If code is not present, do not map. -->
        </xsl:choose>
    </xsl:template>
    
    <xsl:template name="map-yn">
        <xsl:param name="yn_code"/>
        <xsl:choose>
            <xsl:when test="$yn_code='y'">Yes</xsl:when>
            <xsl:when test="$yn_code='n'">No</xsl:when>
            <!-- If code is Sierra default '-' (blank), or 'u' (Unknown), do not map. -->            
            <!-- If code is not present, do not map. -->
        </xsl:choose>        
    </xsl:template>
    
    <xsl:template name="generate-note" xmlns="http://com/exlibris/urm/repository/migration/license/xmlbeans">
        <xsl:param name="note"/>
        <note>
            <ownered_entity>
                <created_by>Sierra ERM to Alma migration</created_by>
            </ownered_entity>
            <content><xsl:value-of select="$note"/></content>
        </note>
    </xsl:template>
    
    <xsl:template name="reformat-date">
        <xsl:param name="date_string"/>
        <xsl:if test="$date_string!=''">
            <xsl:variable name="date_tokens" as="xs:string*" select="tokenize($date_string, '-')"/>
            <!-- get date segments -->
            <xsl:variable name="dd" select="$date_tokens[1]"/>
            <xsl:variable name="mm" select="$date_tokens[2]"/>
            <xsl:variable name="yyyy" select="$date_tokens[3]"/>
            <!-- rebuild date format -->
            <xsl:value-of select="concat($yyyy,$mm,$dd)"/>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>
