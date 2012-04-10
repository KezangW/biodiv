<%@ page import="species.participation.Observation"%>
<%@ page import="species.participation.Recommendation"%>
<%@ page import="species.participation.RecommendationVote"%>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta name="layout" content="main" />

<g:set var="entityName"
	value="${message(code: 'observation.label', default: 'Observation')}" />
<title><g:message code="default.show.label" args="[entityName]" />
</title>


<link rel="stylesheet" type="text/css" media="all"
	href="${resource(dir:'js/galleria/1.2.6/themes/classic/',file:'galleria.classic.css', absolute:true)}" />
<link rel="stylesheet" type="text/css" media="all"
	href="${resource(dir:'js/jquery/jquery.jcarousel-0.2.8/themes/classic/',file:'skin.css', absolute:true)}" />

<link rel="stylesheet"
	href="${resource(dir:'css',file:'tagit/tagit-custom.css', absolute:true)}"
	type="text/css" media="all" />

<g:javascript src="jsrender.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>

<g:javascript src="galleria/1.2.6/galleria-1.2.6.min.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}" />

<g:javascript src="tagit.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>

<g:javascript src="jquery/jquery.jcarousel-0.2.8/jquery.jcarousel.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}" />

<g:javascript src="species/carousel.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}" />

<style>
#nameContainer {
	width: 80%;
	float: left;
}

#name {
	width: 90%;
}
</style>
</head>
<body>
	<div class="container outer-wrapper">
		<div class="row">
			<div class="observation  span12">
				<!--h1>
				<g:message code="default.show.label" args="[entityName]" />
			</h1-->

				<g:if test="${flash.message}">
					<div class="message">
						${flash.message}
					</div>
				</g:if>
				<br />

				<div class="page-header" style="overflow: auto;">
					<div class="span8">
						<h1>
							<obv:showSpeciesName
								model="['observationInstance':observationInstance]" />
						</h1>
					</div>
					<div class="span4" style="margin: 0;">
						<sUser:ifOwns model="['user':observationInstance.author]">
							<a class="btn btn-primary" style="float: right;"
								href="${createLink(controller:'observation', action:'edit', id:observationInstance.id)}">
								Edit Observation </a>
						</sUser:ifOwns>
					</div>

				</div>

				<div class="span8 right-shadow-box" style="margin: 0;">


					<div id="gallery1">
						<g:if test="${observationInstance.resource}">
							<g:each in="${observationInstance.resource}" var="r">

								<%def gallImagePath = r.fileName.trim().replaceFirst(/\.[a-zA-Z]{3,4}$/, grailsApplication.config.speciesPortal.resources.images.gallery.suffix)%>
								<%def gallThumbImagePath = r.fileName.trim().replaceFirst(/\.[a-zA-Z]{3,4}$/, grailsApplication.config.speciesPortal.resources.images.galleryThumbnail.suffix)%>
								<a target="_blank"
									rel="${createLinkTo(file: r.fileName.trim(), base:grailsApplication.config.speciesPortal.observations.serverURL)}"
									href="${createLinkTo(file: gallImagePath, base:grailsApplication.config.speciesPortal.observations.serverURL)}">
									<img class="galleryImage"
									src="${createLinkTo(file: gallThumbImagePath, base:grailsApplication.config.speciesPortal.observations.serverURL)}"
									title="${r?.description}" /> </a>

								<g:imageAttribution model="['resource':r]" />
							</g:each>
						</g:if>
						<g:else>
							<img class="galleryImage"
								src="${createLinkTo(file:"no-image.jpg", base:grailsApplication.config.speciesPortal.resources.serverURL)}"
								title="You can contribute!!!" />

						</g:else>

					</div>



					<obv:showStory
						model="['observationInstance':observationInstance, 'showDetails':true]" />
					<div class="recommendations sidebar_section">
						<div>
							<ul id="recoSummary" class="pollBars">

							</ul>
							<div id="seeMoreMessage" class="message"></div>
							<div id="seeMore" class="btn btn-mini">more</div>
						</div>
						<div>
							<g:hasErrors bean="${recommendationInstance}">
								<div class="errors">
									<g:renderErrors bean="${recommendationInstance}" as="list" />
								</div>
							</g:hasErrors>
							<g:hasErrors bean="${recommendationVoteInstance}">
								<div class="errors">
									<g:renderErrors bean="${recommendationVoteInstance}" as="list" />
								</div>
							</g:hasErrors>

							<form id="addRecommendation"
								action="${createLink(controller:'observation', action:'addRecommendationVote')}"
								method="POST" class="form-horizontal">
								<div  class="input-append">
								<reco:create
									model="['recommendationInstance':recommendationInstance]" />
								<input type="hidden" name='obvId'
									value="${observationInstance.id}" /> <input type="submit"
									value="Add" class="btn" style="position: relative; left: 10px;" />
								</div>
							</form>
						</div>
					</div>

					<div class="comments-box sidebar_section" style="clear: both;">
						<fb:comments href="${createLink(controller:'observation', action:'show', id:observationInstance.id, base:grailsApplication.config.grails.domainServerURL)}"
							num_posts="10" width="620" colorscheme="light"></fb:comments>
					</div>

				</div>


				<div class="span4">
					<div class="sidebar_section">
						<obv:showLocation
							model="['observationInstance':observationInstance]" />
					</div>

					<!-- obv:showRating model="['observationInstance':observationInstance]" /-->
					<!--  static species content -->

					<div class="sidebar_section">
						<h3>Related observations</h3>
						<div class="sidebar_section tile" style="clear: both">
							<div class="title">Other observations of the same species</div>
							<obv:showRelatedStory
								model="['observationInstance':observationInstance, 'observationId': observationInstance.id, 'controller':'observation', 'action':'getRelatedObservation', 'filterProperty': 'speciesName', 'id':'a']" />
						</div>
						<div class="sidebar_section tile">
							<div class="title">Nearby observations</div>
							<obv:showRelatedStory
								model="['observationInstance':observationInstance, 'observationId': observationInstance.id, 'controller':'observation', 'action':'getRelatedObservation', 'filterProperty': 'nearBy', 'id':'nearBy']" />
						</div>

					</div>
					<!-- obv:showTagsSummary model="['observationInstance':observationInstance]" /-->
					<!-- obv:showObvStats  model="['observationInstance':observationInstance]"/-->

				</div>


			</div>
		</div>
	</div>
	<g:javascript>
	
	Galleria.loadTheme('${resource(dir:'js/galleria/1.2.6/themes/classic/',file:'galleria.classic.min.js', absolute:true)}');
	
	$(document).ready(function(){
		
		$("#seeMoreMessage").hide();
		
		$(".readmore").readmore({
			substr_len : 400,
			more_link : '<a class="more readmore">&nbsp;More</a>'
		});
		
		$('#gallery1').galleria({
			height : 400,
			preload : 1,
			carousel : true,
			transition : 'pulse',
			image_pan_smoothness : 5,
			showInfo : true,
			dataSelector : "img.galleryImage",
			debug : false,
			thumbQuality : false,
			maxScaleRatio : 1,
			minScaleRatio : 1,
	
			dataConfig : function(img) {
				return {
					// tell Galleria to grab the content from the .desc div as caption
					description : $(img).parent().next('.notes').html()
				};
			},
			extend : function(options) {
				// listen to when an image is shown
				this.bind('image', function(e) {
					// lets make galleria open a lightbox when clicking the main
					// image:
					$(e.imageTarget).click(this.proxy(function() {
						this.openLightbox();
					}));
				});
			}
		});

        $('#voteCountLink').click(function() {
        	$('#voteDetails').show();
        });

        $('#voteDetails').mouseout(function(){
        	$('#voteDetails').hide();
        });
                        
         $("ul[name='tags']").tagit({select:true,  tagSource: "${g.createLink(action: 'tags')}"});
         
         $("li.tagit-choice").click(function(){
         	var tg = $(this).contents().first().text();
         	window.location.href = "${g.createLink(action: 'list')}/?tag=" + tg 
         });
         
         var max = 3, offset = 0;
         $("#seeMore").click(function() {
         	$.ajax({
				url: "${createLink(controller:'observation', action:'getRecommendationVotes', id:observationInstance.id) }",
				method: "GET",
				dataType: "json",
				data: {max:max , offset:offset},	
				success: function(responseJSON) {
					offset = offset += responseJSON.max;
					$("#recoSummary").append(responseJSON.html);		
				}, statusCode: {
	    			401: function() {
	    				show_login_dialog();
	    			}	    				    			
	    		}, error: function(xhr, status, error) {
	    			var msg = $.parseJSON(xhr.responseText);
	    			if(msg.info) {
						$("#seeMoreMessage").html(msg.info).show().removeClass('error').addClass('message');
					} else {
						$("#seeMoreMessage").html(msg.error ? msg.error : "Error").show().removeClass('message').addClass('error');
					}
			   	}
			});
         });
         $("#seeMore").click();
	});
</g:javascript>

</body>
</html>
