<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:dp="http://www.datapower.com/extensions" xmlns:func="http://exslt.org/functions" xmlns:dpfunc="http://www.datapower.com/extensions/functions" xmlns:dpconfig="http://www.datapower.com/param/config" xmlns:date="http://exslt.org/dates-and-times" xmlns:str="http://exslt.org/strings" xmlns:regexp="http://exslt.org/regular-expressions" xmlns:dyn="http://exslt.org/dynamic" xmlns:chu="http://chu.com" extension-element-prefixes="dp func chu dpfunc dpconfig date str regexp dyn" exclude-result-prefixes="dp chu func dpfunc dpconfig date str regexp dyn">

	<xsl:template match="/">
		<!-- Get FileStore -->
		<xsl:variable name="getFileStore">
			<soapenv:Envelope xmlns:man="http://www.datapower.com/schemas/management" xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="default">
						<man:get-filestore location="temporary:" annotated="false" layout-only="false" no-subdirectories="true"/>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable>

		<!-- Create Error Report -->
		<xsl:variable name="createErrorReport">
			<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
				<soapenv:Header/>
				<soapenv:Body>
					<man:request domain="default">
						<man:do-action>
							<ErrorReport/>
						</man:do-action>
					</man:request>
				</soapenv:Body>
			</soapenv:Envelope>
		</xsl:variable> 

		<xsl:variable name="httpHeaders">
			<header name="Content-Type">application/soap+xml</header>
			<header name="Authorization">Basic T2ZmU2hvcmVfU2VjQmt1cDpMQGchbiRhZmU=</header>
		</xsl:variable>

		<!-- Calling SOMA and get the FileStore -->
		<xsl:variable name="getFileStoreCloud1" select="dp:soap-call('https://dpvblkprd01.chu.com:5550/service/mgmt/current',$getFileStore/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
		<xsl:variable name="getFileStoreCloud2" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$getFileStoreCore/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

		<xsl:for-each select="$getFileStoreCloud1//file">
			<xsl:variable name="filename" select="./@name"/>
			<xsl:message dp:priority="error">filename : <xsl:value-of select="$filename"/>
			</xsl:message>
			<xsl:variable name="filepath" select="concat('temporary:///', $filename)"/>
			<xsl:message dp:priority="error">filepath : <xsl:value-of select="$filepath"/>
			</xsl:message>
			<xsl:choose>
				<xsl:when test="contains($filepath, 'temporary:///error-report')">
					<xsl:variable name="deleteFiles">
						<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
							<soapenv:Header/>
							<soapenv:Body>
								<man:request domain="default">
									<man:do-action>
										<DeleteFile>
											<File>
												<xsl:value-of select="$filepath"/>
											</File>
										</DeleteFile>
									</man:do-action>
								</man:request>
							</soapenv:Body>
						</soapenv:Envelope>
					</xsl:variable>
					<xsl:variable name="getDeleteFileResponse" select="dp:soap-call('https://dpvblkprd01.chu.com:5550/service/mgmt/current',$deleteFiles/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
					<xsl:message dp:priority="error">getDeleteFileResponse : <xsl:value-of select="$getDeleteFileResponse"/>
					</xsl:message>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message dp:priority="error">No old report to delete. Creating new reports. <xsl:value-of select="$filepath"/>
					</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

		<xsl:for-each select="$getFileStoreCloud2//file">
			<xsl:variable name="filename" select="./@name"/>
			<xsl:message dp:priority="error">filename : <xsl:value-of select="$filename"/>
			</xsl:message>
			<xsl:variable name="filepath" select="concat('temporary:///', $filename)"/>
			<xsl:message dp:priority="error">filepath : <xsl:value-of select="$filepath"/>
			</xsl:message>
			<xsl:choose>
				<xsl:when test="contains($filepath, 'temporary:///error-report')">
					<xsl:variable name="deleteFiles">
						<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:man="http://www.datapower.com/schemas/management">
							<soapenv:Header/>
							<soapenv:Body>
								<man:request domain="default">
									<man:do-action>
										<DeleteFile>
											<File>
												<xsl:value-of select="$filepath"/>
											</File>
										</DeleteFile>
									</man:do-action>
								</man:request>
							</soapenv:Body>
						</soapenv:Envelope>
					</xsl:variable>
					<xsl:variable name="getDeleteFileResponse" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$deleteFiles/*,'ldap_ssl',0,'',$httpHeaders/*)"/>
					<xsl:message dp:priority="error">getDeleteFileResponse : <xsl:value-of select="$getDeleteFileResponse"/>
					</xsl:message>
				</xsl:when>
				<xsl:otherwise>
					<xsl:message dp:priority="error">No old report to delete. Creating new reports. <xsl:value-of select="$filepath"/>
					</xsl:message>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>

		<!-- Create Error Report -->
		<xsl:variable name="createErrorReportCloud1" select="dp:soap-call('https://dpvblkprd01.chu.com:5550/service/mgmt/current',$createErrorReport/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

		<xsl:variable name="createErrorReportCloud2" select="dp:soap-call('https://dpvblkprd02.chu.com:5550/service/mgmt/current',$createErrorReport/*,'ldap_ssl',0,'',$httpHeaders/*)"/>

		<xsl:choose>
			<xsl:when test="normalize-space($createErrorReportCloud1/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='response']/*[local-name()='result']/text())='OK'">
				<xsl:text> Cloud 1 Error Report Generated Successfully. </xsl:text>
				<xsl:text>&#10;</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> Failed to generate Cloud 1 error report. Please try again or check logs. </xsl:text>
				<xsl:text>&#10;</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:choose>
			<xsl:when test="normalize-space($createErrorReportCloud2/*[local-name()='Envelope']/*[local-name()='Body']/*[local-name()='response']/*[local-name()='result']/text())='OK'">
				<xsl:text> Cloud 2 Error Report Generated Successfully. </xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text> Failed to generate Cloud 2 error report. Please try again or check logs. </xsl:text>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>
</xsl:stylesheet>
