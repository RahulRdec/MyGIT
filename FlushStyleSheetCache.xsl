<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:ghu="http://ghu.com" extension-element-prefixes="dp func ghu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp ghu func dpfunc dpconfig date str regexp dyn">
	<xsl:template match="/">
		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>
		<xsl:variable name="domainFromRequest">
			<xsl:value-of select="Request/DomainName/text()"/>
		</xsl:variable>
		<status>
			<xsl:choose>
				<xsl:when test="$domainFromRequest='All'">
					<xsl:variable name="domainStatus">
						<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
							<soap:Body>
								<mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
									<mgmt:get-status class="DomainStatus" />
								</mgmt:request>
							</soap:Body>
						</soap:Envelope>
					</xsl:variable>
					<xsl:variable name="getDomainStatusResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$domainStatus/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
					<xsl:for-each select="$getDomainStatusResponse//Domain">
						<xsl:variable name="domain" select="."/>
						<domain name="{$domain}">
							<xsl:message dp:priority="debug">domain '<xsl:value-of select="$domain"/>'</xsl:message>
							<xsl:variable name="getXMLManager">
								<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
									<soapenv:Header/>
									<soapenv:Body>
										<man:request domain="{$domain}">
											<man:get-config class="XMLManager"/>
										</man:request>
									</soapenv:Body>
								</soapenv:Envelope>
							</xsl:variable>
							<xsl:variable name="getXMLManagerResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$getXMLManager/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
							<xsl:for-each select="$getXMLManagerResponse//XMLManager">
								<xsl:variable name="xmlManagerName" select="./@name"/>
								<XMLManager>
									<xsl:value-of select="$xmlManagerName"/>
								</XMLManager>
								<xsl:variable name="flushStyleSheetCache">
									<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
										<soapenv:Header/>
										<soapenv:Body>
											<man:request domain="{$domain}">
												<man:do-action>
													<FlushStylesheetCache>
														<XMLManager>
															<xsl:value-of select="$xmlManagerName"/>
														</XMLManager>
													</FlushStylesheetCache>
												</man:do-action>
											</man:request>
										</soapenv:Body>
									</soapenv:Envelope>
								</xsl:variable>
								<xsl:variable name="flushStyleSheetCacheResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$flushStyleSheetCache/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
								<xsl:choose>
									<xsl:when test="normalize-space($flushStyleSheetCacheResponse/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='response']/*[local-name()='result']/text())='OK'">
										<FlushResult>
											<xsl:value-of select="'Cache Flushed Successfully'"/>
										</FlushResult>
									</xsl:when>
									<xsl:otherwise>
										<FlushResult>
											<xsl:value-of select="$flushStyleSheetCacheResponse"/>
										</FlushResult>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</domain>
					</xsl:for-each>
				</xsl:when>
				<xsl:otherwise>
					<xsl:variable name="domain" select="$domainFromRequest"/>
					<domain name="{$domain}">
						<xsl:message dp:priority="debug">domain '<xsl:value-of select="$domain"/>'</xsl:message>
						<xsl:variable name="getXMLManager">
							<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
								<soapenv:Header/>
								<soapenv:Body>
									<man:request domain="{$domain}">
										<man:get-config class="XMLManager"/>
									</man:request>
								</soapenv:Body>
							</soapenv:Envelope>
						</xsl:variable>
						<xsl:variable name="getXMLManagerResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$getXMLManager/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
						<xsl:for-each select="$getXMLManagerResponse//XMLManager">
							<xsl:variable name="xmlManagerName" select="./@name"/>
							<XMLManager>
								<xsl:value-of select="$xmlManagerName"/>
							</XMLManager>
							<xsl:variable name="flushStyleSheetCache">
								<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
									<soapenv:Header/>
									<soapenv:Body>
										<man:request domain="{$domain}">
											<man:do-action>
												<FlushStylesheetCache>
													<XMLManager>
														<xsl:value-of select="$xmlManagerName"/>
													</XMLManager>
												</FlushStylesheetCache>
											</man:do-action>
										</man:request>
									</soapenv:Body>
								</soapenv:Envelope>
							</xsl:variable>
							<xsl:variable name="flushStyleSheetCacheResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$flushStyleSheetCache/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
							<xsl:choose>
								<xsl:when test="normalize-space($flushStyleSheetCacheResponse/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='response']/*[local-name()='result']/text())='OK'">
									<FlushResult>
										<xsl:value-of select="'Cache Flushed Successfully'"/>
									</FlushResult>
								</xsl:when>
								<xsl:otherwise>
									<FlushResult>
										<xsl:value-of select="$flushStyleSheetCacheResponse"/>
									</FlushResult>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</domain>
				</xsl:otherwise>
			</xsl:choose>
		</status>
	</xsl:template>
</xsl:stylesheet>
