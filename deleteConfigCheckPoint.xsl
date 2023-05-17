<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:dp="http://www.datapower.com/extensions" 
xmlns:mgmt="http://www.datapower.com/schemas/management" 
xmlns:env="http://www.w3.org/2003/05/soap-envelope" 
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
xmlns:date="http://exslt.org/dates-and-times" 
extension-element-prefixes="dp date" exclude-result-prefixes="dp date">

	<xsl:template match="/">
		<xsl:variable name="xmlMgmtHost" select="'https://127.0.0.1:5550/service/mgmt/current'"/>
		<xsl:variable name="sslProfile" select="'ldap_ssl'"/>
		<xsl:variable name="current_date" select="date:date()"/>
		<xsl:message dp:priority="error">current_date: <xsl:value-of select="$current_date"/>
		</xsl:message>

		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>

		<xsl:variable name="domainStatus">
			<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
				<soap:Body>
					<mgmt:request xmlns:mgmt="http://www.datapower.com/schemas/management" domain="default">
						<mgmt:get-status class="DomainStatus" />
					</mgmt:request>
				</soap:Body>
			</soap:Envelope>
		</xsl:variable>
		<xsl:variable name="getDomainStatusResponse" select="dp:soap-call($xmlMgmtHost,$domainStatus/*,$sslProfile,0,'',$httpHeaders/*)"/>
		<xsl:message dp:priority="error">getDomainStatusResponse: <xsl:copy-of select="$getDomainStatusResponse"/>
		</xsl:message>

		<xsl:for-each select="$getDomainStatusResponse//Domain">
			<xsl:variable name="domain" select="."/>

			<xsl:variable name="getCheckpoints">
				<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soap:Header/>
					<soap:Body>
						<man:request domain="{$domain}">
							<man:get-status class="DomainCheckpointStatus"/>
						</man:request>
					</soap:Body>
				</soap:Envelope>
			</xsl:variable> 
			<!-- Calling SOMA and get the Response -->
			<xsl:variable name="getCheckpointsResponse" select="dp:soap-call($xmlMgmtHost,$getCheckpoints/*,$sslProfile,0,'',$httpHeaders/*)"/>
			<xsl:message dp:priority="error">getCheckpointsResponse: <xsl:copy-of select="$getCheckpointsResponse"/>
			</xsl:message>

			<xsl:for-each select="$getCheckpointsResponse//DomainCheckpointStatus"> 
				<xsl:variable name="CreatedDate" select="./Date"/>
				<xsl:variable name="ChkName" select="./ChkName"/>
				<xsl:message dp:priority="error">CreatedDate: <xsl:value-of select="$CreatedDate"/>
				</xsl:message>

				<xsl:variable name="daysRemaining" select="date:difference($current_date,$CreatedDate)"/>
				<xsl:message dp:priority="error">daysRemaining: <xsl:value-of select="$daysRemaining"/>
				</xsl:message>
				<xsl:variable name="CheckpointAge" select="number(substring-after(substring-before($daysRemaining,'D'),'P'))"/>

				<xsl:if test="$CheckpointAge &gt; 0">
					<xsl:variable name="deleteCheckpoint">
						<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
							<soap:Header/>
							<soap:Body>
								<man:request domain="{$domain}">
									<man:do-action>
										<RemoveCheckpoint>
											<ChkName>
												<xsl:value-of select="$ChkName"/>
											</ChkName>
										</RemoveCheckpoint>
									</man:do-action>
								</man:request>
							</soap:Body>
						</soap:Envelope>
					</xsl:variable>
					<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$deleteCheckpoint/*,$sslProfile,0,'',$httpHeaders/*)"/>
					<xsl:message dp:priority="error">DeleteSomaResponse: <xsl:copy-of select="$somaResponse"/>
				</xsl:message>
				</xsl:if>
			</xsl:for-each>
		</xsl:for-each>
	</xsl:template> 
</xsl:stylesheet>