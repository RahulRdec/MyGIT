<xsl:stylesheet version="1.0" extension-element-prefixes="dp func hgu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp hgu func dpfunc dpconfig date str regexp dyn" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:hgu="http://hgu.com">
	<xsl:output method="html"/>
	<xsl:template match="/">
		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic YWRtaW46YWRtaW4xMjM=</header>
		</xsl:variable>
		<xsl:variable name="xmlMgmtHost" select="'https://dpelrprd01.chu.com:5550/service/mgmt/current'"/>
		<xsl:variable name="sslProfile" select="'localhost_sslProxyProfile'"/>
		<xsl:variable name="current_date" select="date:date()"/>
		<html>
			<body>
				<table border="1">
					<tbody align="left">
						<tr>
							<th>Cert Name</th>
							<th>Serial Number</th>
							<th>Issuer</th>
							<th>Expiry</th>
							<th>Days Remaining</th>
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
						<xsl:variable name="getDomainStatusResponse" select="dp:soap-call($xmlMgmtHost,$domainStatus/*,$sslProfile,0,'',$httpHeaders/*)"/>
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
							<xsl:variable name="getCertNamesResponse" select="dp:soap-call($xmlMgmtHost,$getCertNames/*,$sslProfile,0,'',$httpHeaders/*)"/>
							<xsl:for-each select="$getCertNamesResponse//CryptoCertificate">
								<xsl:variable name="certAlias" select="./@name"/>
								<xsl:variable name="certFullPath" select="./Filename/text()"/>
								<xsl:variable name="certFileName" select="substring-after($certFullPath,':///')"/>
								<xsl:variable name="getCertDetails">
									<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
										<soapenv:Header/>
										<soapenv:Body>
											<man:request domain="{$domain}">
												<man:do-view-certificate-details>
													<man:certificate-object>
														<xsl:value-of select="$certAlias"/>
													</man:certificate-object>
												</man:do-view-certificate-details>
											</man:request>
										</soapenv:Body>
									</soapenv:Envelope>
								</xsl:variable>
								<xsl:variable name="getCertDetailsResponse" select="dp:soap-call($xmlMgmtHost,$getCertDetails/*,$sslProfile,0,'',$httpHeaders/*)"/>
								<xsl:variable name="certExpiry" select="substring-before($getCertDetailsResponse//CertificateDetails/NotAfter,'T')"/>
								<xsl:message dp:priority="error">certExpiry '<xsl:value-of select="$certExpiry"/>'</xsl:message>
								<xsl:variable name="daysRemaining" select="date:difference($current_date,$certExpiry)"/>
								<xsl:message dp:priority="error">daysRemaining '<xsl:value-of select="$daysRemaining"/>'</xsl:message>
								<xsl:variable name="numberofDaysRemaining" select="number(translate($daysRemaining,'DP',''))"/>
								<xsl:message dp:priority="error">numberofDaysRemaining '<xsl:value-of select="$numberofDaysRemaining"/>'</xsl:message>
								<xsl:if test="$numberofDaysRemaining &lt; 14">
									<tr>
										<td>
											<xsl:value-of select="$getCertDetailsResponse//CertificateDetails/Subject"/>
										</td>
										<td>
											<xsl:value-of select="$getCertDetailsResponse//CertificateDetails/SerialNumber"/>
										</td>
										<td>
											<xsl:value-of select="$getCertDetailsResponse//CertificateDetails/Issuer"/>
										</td>
										<td>
											<xsl:value-of select="substring-before($getCertDetailsResponse//CertificateDetails/NotAfter,'T')"/>
										</td>
										<td>
											<xsl:value-of select="$numberofDaysRemaining"/>
										</td>
										<td>
											<xsl:value-of select="$domain"/>
										</td>
										<td>
											<xsl:value-of select="$certAlias"/>
										</td>
									</tr>
								</xsl:if>
							</xsl:for-each>
						</xsl:for-each>
					</tbody>
				</table>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
