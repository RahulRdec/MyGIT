<xsl:stylesheet version="1.0"
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:dp="http://www.datapower.com/extensions"
				xmlns:func="http://exslt.org/functions"
				xmlns:dpfunc="http://www.datapower.com/extensions/functions"
				xmlns:dpconfig="http://www.datapower.com/param/config"
				xmlns:date="http://exslt.org/dates-and-times"
				xmlns:str="http://exslt.org/strings"
				xmlns:regexp="http://exslt.org/regular-expressions"
				xmlns:dyn="http://exslt.org/dynamic"
				xmlns:hgu="http://hgu.com"
				extension-element-prefixes="dp func hgu dpfunc dpconfig date str regexp dyn"
				exclude-result-prefixes="dp hgu func dpfunc dpconfig date str regexp dyn">
	<xsl:output omit-xml-declaration="yes" />
	<xsl:template match="/">
		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="current_date" select="date:date()"/>
		<xsl:variable name="certDetails">
			<certDetails>

				<xsl:variable name="domainStatus">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
						<soap:Body>
							<mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
								<mgmt:get-status class="DomainStatus" />
							</mgmt:request>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="getDomainStatusResponse" select="dp:soap-call('https://10.119.202.36:5550/service/mgmt/current',$domainStatus/*,'soma-ssl',0,'',$httpHeaders/*)"/>
				<xsl:for-each select="$getDomainStatusResponse//Domain">
					<xsl:variable name="domain" select="."/>
					<xsl:message dp:priority="debug">domain '<xsl:value-of select="$domain"/>'</xsl:message>
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
					<xsl:variable name="getCertNamesResponse" select="dp:soap-call('https://10.119.202.36:5550/service/mgmt/current',$getCertNames/*,'soma-ssl',0,'',$httpHeaders/*)"/>
					<xsl:for-each select="$getCertNamesResponse//CryptoCertificate">
						<xsl:variable name="certAlias" select="./@name"/>
						<xsl:variable name="certFullPath" select="./Filename/text()"/>
						<xsl:variable name="certFileName" select="substring-after($certFullPath,':///')"/>
						<!-- Delete cert file from temporary directory as export does not overwrite existing file. -->
						<xsl:variable name="deleteCert">
							<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
								<soapenv:Header/>
								<soapenv:Body>
									<man:request domain="{$domain}">
										<man:do-action>
											<DeleteFile>
												<File>
													<xsl:value-of select="concat('temporary:///',normalize-space($certFileName))"/>
												</File>
											</DeleteFile>
										</man:do-action>
									</man:request>
								</soapenv:Body>
							</soapenv:Envelope>
						</xsl:variable>
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
						<xsl:variable name="deleteCertResponse" select="dp:soap-call('https://10.119.202.36:5550/service/mgmt/current',$deleteCert/*,'soma-ssl',0,'',$httpHeaders/*)"/>
						<xsl:variable name="getExportCryptoCertResponse" select="dp:soap-call('https://10.119.202.36:5550/service/mgmt/current',$exportCryptoCert/*,'soma-ssl',0,'',$httpHeaders/*)"/>
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
						<xsl:variable name="getFileResponse" select="dp:soap-call('https://10.119.202.36:5550/service/mgmt/current',$getFile/*,'soma-ssl',0,'',$httpHeaders/*)"/>

						<xsl:variable name="base64EncodedFile" select="$getFileResponse//*[local-name()='file']/text()"/>

						<xsl:variable name="base64DecodedFile" select="dp:decode($base64EncodedFile,'base-64')"/>

						<xsl:variable name="base64Cert" select="dp:parse($base64DecodedFile)//certificate/text()"/>

						<xsl:variable name="cert-data">
							<xsl:copy-of select="dp:get-cert-details(concat('cert:',$base64Cert))"/>
						</xsl:variable>
						<xsl:variable name="certExpiry" select="$cert-data/CertificateDetails/NotAfter"/>
						<xsl:variable name="daysRemaining" select="date:difference($current_date,$certExpiry)"/>
						<xsl:variable name="numberofDaysRemaining" select="number(translate($daysRemaining,'DP',''))"/>
						<xsl:if test="$numberofDaysRemaining &lt; 14">
							<cert name="{$certFullPath}">
								<version>
									<xsl:value-of select="$cert-data/CertificateDetails/Version"/>
								</version>
								<serial>
									<xsl:value-of select="$cert-data/CertificateDetails/SerialNumber"/>
								</serial>
								<subject>
									<xsl:value-of select="$cert-data/CertificateDetails/Subject"/>
								</subject>
								<issuer>
									<xsl:value-of select="$cert-data/CertificateDetails/Issuer"/>
								</issuer>
								<notbefore>
									<xsl:value-of select="substring-before($cert-data/CertificateDetails/NotBefore,'T')"/>
								</notbefore>
								<notafter>
									<xsl:value-of select="substring-before($cert-data/CertificateDetails/NotAfter,'T')"/>
								</notafter>
								<daysremaining>
									<xsl:value-of select="$numberofDaysRemaining"/>
								</daysremaining>
								<DomainName>
									<xsl:value-of select="$domain"/>
								</DomainName>
								<CryptoCertObject>
									<xsl:value-of select="$certAlias"/>
								</CryptoCertObject>
							</cert>
						</xsl:if>
					</xsl:for-each>
				</xsl:for-each>
			</certDetails>
		</xsl:variable>
		<xsl:variable name="finalOutput">
			<html>
				<body>
					<p>Hello Team,</p>
					<p>This is an automatic alert for the certificates that are about to expire on DataPower Cloud Production environment within 2 weeks from today. Please reach out to the respective teams to get the certificate renewed in the system. Please find below the list of all such certificates:</p>
					<br/>
					<p>Note: Negative (-ve) value of 'Days Remaining' indicates that certificate has expired already and needs to be removed from device.</p>
					<br/>
					<table border="1">
						<tbody align="left">
							<tr>
								<th>Cert Name</th>
								<th>Version</th>
								<th>Serial Number</th>
								<th>Subject</th>
								<th>Issuer</th>
								<th>NotBefore</th>
								<th>NotAfter</th>
								<th>Days Remaining</th>
								<th>Domain</th>
								<th>CryptoCertObject</th>
							</tr>
							<xsl:for-each select="$certDetails//cert[not(@name=preceding-sibling::cert/@name)]">
								<tr>
									<td>
										<xsl:value-of select="./@name"/>
									</td>
									<td>
										<xsl:value-of select=".//version/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//serial/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//subject/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//issuer/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//notbefore/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//notafter/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//daysremaining/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//DomainName/text()"/>
									</td>
									<td>
										<xsl:value-of select=".//CryptoCertObject/text()"/>
									</td>
								</tr>
							</xsl:for-each>
						</tbody>
					</table>
					<br/>
					<br/>
					<p>--DataPower Automatic Notification System</p>
				</body>
			</html>
		</xsl:variable>
		<xsl:variable name="sender" select="dp:encode('datapower_notification@mutpo.com','url')"/>
		<xsl:variable name="receiver" select="dp:encode('API_Security_Gateway_DL@ds.chu.com','url')"/>
		<xsl:variable name="subject" select="dp:encode('Urgent Attention Required - DP Cloud Production: Certificates expiring within 2 Weeks','url')"/>
		<xsl:variable name="domain" select="dp:encode('mail02.chu.com','url')"/>
		<xsl:variable name="remotehost" select="dp:encode('mailinbound.chu.com','url')"/>
		<xsl:variable name="serializedHTMLData">
			<dp:serialize select="$finalOutput" omit-xml-decl="yes"/>
		</xsl:variable>
		<xsl:variable name="CRLF"  select="'&#13;&#10;'"/>
		<xsl:variable name="DDASH" select="'--'"/>
		<xsl:variable name="QUOT"  select="'&quot;'"/>
		<xsl:variable name="boundary" select="dp:generate-uuid()"/>
		<xsl:if test="$finalOutput//tr/td[1]/text()!=''">
			<dp:url-open response="ignore" target="{concat( 'smtp://', $remotehost, '/?Recpt=', $receiver, '&amp;Sender=', $sender, '&amp;Subject=', $subject, '&amp;Domain=', $domain, '&amp;MIME=true' )}">
				<xsl:value-of disable-output-escaping="yes" select="concat('MIME-Version: 1.0',$CRLF)"/>
				<xsl:value-of disable-output-escaping="yes" select="concat('Content-type: text/html',$CRLF,$CRLF)"/>
				<xsl:value-of disable-output-escaping="yes" select="$serializedHTMLData"/>
			</dp:url-open>
		</xsl:if>
	</xsl:template>
</xsl:stylesheet>
