package content

import content.eml.UFile;
import content.eml.Document

import org.codehaus.groovy.grails.web.taglib.exceptions.GrailsTagException

class FileManagerTagLib {
	
	static namespace = 'fileManager'
	
	
	def uploader = { attrs, body ->
		
		out << render(template:"/document/uploader", model: attrs.model);	
	}
	
	
	def download = { attrs, body ->
		
		//checking required fields
		if (!attrs.id) {
			def errorMsg = "'id' attribute not found in file-manager download tag."
			log.error (errorMsg)
			throw new GrailsTagException(errorMsg)
		}
				
	
		params.errorAction = "browser"
		params.errorController = "document"
		
		out << g.link([controller: "UFile", action: "download", params: params, id: attrs.id], body)
		
	}
	def showAllFiles = { attrs, body -> 
		
		out << body
	}
	
	
	def displayIcon = {attrs, body ->
		//checking required fields
		if (!attrs.id) {
			def errorMsg = "'id' attribute not found in file manager display icon tag."
			log.error (errorMsg)
			throw new GrailsTagException(errorMsg)
		}
		
		//XXX - ICON should be based on extension type
		out << g.link(['uri': UFile.findById(attrs.id)?.path], '<p class="pdficon"></p>')
	}

	def displayIconName = {attrs, body->
		//checking required fields
		if (!attrs.id) {
			def errorMsg = "'id' attribute not found in file manager display icon tag."
			log.error (errorMsg)
			throw new GrailsTagException(errorMsg)
		}
		
		//XXX - ICON should be based on extension type		
		out << g.link(['base': UFile.findById(attrs.id)?.path], ' <span class="pdficon" style="display:inline-block; margin-left: 5px; margin-right:5px;"></span>' + UFile.findById(attrs.id)?.path )
		
	}
	
	def displayFile = {attrs, body->
		def filePath = attrs["filePath"]
		def fileName = attrs["fileName"]
		def fileUrl=attrs["fileUrl"]
				
		if(!fileName) {
			int idx = filePath.lastIndexOf("/");
			fileName = idx >= 0 ? filePath.substring(idx + 1) : filePath;
		}
	
		if(filePath){
		  def extension = filePath.split("\\.")[-1]
		  def path = g.createLinkTo(base:grailsApplication.config.speciesPortal.content.serverURL, file: filePath)
	
		  switch(extension.toUpperCase()){
			case ["JPG", "PNG", "GIF"]:
				 def html = """
             <p>
               <img src="${filePath}"
                    alt="${path}"
                    title="${fileName}" />
             </p>
             """
	
				 out << html
				 break

			case "PDF":
							
				
				out <<'<a href='+path+' target="_blank"><span class="pdficon" style="display:inline-block; margin-left: 5px; margin-right:5px;"></span>'+ fileName +'</a>' 
					break
			default:
				out <<'<a href='+path+' target="_blank">'+ fileName +'</a>' 
				 break
		  }
		}else{
		  out << "<!-- no file -->"
		}
	  }
	
	
	

}
