<%@page import="org.springframework.web.context.request.RequestContextHolder"%>
<%@page import="species.License"%>
<%@page import="species.License.LicenseType"%>
<%@ page import="species.participation.Observation"%>
<%@ page import="species.groups.SpeciesGroup"%>
<%@ page import="species.Habitat"%>
<%@ page import="org.grails.taggable.Tag"%>

<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<div id="fb-root"></div>

<meta name="layout" content="main" />
<g:set var="entityName"
	value="${message(code: 'observation.label', default: 'Observation')}" />
<title><g:message code="default.create.label"
		args="[entityName]" />
</title>

<link rel="stylesheet"
	href="${resource(dir:'css',file:'location_picker.css', absolute:true)}"
	type="text/css" media="all" />
<link rel="stylesheet"
	href="${resource(dir:'css',file:'tagit/tagit-custom.css', absolute:true)}"
	type="text/css" media="all" />

<script src="http://maps.google.com/maps/api/js?sensor=true"></script>
<g:javascript src="jquery/jquery.exif.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>
<g:javascript src="jquery/jquery.watermark.min.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>
<g:javascript src="location/location-picker.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>

<g:javascript src="jsrender.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>

<g:javascript src="tagit.js"
	base="${grailsApplication.config.grails.serverURL+'/js/'}"></g:javascript>


</head>
<body>
	<div class="container_16 big_wrapper">

		<div class="grid_16">
			<h1>
				<!--g:message code="default.create.label" args="[entityName]" /-->
				Add an observation
			</h1>

			<g:if test="${flash.message}">
				<div class="message">
					${flash.message}
                        </div>
                </g:if>

                <g:hasErrors bean="${observationInstance}">
                	<div class="errors">
                    	<g:renderErrors bean="${observationInstance}" as="list" />
					</div>
                </g:hasErrors>
            </div>

            <form id="upload_resource" enctype="multipart/form-data"
                    style="position: relative; float: left; z-index: 2; left: 20px; top: 320px;" title="Add a photo for this observation"
                    class="${hasErrors(bean: observationInstance, field: 'resource', 'errors')}">

                    <!-- TODO multiple attribute is HTML5. need to chk if this gracefully falls back to default in non compatible browsers -->
                    <input type="button" class="red" id="upload_button"
                            value="Add photo">
                    <div
                            style="overflow: hidden; width: 100px; height: 49px; position: absolute; left: 0px; top: 0px;">
                            <input type="file" id="attachFiles" name="resources"
                                    multiple="multiple" accept="image/*" />
                    </div>
                    <span class="msg" style="float: right"></span>
            </form>
            
            <%
				def form_id = "addObservation"
				def form_action = createLink(action:'save')
				def form_button_name = "Add Observation"
				def form_button_val = "Add Observation"
				if(params.action == 'edit' || params.action == 'update'){
					form_id = "updateObservation"
					form_action = createLink(action:'update', id:observationInstance.id)
				 	form_button_name = "Update Observation"
					form_button_val = "Update Observation"
				}
			
			%>
			 <form id="${form_id}" action="${form_action}" method="POST">

            <div class="container_16 super-section" style="clear:both;">    
                <div class="grid_16 section bold_section" style="position:relative;overflow:visible;">
                    <h3>What did you observe?</h3>
                        <div class="row">
                            <label for="group"><g:message
                                            code="observation.group.label" default="Group" />
                            </label> 
                            <div id="groups_div" class="bold_dropdown" style="z-index:3;">
                            	<%
									def defaultGroupId = observationInstance?.group?.id
									def defaultGroupIconFileName = (defaultGroupId)? SpeciesGroup.read(defaultGroupId).icon()?.fileName?.trim() : SpeciesGroup.findByName('All').icon()?.fileName?.trim()
									def defaultGroupValue = (defaultGroupId) ? SpeciesGroup.read(defaultGroupId).name : "Select group"
								%>
	                            <div id="selected_group" class="selected_value ${hasErrors(bean: observationInstance, field: 'group', 'errors')}">
									<img
										src="${createLinkTo(dir: 'images', file: defaultGroupIconFileName, absolute:true)}" ></img>
								<span class="display_value">${defaultGroupValue}</span>
								</div>
	                            
	                            <div id="group_options" style="background-color:#fbfbfb;box-shadow:0 8px 6px -6px black; border-radius: 0 5px 5px 5px;display:none;">
	                                    <ul>
	                                    	<g:each in="${species.groups.SpeciesGroup.list()}" var="g">
	                                            <g:if
	                                                    test="${!g.name.equals(grailsApplication.config.speciesPortal.group.ALL)}">
	                                                    <li class="group_option" style="display:inline-block;padding:5px;" value="${g.id}">
	                                                   		<div style="width:160px;">
	                                                    		<img src="${createLinkTo(dir: 'images', file: g.icon()?.fileName?.trim(), absolute:true)}"/>
	                                                    		<span class="display_value">${g.name}</span>
	                                                    	</div>
	                                                    </li>
	                                            </g:if>
	                                    	</g:each>
	                                    </ul>
	                            </div>
                            </div>
                            <input id="group_id" type="hidden" name="group_id"  value="${observationInstance?.group?.id}"></input>
                        </div>

                        <div class="row">
                          <label>Habitat</label>
                            <div id="habitat_list">
                                <div id="habitat_div" class="bold_dropdown" style="z-index:2;">
                                <%
									def defaultHabitatId = observationInstance?.habitat?.id
						  			//def defaultHabitatIconFileName = (defaultHabitatId)? Habitat.read(defaultHabitatId).icon()?.fileName?.trim() : Habitat.findByName('All').icon()?.fileName?.trim()
									def defaultHabitatValue = (defaultHabitatId) ? Habitat.read(defaultHabitatId).name : "Select habitat"
								%>
                                    <div id="selected_habitat" class="selected_value ${hasErrors(bean: observationInstance, field: 'habitat', 'errors')}"><img src="${resource(dir:'images/group_icons',file:'All.png', absolute:true)}"/>
                                    <span class="display_value">${defaultHabitatValue}</span></div>
                                        <div id="habitat_options" style="background-color:#fbfbfb;box-shadow:0 8px 6px -6px black; border-radius: 0 5px 5px 5px;display:none;">                                       <ul>
                                            	<g:each in="${species.Habitat.list()}" var="h">
                                            		<li class="habitat_option" value="${h.id}" ><img src="${resource(dir:'images/group_icons',file:'All.png', absolute:true)}"/><span class="display_value">${h.name}</span></li>
                                    			</g:each>
                                        	</ul>
                                        </div>
                                    </div>
                                </div>	
								<input id="habitat_id" type="hidden" name="habitat_id"  value="${observationInstance?.habitat?.id}"></input>
                            </div>

                        <div class="row" style="margin-top:20px;height:auto;">
                            <label for="recommendationVote"><g:message
                                            code="observation.recommendationVote.label"
                                            default="Species name" />
                            </label>
                            <g:hasErrors bean="${recommendationVoteInstance}">
                                    <div class="errors">
                                            <g:renderErrors bean="${observationInstance}" as="list" />
                                    </div>
                            </g:hasErrors>

                            <reco:create />
                        </div>

                        <div class="row">
                            <label for="observedOn"><g:message
                                        code="observation.observedOn.label" default="Observed on" />
                            </label><input name="observedOn" type="text" id="observedOn" value="${observationInstance?.observedOn?.format('MM/dd/yyyy')}"/>
                        </div>
                        
                    </div>


                <div class="grid_16 section">
                                      <div class="resources">
                        <ul id="imagesList" class="thumbwrap"
                                style='list-style: none; margin-left: 0px;background:url("${resource(dir:'images',file:'species_canvas.png', absolute:true)}")'>
                                <g:set var="i" value="1" />
                                <g:each in="${observationInstance?.resource}" var="r">
                                        <li class="addedResource">
                                                <%def thumbnail = r.fileName.trim().replaceFirst(/\.[a-zA-Z]{3,4}$/, grailsApplication.config.speciesPortal.resources.images.thumbnail.suffix)%>
                                                <div class='figure'
                                                        style='max-height: 220px; max-width: 160px;'>
                                                        <span> <img
                                                                style="width:160px;" src='${createLinkTo(file: thumbnail, base:grailsApplication.config.speciesPortal.observations.serverURL)}'
                                                                class='geotagged_image' exif='true' /> </span>
                                                </div>


                                                <div class='metadata prop'>
                                                        <input name="file_${i}" type="hidden" value='${r.fileName}' />
                                                         <!--label class="name grid_2">Title </label><input
                                                                name="title_${i}" type="text" size='18'
                                                                class='value ui-corner-all' value='${r.description}' /><br /-->
                                                        <!--label class="name grid_2">License </label--> <!--select
                                                                name="license_${i}" class="value ui-corner-all">
                                                                <g:each in="${species.License.list()}" var="l">
                                                                        <option value="${l.name.value()}"
                                                                                ${(l == r.licenses.iterator().next())?'selected':''}>
                                                                                ${l?.name.value()}
                                                                        </option>
                                                                </g:each>
                                                        </select> <br /-->
                                                          <div id="license_div" style="z-index:2;">
                                                                    <div id="selected_license" class="selected_value"><img src="${resource(dir:'images/group_icons',file:'All.png', absolute:true)}"/><span class="display_value">Copyright</span></div>
                                                                        <div id="license_options" style="background-color:#fbfbfb;box-shadow:0 8px 6px -6px black; border-radius: 0 5px 5px 5px;display:none;">                                       <ul>
                                                                                <g:each in="${species.License.list()}" var="l">
                                                                                        <li class="license_option"><img src="${resource(dir:'images/group_icons',file:'All.png', absolute:true)}"/><span class="display_value">${l?.name.value()}</span></li>
                                                                                        </g:each>
                                                                                </ul>
                                                                        </div>
                                                                    </div>
                                                                </div>	
									<input id="license" type="hidden" name="license" ></input>
                                                            </div>


                                                </div> <a href="#" class="resourceRemove">Remove</a></li>
                                        <g:set var="i" value="${i+1}" />
                                </g:each>
                                <li id="add_file" class="addedResource" onclick="$('#attachFiles').select()[0].click();return false;">
                                    <div class="progress">
                                        <div id="translucent_box"></div >
                                        <div id="progress_bar"></div >
                                        <div id="progress_msg"></div >
                                    </div>

                                </li>
                        </ul>

                                   </div>
                                   
                </div>
            </div>

            <div class="container_16 super-section">    
                <div class="grid_8 section" style="clear:both">
                    <h3>Where did you find this observation?</h3>
               
                     <div style="position:relative; left:20px; padding:20px 10px; margin-bottom:10px; background-color:#f7f7f7; border-radius:5px 0 0 5px;">   
                     <input id="address" type="text" title="Find by place name" class="section-item"/>
                     <div id="current_location" class="section-item" style="float:right">
                        <a href="#" onclick="return false;">Use current location</a>
                     </div>
                     <div id="geotagged_images" class="section-item">
                        <div class="title" style="display:none">Use location from geo-tagged image:</div>  	
                        <div class="msg" style="display:none">Select image if you want to use location information embedded in it</div>  	
                    </div>
                    </div>



                    <div class="row">
                    <%
						def defaultPlaceName = (observationInstance) ? observationInstance.placeName : ""
					%>
                        <label>Location title</label> <input id="place_name" type="text"
                                    name="place_name" value="${defaultPlaceName}" ></input>
                                    
                    </div>
                    <div class="row">
                    <%
						def defaultAccuracy = (observationInstance?.locationAccuracy) ? observationInstance.locationAccuracy : "Approximate"
						def isAccurateChecked = (defaultAccuracy == "Accurate")? "checked" : ""
						def isApproxChecked = (defaultAccuracy == "Approximate")? "checked" : ""
					%>
                            <label>Accuracy</label> 
                            <input type="radio" name="location_accuracy" value="Accurate" ${isAccurateChecked} >Accurate 
                            <input type="radio" name="location_accuracy" value="Approximate" ${isApproxChecked} >Approximate<br />
                    </div>

                    <div class="row" style="margin-bottom:20px;">
                            <label>Hide precise location?</label> <input type="checkbox"
                                    name="geo_privacy" value="geo_privacy" />Hide<br />
                    </div>
                    <hr>
                    <div class="row" style="margin-top:20px;">
                            <label>Geocode name</label>
                            <div class="location_picker_value" id="reverse_geocoded_name"></div>
                            <input id="reverse_geocoded_name_field" type="hidden"
                                    name="reverse_geocoded_name" value="${observationInstance?.reverseGeocodedName}" > </input>
                    </div>
                    <div class="row">
                            <label>Latitude</label>
                            <div class="location_picker_value" id="latitude"></div>
                            <input id="latitude_field" type="hidden" name="latitude" value="${observationInstance?.latitude}" ></input>
                    </div>
                    <div class="row">
                            <label>Longitude</label>
                            <div class="location_picker_value" id="longitude"></div>
                            <input id="longitude_field" type="hidden" name="longitude" value="${observationInstance?.longitude}"></input>
                    </div>
              
                </div>
                <div class="grid_8 section" style="margin:30px 10px 10px; background-color:#f7f7f7; border-radius:5px;">
                   
                    <div id="map_area">
                        <div id="map_canvas"></div>
                    </div>

                                                            

                </div>
            </div>    
            <div class="container_16 super-section">    
                <div class="grid_8 section" style="clear:both">
                    <h3>Describe your observation!</h3>
                    <!--label for="notes"><g:message code="observation.notes.label" default="Notes" /></label-->
                    <label style="text-align:left;padding-left:10px;width:auto;">Notes</label> (Max: 400 characters)<br/>
                    <div class="section-item">
                    <g:textArea name="notes" value="${observationInstance?.notes}"
                                                    class="text ui-corner-all" />
                    </div>
                </div>
                <div class="grid_8 section" style="border-radius:5px; background-color:#c4cccf; position: relative; top: 100px;">
                    <label style="text-align:left;padding-left:10px;width:auto;">Tags</label><br/>
                    <div class="create_tags section-item">
                        <ul name="tags">
                            <g:each in="${observationInstance?.tags}">
                            </g:each>
                        </ul>
                    </div>
                </div>
            </div>    
	        <span> <input class="button button-red" type="submit" name="${form_button_name}" value="${form_button_val}" /> </span>
	        <g:if test="${observationInstance?.id}">
	        	<a href="${createLink(controller:'observation', action:'flagDeleted', id:observationInstance.id)}" onclick="return confirm('${message(code: 'default.observatoin.delete.confirm.message', default: 'This observation will be deleted. Are you sure ?')}');"> Delete Observation </a>
	        </g:if>
	    </form>

        </div>

		<!--====== Template ======-->
		<script id="metadataTmpl" type="text/x-jquery-tmpl">
	<li class="addedResource">
		<div class='figure' style='max-height: 165px; max-width: 220px; overflow:hidden;'>
			<span> 
				<img style="width:220px;" src='{{=thumbnail}}' class='geotagged_image' exif='true'/> 
			</span>
		</div>
				
		<div class='metadata prop' style="position:relative; top:15px;">
			<input name="file_{{=i}}" type="hidden" value='{{=file}}'/>
			<!--label class="name grid_2">Title </label><input name="title_{{=i}}" type="text" size='18' class='value ui-corner-all' value='{{=title}}'/><br/-->
			
			<!--label class="name grid_2">License </label-->
			<!--select name="license_{{=i}}" class="value ui-corner-all" >
				<g:each in="${species.License.list()}" var="l">
					<option value="${l.name.value()}" ${(l.name.value().equals(LicenseType.CC_BY.value()))?'selected':''}>${l?.name.value()}</option>
				</g:each>							
			</select><br/-->
                            <div id="license_div_{{=i}}" class="licence_div" style="z-index:2;cursor:pointer;">
                                    <div id="selected_license_{{=i}}" onclick="$(this).next().show();"><img src="${resource(dir:'images/license',file:'cc_by.png', absolute:true)}" title="Set a license for this image"/></div>
                                        <div id="license_options_{{=i}}" class="license_options">                                       <ul>
                                            	<g:each in="${species.License.list()}" var="l">

                                            		<li class="license_option" onclick="$('#license_{{=i}}').val($(this).text());$('#selected_license_{{=i}}').html($(this).html());$('#license_options_{{=i}}').hide();"><img src="${resource(dir:'images/license',file:l?.name.getIconFilename()+'.png', absolute:true)}"/><!--span class="display_value">${l?.name.value()}</span--></li>
                                    			</g:each>
                                        	</ul>
                                        </div>
                                    </div>
                                </div>	
								<input id="license_{{=i}}" type="hidden" name="license_{{=i}}"></input>
                            </div>


		</div>
                <br/>
		<div>
                <!--a href="#" onclick="removeResource(event);$('#geotagged_images').trigger('update_map');">Remove</a-->
                <div class="close_button" onclick="removeResource(event);$('#geotagged_images').trigger('update_map');"></div>
                </div>
	</li>
	
</script>

		<g:javascript>
	
        var mouse_inside_groups_div = false;        
        var mouse_inside_habitat_div = false;        
        var add_file_button = '<li id="add_file" class="addedResource" style="display:none;" onclick="$(\'#attachFiles\').select()[0].click();return false;"><div class="progress"><div id="translucent_box"></div><div id="progress_bar"></div ><div id="progress_msg"></div ></div></li>';

	
	$(document).ready(function(){

		$('#attachFiles').change(function(e){
  			$('#upload_resource').submit().find("span.msg").html("Uploading... Please wait...");
		});
       	
        	
        function progressHandlingFunction(e){
            if(e.lengthComputable){
                var position = e.position || e.loaded;
                var total = e.totalSize || e.total;

                var percentVal = ((position/total)*100).toFixed(0) + '%';
                $('#progress_bar').width(percentVal)
                $('#translucent_box').width('100%')
                $('#progress_msg').html('Uploaded '+percentVal);
             }
        }

     	$('#upload_resource').ajaxForm({ 
			url:'${createLink(controller:'observation', action:'upload_resource')}',
			dataType: 'xml',//could not parse json wih this form plugin 
			clearForm: true,
			resetForm: true,
			type: 'POST',
			 
			beforeSubmit: function(formData, jqForm, options) {
				return true;
			}, 
                        xhr: function() {  // custom xhr
                            myXhr = $.ajaxSettings.xhr();
                            if(myXhr.upload){ // check if upload property exists
                                myXhr.upload.addEventListener('progress', progressHandlingFunction, false); // for handling the progress of the upload
                            }
                            return myXhr;
                        },

			success: function(responseXML, statusText, xhr, form) {
				$(form).find("span.msg").html("");
				var rootDir = '${grailsApplication.config.speciesPortal.observations.serverURL}'
				var obvDir = $(responseXML).find('dir').text();
				var images = []
				var i = $(".metadata").length;
				$(responseXML).find('resources').find('image').each(function() {
					var fileName = $(this).attr('fileName');
					var size = $(this).attr('size');
					var image = rootDir + obvDir + "/" + fileName.replace(/\.[a-zA-Z]{3,4}$/, "${grailsApplication.config.speciesPortal.resources.images.gallery.suffix}");
					var thumbnail = rootDir + obvDir + "/" + fileName.replace(/\.[a-zA-Z]{3,4}$/, "${grailsApplication.config.speciesPortal.resources.images.thumbnail.suffix}");
  					images.push({i:++i, file:obvDir + "/" + fileName, thumbnail:thumbnail, title:fileName});
				});

                                $("#add_file").remove();
                                
				
				var html = $( "#metadataTmpl" ).render( images );
				var metadataEle = $(html)
				metadataEle.each(function() {
					$('.geotagged_image', this).load(function(){
						update_geotagged_images_list($(this));		
					});
				})
				$( "#imagesList" ).append (metadataEle);
                $( "#imagesList" ).append (add_file_button);
                $( "#add_file" ).fadeIn(3000);

			}, error:function (xhr, ajaxOptions, thrownError){
					$('#upload_resource').find("span.msg").html("");
					var messageNode = $(".message .resources") 
					var response = $.parseJSON(xhr.responseText);					
					if(messageNode.length == 0 ) {
						$("#upload_resource").prepend('<div class="message">'+(response?response.error:"Error")+'</div>');
					} else {
						messageNode.append(response?response.error:"Error");
					}
                        } 
     	});  
		/*
		//"aaaaa" 
		//alert("${observationInstance?.observedOn?.getTime()}")
		var currDate = new Date();
		if(${observationInstance?.observedOn != null}){
			currDate = new Date(${observationInstance?.observedOn?.getTime()})
			console.log(currDate);
		}
        var prettyDate =(currDate.getMonth()+1) + '/' + currDate.getDate() + '/' +  currDate.getFullYear();
        $("#observedOn").val(prettyDate);
        //alert(prettyDate);
		*/
		var defaultInitialTags = ["'zz'", "'tt'"]
<%--		if(${observationInstance?.tags != null}){--%>
<%--			defaultInitialTags = ${observationInstance.tags}--%>
<%--		}--%>
<%--		alert("test");--%>
<%--		alert(defaultInitialTags);--%>
		//$("ul[name='tags']").tagit({select:true, initialTags:defaultInitialTags, tagSource: "${g.createLink(action: 'tags')}"});
		$("ul[name='tags']").tagit({select:true,  tagSource: "${g.createLink(action: 'tags')}"});
		//$("ul[name='tags']").tagit();

        $("#selected_group").click(function(){
            $("#group_options").show();
            $(this).css({'background-color':'#fbfbfb', 'border-bottom-color':'#fbfbfb'});
        });

        $("#group_options").hover(function(){
                mouse_inside_groups_div = true;
                }, function(){
                mouse_inside_groups_div = false;
                });


        $("body").mouseup(function(){
                if(!mouse_inside_groups_div){
                    $("#group_options").hide();
                    $("#selected_group").css({'background-color':'#e5e5e5', 'border-bottom-color':'#aeaeae'});
                }
                });
		
        $(".group_option").click(function(){
                $("#group_id").val($(this).val());
                $("#selected_group").html($(this).html());
                $("#group_options").hide();
                $("#selected_group").css({'background-color':'#e5e5e5', 'border-bottom-color':'#aeaeae'});
        });

        $("#selected_habitat").click(function(){
            $("#habitat_options").show();
            $(this).css({'background-color':'#fbfbfb', 'border-bottom-color':'#fbfbfb'});
        });

        $("#habitat_options").hover(function(){
                mouse_inside_habitat_div = true;
                }, function(){
                mouse_inside_habitat_div = false;
                });


        $("body").mouseup(function(){
                if(!mouse_inside_habitat_div){
                    $("#habitat_options").hide();
                    $("#selected_habitat").css({'background-color':'#e5e5e5', 'border-bottom-color':'#aeaeae'});
                }
                });
		
        $(".habitat_option").click(function(){
                $("#habitat_id").val($(this).val());
                $("#selected_habitat").html($(this).html());
                $("#habitat_options").hide();
                $("#selected_habitat").css({'background-color':'#e5e5e5', 'border-bottom-color':'#aeaeae'});
        });
       
        $("#name").watermark("Recommend a species name");
        $("#place_name").watermark("Set a title for this location");
        $(".tagit-input").watermark("Add some tags");
        
        if(${observationInstance?.latitude && observationInstance?.longitude}){
        	set_location(${observationInstance?.latitude}, ${observationInstance?.longitude});
        }

	});

	function removeResource(event) {
		$(event.target).parent().parent('.addedResource').remove();
	}
	
	$( "#observedOn" ).datepicker({
			showOn: "both",
			buttonImage: "/biodiv/images/calendar.gif",
			buttonImageOnly: true
			
	});
	
</g:javascript>
</body>
</html>

