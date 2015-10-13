import java.sql.Timestamp;

import javax.sql.DataSource
import groovy.sql.Sql

import species.participation.Comment
import species.participation.Observation
import species.participation.ActivityFeedService
import species.participation.ActivityFeed

import speciespage.UserGroupService
import species.auth.SUser
import species.groups.UserGroup
import org.codehaus.groovy.grails.orm.hibernate.cfg.GrailsDomainBinder;
import content.eml.*;
import species.Species
import species.*;
/*
def feedService = ctx.getBean("activityFeedService");
def userGroupService = ctx.getBean("userGroupService");

def wgpGroup = UserGroup.read(1)
def wgpUserDate = new Date(112, 7, 8)
*/



def migrate(){
	/*
	def userGroupService = ctx.getBean("userGroupService");
	userGroupService.migrateUserPermission()
	println "=== done "
	*/
	
	//migrateUserToWGPGroup()
	//migreateObvToTWGPGroup()
	//migrateCommentAsFeeds()
	migratePermission()
}


def migratePermission(){
	
	def userGroupService = ctx.getBean("userGroupService");
	userGroupService.migrateUserPermission()
	
}

def migrateCommentAsFeeds(){
	def feedService = ctx.getBean("activityFeedService");
	Comment.list().each { Comment c ->
		def rootHolder = feedService.getDomainObject(c.rootHolderType, c.rootHolderId)
		def af = feedService.addActivityFeed(rootHolder, c,  c.author, feedService.COMMENT_ADDED)
		
		if(!af.save(flush:true)){
			println "=========== error while save "
		}
		updateTime(af, c)
		println "=== done comment " + af
	}
}

def migrateUserToWGPGroup(){
	def wgpUserDate = new Date(111, 7, 8)
	def wgpGroup = UserGroup.read(1)
	def feedService = ctx.getBean("activityFeedService");

	SUser.findAllByDateCreatedGreaterThanEquals(wgpUserDate).each{ user ->
		if(!wgpGroup.isMember(user) && !wgpGroup.isFounder(user)){
			wgpGroup.addMember(user)
			println "== done user addition " + user
		}
	}
	
	ActivityFeed.findAllByActivityType(feedService.MEMBER_JOINED).each{ af ->
		def user = feedService.getDomainObject(af.activityHolderType, af.activityHolderId)
		updateTime(af, user)
		println "== done updating user time addition " + user
	}
}

def migreateObvToTWGPGroup(){
	def wgpGroup = UserGroup.read(1)
	def userGroupService = ctx.getBean("userGroupService");
	def feedService = ctx.getBean("activityFeedService");
	
	def obvs = getAllWgpObvs()
	obvs.each{ obv ->
		userGroupService.postObservationToUserGroup(obv, wgpGroup)
		println "done post of obv " + obv
	}
	
	ActivityFeed.findAllByActivityType(feedService.OBSERVATION_POSTED_ON_GROUP).each{ af ->
		def obv = feedService.getDomainObject(af.rootHolderType, af.rootHolderId)
		af.dateCreated = obv.createdOn 
		af.lastUpdated = obv.createdOn
		if(!af.save(flush:true)){
			af.errors.allErrors.each { println  it }
		}
		println "== done updating user time addition " + obv
	}
}

def getAllWgpObvs(){
	def dataSource =  ctx.getBean("dataSource");
	println "======== data osurce  $dataSource"
	def sql =  Sql.newInstance(dataSource);
	String query = "select obv.id from observation_locations as obv, wg_bounds as wg where ST_Contains(wg.geom, obv.st_geomfromtext);"
	String query1 = "select obv.id as id from observation as obv"
	def retList = []
	sql.eachRow(query){ row ->
		println "=== id " + row.id
		retList.add(Observation.read(row.id))
	}
	return retList
}

def updateTime(af, c){
	af.dateCreated = c.dateCreated 
	af.lastUpdated = c.dateCreated
	
	
	println "new date " + af.dateCreated
	
	if(!af.save(flush:true)){
		af.errors.allErrors.each { println  it }
	}
	println "after save " +  af.dateCreated
}


def correctObvActivityOrder(){
	def feedService = ctx.getBean("activityFeedService");
	
	ActivityFeed.withTransaction(){
		ActivityFeed.findAllByActivityType(feedService.OBSERVATION_CREATED).each{ af ->
			def createdTime = af.dateCreated
			
			ActivityFeed.findAllWhere(activityType:feedService.OBSERVATION_POSTED_ON_GROUP, rootHolderType:af.rootHolderType, rootHolderId:af.rootHolderId).each{ af1 ->
				if(createdTime >=  af1.dateCreated){
					createdTime = new Timestamp(af1.dateCreated.getTime() - 1)
				}
			}
			
			if(createdTime < af.dateCreated){
				af.dateCreated = createdTime
				if(!af.save()){
					af.errors.allErrors.each { println  it }
				}
				println "========== updating " + af
			}
		}
	}
	
	
	
	//biodiv=#  update activity_feed set last_updated = date_created where activity_type = 'Observation created';
}

def addFeedForObvCreate(){
	def feedService = ctx.getBean("activityFeedService");
	Observation.findAllWhere(isDeleted:false).each { obv ->
		def af1 = ActivityFeed.findWhere(activityType:feedService.OBSERVATION_CREATED, rootHolderType:Observation.class.getCanonicalName(), rootHolderId:obv.id)
		if(!af1){
			ActivityFeed newaf = feedService.addActivityFeed(obv, null, obv.author, feedService.OBSERVATION_CREATED);
			println "saved feed"
		}
	}
	ActivityFeed.withTransaction(){
	ActivityFeed.findAllByActivityType(feedService.OBSERVATION_CREATED).each{ af ->
		def obv = feedService.getDomainObject(af.rootHolderType, af.rootHolderId)
		af.dateCreated = obv.createdOn
		af.lastUpdated = obv.createdOn
		if(!af.save()){
			af.errors.allErrors.each { println  it }
		}
		println "== done updating user time addition " + af.dateCreated
	}
	}
}

def addUserRegistrationFeed(){
	def checklistUtilService = ctx.getBean("checklistUtilService");
	def m = GrailsDomainBinder.getMapping(ActivityFeed.class)
	m.autoTimestamp = false
	
	SUser.withTransaction(){
		SUser.list().each { user ->
			println user
			checklistUtilService.addActivityFeed(user, user, user, ActivityFeedService.USER_REGISTERED, user.dateCreated);
		}
	}
	m.autoTimestamp = true
}


def addDocumentPostFeed(){
	def checklistUtilService = ctx.getBean("checklistUtilService");
	def m = GrailsDomainBinder.getMapping(ActivityFeed.class)
	def desc = "Posted document to group"
	m.autoTimestamp = false
	Document.withTransaction(){
		Document.list().each { doc ->
			println doc
			doc.userGroups.each { ug ->
				checklistUtilService.addActivityFeed(doc, ug, doc.author, ActivityFeedService.RESOURCE_POSTED_ON_GROUP, new Date(doc.createdOn.getTime() + 2) , desc);
			}
		}
	}
	m.autoTimestamp = true
}



def migrateCoverageToDoc(){
	Document.withTransaction(){
		Document.list().each { Document doc ->
			println "=================================="
			println doc
			def cov = doc.coverage
			if(cov){
				println "========== got coverage properties  "
				doc.placeName    = cov.placeName
				doc.reverseGeocodedName   = cov.reverseGeocodedName
				doc.latitude    = cov.latitude
				doc.longitude  = cov.longitude
				doc.topology    = cov.topology
				doc.geoPrivacy    = cov.geoPrivacy
				if(cov.habitats){
					cov.habitats.each { 
						doc.addToHabitats(it)
					}
				}
				if(cov.speciesGroups){
					cov.speciesGroups.each {
						doc.addToSpeciesGroups(it)
					}
				}
				if(!doc.save(flush:true)){
					doc.errors.allErrors.each { println  it }
				}
			}
			println "=================================="
		}
	}
}



def pullTreeSpecies(){
	def startDate = new Date()
	def userGroupService = ctx.getBean("userGroupService");
	def ds = ctx.getBean("dataSource");
	def conn = new Sql(ds);
	String query = "select species_id from species_field where description ILIKE '%tree%' and id in (select id from species_field where field_id in (4, 7, 16)) and id not in (select species_field_contributors_id from species_field_contributor where contributor_id = 268373);"
	try {
		def speciesIdList = conn.rows(query);
		def newList = []
		speciesIdList.each{ 
			if(!newList.contains(it.species_id))
				newList << it.species_id
		}
		println "============ new list size  " + newList.size()
		//println "========== species list " + 	newList.join(",")
		def userGroups = [18]
		def myMap = ['pullType':'bulk', 'selectionType':'reset', 'objectType':species.Species.class.canonicalName, 'objectIds':newList.join(","), 'submitType':'post', 'userGroups':userGroups.join(","), 'filterUrl':'', 'author':'1426']
		userGroupService.updateResourceOnGroup(myMap)
		println "========== Done  start date " + startDate + "   endDate " + new Date() 
				
	}catch (Exception e) {
		// TODO: handle exception
		e.printStackTrace();
	}
}


def pullTreeObservations(){
	def startDate = new Date()
	def userGroupService = ctx.getBean("userGroupService");
	def ds = ctx.getBean("dataSource");
	def conn = new Sql(ds);
	String query = "select id from observation where is_deleted = false and is_checklist = false and source_id = id and max_voted_reco_id in ( select id from recommendation where taxon_concept_id in ( select taxon_concept_id from species where id in (select species_id from user_group_species where user_group_id = 18)));"
	try {
		def speciesIdList = conn.rows(query);
		def newList = []
		speciesIdList.each{ 
			if(!newList.contains(it.id))
				newList << it.id
		}
		println "============ new list size  " + newList.size()
		//println "========== species list " + 	newList.join(",")
		def userGroups = [18]
		def myMap = ['pullType':'bulk', 'selectionType':'reset', 'objectType':species.participation.Observation.class.canonicalName, 'objectIds':newList.join(","), 'submitType':'post', 'userGroups':userGroups.join(","), 'filterUrl':'', 'author':'1426']
		userGroupService.updateResourceOnGroup(myMap)
		println "========== Done  start date " + startDate + "   endDate " + new Date() 
				
	}catch (Exception e) {
		// TODO: handle exception
		e.printStackTrace();
	}
}


def postSpeices(){
	def userGroupService = ctx.getBean("userGroupService");
	def m = [author:"1", userGroups:"45", objectType:Species.class.getCanonicalName(), submitType:'post', objectIds: new File('/home/biodiv/NEspecies.csv').text]
	println m
	userGroupService.updateResourceOnGroup(m)
}


def updateSpeciesGroup(){
	def groupHandlerService = ctx.getBean("groupHandlerService");
	Species.findAllByIdGreaterThanEquals(276023).each { Species s ->
		groupHandlerService.updateGroup(s.taxonConcept);
	}
}



def obsQuery(){
	File file = new File("/tmp/obv.txt")
	if(!file.exists()){
		file.createNewFile()
	}
	file.write "obv_id | contributor_id | suggestors \n"
	
	def ds = ctx.getBean('dataSource')
	Sql sql = Sql.newInstance(ds)
	String query = ''' select o.id as id, o.author_id as user_id from observation o, user_group_observations ug  where ug.user_group_id = 33 and o.id = ug.observation_id and o.created_on > '2015-08-01 00:00:00' and  o.created_on <  '2015-09-01 00:00:00' ''';
	String q = "select string_agg(CAST(author_id as varchar), ', ') as cc from recommendation_vote where observation_id = " 
	sql.eachRow(query){ row ->
		String str = row.id + "|" + row.user_id + "|" 
		def r = sql.rows(q + row.id)
		def tt = ""
		if(r){
			tt = r[0].cc
		}
 		str += tt + "\n"
		println str
		file << str
	}
}


//obsQuery()

def addNewField1(){
	def f = new Field(language: Language.findByNameIlike(Language.DEFAULT_LANGUAGE), concept:'Nomenclature and Classification',category:'Taxon Record Name', subCategory:'Rank',description:'Place holder for TaxonRank', displayOrder:85, connection:85)
	f.save(flush:true)
	
	f = new Field(language: Language.findByNameIlike(Language.DEFAULT_LANGUAGE), concept:'Nomenclature and Classification',category:'Author Contributed Taxonomy Hierarchy', subCategory:'Infra Species',description:'Place holder for Infra Species', displayOrder:86, connection:86)
	f.save(flush:true)
}

addNewField1()

//updateSpeciesGroup()

//postSpeices()

//pullTreeSpecies()
//pullTreeObservations()

//migrateCoverageToDoc()
//addDocumentPostFeed()
//author contributed taxonomy hierarchy

//addUserRegistrationFeed()

//addFeedForObvCreate()
//correctObvActivityOrder()
//migrate()

/*
//please run following command on database
//biodiv=#  update activity_feed set last_updated = date_created;
//becasue last updated is managed by grails so manully setting its time to same as date_created
*/
