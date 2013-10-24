<%@ page import="content.eml.UFile"%>
<%@ page import="content.eml.Document"%>
<%@page import="species.utils.Utils"%>
<%@ page import="org.grails.taggable.Tag"%>
<%@ page import="species.participation.ActivityFeedService"%>
<html>
<head>
<g:set var="title" value="Documents"/>
<g:render template="/common/titleTemplate" model="['title':title]"/>
<r:require modules="add_file, content_view, activityfeed" />
<uploader:head />
<style type="text/css">
.thumbnails>.thumbnail {
	margin: 0 0 10px 0px;
        width:100%;
}


</style>
</head>
<body>

	<div class="span12">
		<g:render template="/document/documentSubMenuTemplate" model="['entityName':'Documents']" />
		<uGroup:rightSidebar/>
		

		<div class="document-list span8 right-shadow-box" style="margin:0;">
			<g:render template="/document/search" model="['params':params]" />
			
			<obv:showObservationFilterMessage />
			
                        <g:render template="/document/documentListTemplate" model="['userGroupInstance':userGroupInstance]"/>
		</div>
		
		<div class="span4">
		<uGroup:objectPostToGroupsWrapper 
			model="[canPullResource:canPullResource, 'objectType':Document.class.canonicalName]" />
      	</div>
      	<g:render template="/document/documentSidebar" />
	</div>

</body>
</html>
