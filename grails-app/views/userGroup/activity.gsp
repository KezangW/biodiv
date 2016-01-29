<%@page import="org.springframework.security.acls.domain.BasePermission"%>
<%@page import="species.utils.ImageType"%>
<%@page import="species.utils.Utils"%>
<%@ page import="species.groups.UserGroup"%>
<html>
<head>
<g:set var="title" value="${g.message(code:'ugroup.value.activity')}"/>
<g:render template="/common/titleTemplate" model="['title':title]"/>
<style>
.comment-textbox {
	width: 100%;
}
.thumbnail .observation_story {
width:715px;
}

</style>
</head>
<body>
	<div class="observation span12 bodymarker">
		<uGroup:showSubmenuTemplate model="['entityName':'Activity']"/>
		<uGroup:rightSidebar model="['userGroupInstance':userGroupInstance]"/>
		<div class="userGroup-section">
			<feed:showFeedWithFilter model="['rootHolder':userGroupInstance, feedType:'GroupSpecific', feedPermission:'editable', feedCategory:UserGroup.class.canonicalName,'feedOrder':'latestFirst']" />
		</div>	
	</div>
</body>
</html>
