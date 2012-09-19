
<%@page import="org.springframework.security.acls.domain.BasePermission"%>

<%@page import="org.springframework.security.acls.domain.BasePermission"%>
<%@page import="species.utils.ImageType"%>
<%@page import="species.utils.Utils"%>
<%@ page import="species.groups.UserGroup"%>
<html>
<head>
<meta name="layout" content="main" />
<g:set var="entityName" value="${userGroupInstance.name}" />
<title><g:message code="default.show.label"
		args="[userGroupInstance.name]" /></title>
<r:require modules="userGroups_show" />
</head>
<body>
	<div class="observation span12">
		<uGroup:showSubmenuTemplate />
		<div class="super-section userGroup-section">
			<div class="description notes_view">
				${userGroupInstance.description}
			</div>
		</div>

		<div class="super-section userGroup-section">
			<div class="description notes_view" name="contactEmail">
				Contact us by filling in the following feedback form.</div>
		</div>
	</div>


	<r:script>
		$(document).ready(function(){

		});
	</r:script>
</body>
</html>