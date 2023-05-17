<xsl:stylesheet version="1.0" 
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
xmlns:dp="http://www.datapower.com/extensions" 
xmlns:mgmt="http://www.datapower.com/schemas/management" 
xmlns:env="http://www.w3.org/2003/05/soap-envelope" 
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
extension-element-prefixes="dp" exclude-result-prefixes="dp">

	<xsl:template match="/">
		<xsl:variable name="xmlMgmtHost" select="'https://10.205.104.223:5550/service/mgmt/current'"/>
		<xsl:variable name="sslProfile" select="'ldap_ssl'"/>

		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>

			<xsl:variable name="getCertNames">
				<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soap:Header/>
					<soap:Body>
						<man:request domain="UPM-STAGE-BACKEND">
							<man:get-config class="CryptoCertificate"/>
						</man:request>
					</soap:Body>
				</soap:Envelope>
			</xsl:variable> 
			<xsl:variable name="getKeyNames">
				<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
					<soap:Header/>
					<soap:Body>
						<man:request domain="UPM-STAGE-BACKEND">
							<man:get-config class="CryptoKey"/>
						</man:request>
					</soap:Body>
				</soap:Envelope>
			</xsl:variable> 
			<!-- Calling SOMA and get the Response -->
			<xsl:variable name="getCertNamesResponse" select="dp:soap-call($xmlMgmtHost,$getCertNames/*,$sslProfile,0,'',$httpHeaders/*)"/>
			<xsl:variable name="getKeyNamesResponse" select="dp:soap-call($xmlMgmtHost,$getKeyNames/*,$sslProfile,0,'',$httpHeaders/*)"/>

			<xsl:for-each select="$getCertNamesResponse//CryptoCertificate"> 
				<xsl:variable name="certAlice" select="./@name"/>
				<xsl:variable name="disableObject">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soap:Header/>
						<soap:Body>
							<man:request domain="UPM-STAGE-BACKEND">
								<man:modify-config>
									<CryptoCertificate name="{$certAlice}">
										<mAdminState>disabled</mAdminState>
									</CryptoCertificate>
								</man:modify-config>
							</man:request>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$disableObject/*,$sslProfile,0,'',$httpHeaders/*)"/>

				<xsl:variable name="enableObject">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soap:Header/>
						<soap:Body>
							<man:request domain="UPM-STAGE-BACKEND">
								<man:modify-config>
									<CryptoCertificate name="{$certAlice}">
										<mAdminState>enabled</mAdminState>
									</CryptoCertificate>
								</man:modify-config>
							</man:request>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$enableObject/*,$sslProfile,0,'',$httpHeaders/*)"/>
			</xsl:for-each>
			<xsl:for-each select="$getKeyNamesResponse//CryptoKey"> 
				<xsl:variable name="certAlice" select="./@name"/>
				<xsl:variable name="disableObject">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soap:Header/>
						<soap:Body>
							<man:request domain="UPM-STAGE-BACKEND">
								<man:modify-config>
									<CryptoCertificate name="{$certAlice}">
										<mAdminState>disabled</mAdminState>
									</CryptoCertificate>
								</man:modify-config>
							</man:request>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$disableObject/*,$sslProfile,0,'',$httpHeaders/*)"/>

				<xsl:variable name="enableObject">
					<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
						<soap:Header/>
						<soap:Body>
							<man:request domain="UPM-STAGE-BACKEND">
								<man:modify-config>
									<CryptoCertificate name="{$certAlice}">
										<mAdminState>enabled</mAdminState>
									</CryptoCertificate>
								</man:modify-config>
							</man:request>
						</soap:Body>
					</soap:Envelope>
				</xsl:variable>
				<xsl:variable name="somaResponse" select="dp:soap-call($xmlMgmtHost,$enableObject/*,$sslProfile,0,'',$httpHeaders/*)"/>
			</xsl:for-each>
	</xsl:template> 
</xsl:stylesheet>