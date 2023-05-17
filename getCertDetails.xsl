<xsl:stylesheet version="1.0" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com">
   <xsl:output method="html"/>
   <xsl:template match="/">
      <xsl:variable name="httpHeaders">
         <header name="Content-Type">application/soap+xml</header>
         <header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
      </xsl:variable>
      <xsl:variable name="xmlMgmtHost" select="'https://127.0.0.1:5550/service/mgmt/current'"/>
      <xsl:variable name="sslProfile" select="'soma-ssl'"/>
      <html>
         <body>
            <table border="1">
               <tbody align="left">
                  <tr>
                     <th>Cert Name</th>
                     <th>Serial Number</th>
                     <th>Subject</th>
                     <th>Issuer</th>
                     <th>Expiry</th>
                     <th>Domain</th>
                     <th>Crypto Cert Object</th>
                  </tr>
                  <xsl:variable name="domainStatus">
                     <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
                        <soap:Body>
                           <mgmt:request domain="default" xmlns:mgmt="http://www.datapower.com/schemas/management">
                              <mgmt:get-status class="DomainStatus"/>
                           </mgmt:request>
                        </soap:Body>
                     </soap:Envelope>
                  </xsl:variable>
                  <xsl:variable name="getDomainStatusResponse" select="dp:soap-call('https://127.0.0.1:5550/service/mgmt/current',$domainStatus/*,'soma-ssl',0,'',$httpHeaders/*)"/>
                  <xsl:for-each select="$getDomainStatusResponse//Domain">
                     <xsl:variable name="domain" select="."/>
                     <xsl:variable name="getCertNames">
                        <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
                           <soapenv:Header/>
                           <soapenv:Body>
                              <man:request domain="{$domain}">
                                 <man:get-config class="CryptoCertificate"/>
                              </man:request>
                           </soapenv:Body>
                        </soapenv:Envelope>
                     </xsl:variable>
                     <xsl:variable name="getCertNamesResponse" select="dp:soap-call('https://127.0.0.1:5550/service/mgmt/current',$getCertNames/*,'soma-ssl',0,'',$httpHeaders/*)"/>
                     <xsl:for-each select="$getCertNamesResponse//CryptoCertificate">
                        <xsl:variable name="certAlias" select="./@name"/>
                        <xsl:variable name="certFullPath" select="./Filename/text()"/>
                        <xsl:variable name="certFileName" select="substring-after($certFullPath,':///')"/>
                        <xsl:variable name="exportCryptoCert">
                           <soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                              <soapenv:Header/>
                              <soapenv:Body>
                                 <man:request domain="{$domain}">
                                    <man:do-action>
                                       <CryptoExport>
                                          <ObjectType>cert</ObjectType>
                                          <ObjectName>
                                             <xsl:value-of select="$certAlias"/>
                                          </ObjectName>
                                          <OutputFilename>
                                             <xsl:value-of select="$certFileName"/>
                                          </OutputFilename>
                                          <Mechanism/>
                                       </CryptoExport>
                                    </man:do-action>
                                 </man:request>
                              </soapenv:Body>
                           </soapenv:Envelope>
                        </xsl:variable>
                        <xsl:variable name="getExportCryptoCertResponse" select="dp:soap-call('https://127.0.0.1:5550/service/mgmt/current',$exportCryptoCert/*,'soma-ssl',0,'',$httpHeaders/*)"/>
                        <xsl:variable name="certFileName_full" select="concat('temporary:///',$certFileName)"/>
                        <xsl:variable name="getFile">
                           <soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
                              <soapenv:Header/>
                              <soapenv:Body>
                                 <man:request domain="{$domain}">
                                    <man:get-file name="{$certFileName_full}"/>
                                 </man:request>
                              </soapenv:Body>
                           </soapenv:Envelope>
                        </xsl:variable>
                        <xsl:variable name="getFileResponse" select="dp:soap-call('https://127.0.0.1:5550/service/mgmt/current',$getFile/*,'soma-ssl',0,'',$httpHeaders/*)"/>
                        <xsl:variable name="base64EncodedFile" select="$getFileResponse//*[local-name()='file']/text()"/>
                        <xsl:variable name="base64DecodedFile" select="dp:decode($base64EncodedFile,'base-64')"/>
                        <xsl:variable name="base64Cert" select="dp:parse($base64DecodedFile)//certificate/text()"/>
                        <xsl:variable name="cert-data">
                           <xsl:copy-of select="dp:get-cert-details(concat('cert:',$base64Cert))"/>
                        </xsl:variable>

                        <tr>
                           <td>
                              <xsl:value-of select="$certFileName"/>
                           </td>
                           <td>
                              <xsl:value-of select="$cert-data/CertificateDetails/SerialNumber"/>
                           </td>
                           <td>
                              <xsl:value-of select="$cert-data/CertificateDetails/Subject"/>
                           </td>
                           <td>
                              <xsl:value-of select="$cert-data/CertificateDetails/Issuer"/>
                           </td>
                           <td>
                              <xsl:value-of select="substring-before($cert-data/CertificateDetails/NotAfter,'T')"/>
                           </td>
                           <td>
                             <xsl:value-of select="$domain"/>
                           </td>
						   <td>
                             <xsl:value-of select="$certAlias"/>
                           </td>
                        </tr>
                     </xsl:for-each>
                  </xsl:for-each>
               </tbody>
            </table>
         </body>
      </html>
   </xsl:template>
</xsl:stylesheet>
