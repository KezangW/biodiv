package speciespage

import static groovyx.net.http.ContentType.JSON

import java.util.List

import org.apache.commons.logging.LogFactory
import org.apache.lucene.analysis.Analyzer
import org.apache.lucene.analysis.standard.StandardAnalyzer
import org.apache.lucene.analysis.shingle.ShingleAnalyzerWrapper
import org.apache.lucene.analysis.tokenattributes.CharTermAttribute
import org.apache.lucene.analysis.tokenattributes.OffsetAttribute
import org.apache.lucene.util.Version

import species.Species
import species.Language
import species.TaxonomyDefinition
import species.ScientificName.TaxonomyRank;
import species.participation.Recommendation
import species.search.Lookup
import species.search.Record
import species.search.*
import species.search.TSTLookup
import species.search.TSTAutocomplete
import species.search.TernaryTreeNode
import species.search.Record
import species.search.Lookup.LookupResult
import species.utils.ImageType;
import species.utils.ImageUtils;

import com.esotericsoftware.kryo.Kryo
import com.esotericsoftware.kryo.io.Output
import com.esotericsoftware.kryo.io.Input
import com.esotericsoftware.kryo.serializers.FieldSerializer
import com.esotericsoftware.kryo.serializers.*;
class NamesIndexerService {

	static transactional = false
	def grailsApplication;
    def utilsService;

	private static final log = LogFactory.getLog(this);
	private Lookup lookup = new TSTLookup();
	private boolean dirty = false;

	/**
	 * Rebuilds whole index and persists it. 
	 * Existing lookup is present 
	 */
	void rebuild() {
		log.info "Publishing names to autocomplete index";
		Lookup lookup1 = new TSTLookup();

		setDirty(false);

		def a = new StandardAnalyzer(Version.LUCENE_4_10_0)
		def analyzer = new ShingleAnalyzerWrapper(a, 2, 15, ' ', true, true,'')
		//analyzer.setOutputUnigrams(true);

		//TODO fetch in batches
		def startTime = System.currentTimeMillis()
		
		int limit = 200, offset = 0, noOfRecosAdded = 0;
        def recos;
		while(true){
            Recommendation.withNewTransaction([readOnly:true]) { status ->
			recos = Recommendation.listOrderById(max:limit, offset:offset, order: "asc")
			recos.each { reco ->
				if(addRecoWithAnalyzer(reco, analyzer, lookup1)){
					noOfRecosAdded++;
				}
			}
			
			offset = offset + limit;
			log.info "=========== total added recos == $noOfRecosAdded"
			if(!recos) return; //no more results;
            }
			if(!recos) break; //no more results;
            recos.clear();
		}
		
		synchronized(lookup) {
			lookup = lookup1;
		}

		log.info "Added recos : ${noOfRecosAdded}";
		log.info "Time taken to rebuild index : "+((System.currentTimeMillis() - startTime)/1000) + "(sec)"

		def indexStoreDir = grailsApplication.config.speciesPortal.nameSearch.indexStore;
		store(indexStoreDir);
	}

	/**
	 * 
	 * @param reco
	 * @return
	 */
	boolean add(Recommendation reco) {
		def a = new StandardAnalyzer(Version.LUCENE_4_10_0)
		/* setOutputUnigrams(boolean outputUnigrams) is deprecated....Confgure outputUnigrams during construction as shown below.*/
		//def analyzer = new ShingleAnalyzerWrapper(Analyzer, minShingleSize, maxShingleSize, tokenSeprator, outputUnigram, outputUnigramsIfNoShingles)
		def analyzer = new ShingleAnalyzerWrapper(a, 2, 15, " ", true, true, '')
		return addRecoWithAnalyzer(reco, analyzer, lookup);
	}

	/**
	 * 
	 * @param reco
	 * @param analyzer
	 * @param lookup
	 * @return
	 */
	private boolean addRecoWithAnalyzer(Recommendation reco, Analyzer analyzer, lookup) {
		if(isDirty()) {
			log.info "Rebuilding index as its dirty"
			rebuild();
			return;
		}

		//log.debug "Adding recommendation : "+reco.name + " with taxonConcept : "+reco.taxonConcept;

		boolean success = false;
		def species = getSpecies(reco.taxonConcept);
		def icon = getIconPath1(reco)
		
		//log.debug "Generating ngrams"
		def tokenStream = analyzer.tokenStream("name", new StringReader(reco.name));
		tokenStream.reset()
		OffsetAttribute offsetAttribute = tokenStream.getAttribute(OffsetAttribute.class);
		CharTermAttribute charTermAttribute = tokenStream.getAttribute(CharTermAttribute.class);
		def wt = 0;
		while (tokenStream.incrementToken()) {
			int startOffset = offsetAttribute.startOffset();
			int endOffset = offsetAttribute.endOffset();
			String term = charTermAttribute.toString()?.replaceAll("\u00A0|\u2007|\u202F", " ");
			//log.debug "Adding name term : "+term
			synchronized(lookup) {
				success |= lookup.add(term, new Record(originalName:reco.name, canonicalForm:reco.taxonConcept?.canonicalForm, isScientificName:reco.isScientificName, languageId:reco.languageId, icon:icon, wt:wt, speciesId:species?.id));
			}
		}
        tokenStream.close();
		return success;
	}

	private Species getSpecies(TaxonomyDefinition taxonConcept) {
		if(!taxonConcept) return null;
		return Species.get(taxonConcept.findSpeciesId());
	}
	
	private String getIconPath(mainImage){
        if(!mainImage) return null;
        return mainImage?mainImage.thumbnailUrl(grailsApplication.config.speciesPortal.resources.serverURL, null): null;
	}

	/**
	 * 
	 */
	boolean incrementByWt(String taxonConcept, int wt) {
		def record = lookup.getByName(taxonConcept);
		if(record) {
			synchronized(record) {
				record.wt += wt;
			}
			return true;
		} else {
			log.error "Couldnt find the record for term : "+taxonConcept
		}
		return false;
	}

	
	def getFormattedResult(List<LookupResult> lookupResults, inputTerm){
		def result = new ArrayList();
		lookupResults.each { lookupResult ->
			def term = lookupResult.key;
			def record = lookupResult.value;
			//			String name = term.replaceFirst(/(?i)${params.term}/, "<b>"+params.term+"</b>");
			//			String highlightedName = record.originalName.replaceFirst(/(?i)${term}/, name);
			String highlightedName = getLabel(record.originalName, inputTerm);
			String icon = record.icon
			
			def languageName = Language.read(record.languageId)?.name 
			result.add([value:record.originalName, label:highlightedName, desc:record.canonicalForm, icon:icon, speciesId:record.speciesId, languageName:languageName, "category":"Names"]);
		}
		return result;
	}
	
	String getIconPath1(Recommendation reco){
		String imagePath = null;
		def speciesInstance = getSpecies(reco.taxonConcept);
		if(speciesInstance){
			def mainImage = speciesInstance.mainImage()
			def speciesGroupIcon =  speciesInstance.fetchSpeciesGroup().icon(ImageType.ORIGINAL)
			if(mainImage?.fileName == speciesGroupIcon.fileName) {
				imagePath = mainImage.thumbnailUrl(null, '.png');
			} else{
				imagePath = mainImage?mainImage.thumbnailUrl():null;
			}
		}
		else{
			def mainImage = reco.taxonConcept?.group?.icon(ImageType.VERY_SMALL)
			imagePath = mainImage?.thumbnailUrl(null, '.png');
		}
		//println "=============== image path " + imagePath
		return imagePath
	}
	
    String getLabel(String originalName , String inputTerm) {
        int index = originalName.toLowerCase().indexOf(inputTerm.toLowerCase());

        //TODO:StringBuilder
        String name = new String();
        for(int i=0; i<originalName.size(); i++) {
            if(i == index) {
                name += "<b>"
            }
            name += originalName.charAt(i);
            if(i == index+inputTerm.length()-1) {
                name += "</b>"
            }
        }

        return name.toString();
    }


	/**
	 *
	 * @param query
	 * @return
	 */
	def suggest(params){
		log.info "Suggest name using params : "+params
		def result = new ArrayList();
		int max = params.max ? params.int('max'): 5;
        int rank = params.rank ? params.int('rank'):TaxonomyRank.SPECIES.ordinal();
        String term = params.term?:''
		if(term && rank >= TaxonomyRank.SPECIES.ordinal()) {
			List<LookupResult> lookupResults = lookup.lookup(term.toLowerCase(), true, max, params.nameFilter);
			result = getFormattedResult(lookupResults,  params.term)
		} else {
            List<LookupResult> lookupResults = TaxonomyDefinition.findAllByRankAndCanonicalFormIlike(rank, params.term+'%', [max:max, sort:'canonicalForm', offset:0]); 
            lookupResults.each { taxonDefinition ->
                result << ['value':taxonDefinition.canonicalForm, 'label':taxonDefinition.canonicalForm, 'category':TaxonomyRank.list()[rank].value()]
            }
        }
		log.debug "suggestion : "+result;
		return result;
	}
	
	public static final String FILENAME = "tstLookup.dat";

	/**
	 *
	 */
    synchronized boolean load(String storeDir) {
        File f = new File(storeDir, FILENAME);
        if(!f.exists() || !f.canRead()) {
            rebuild();
        } else {
            log.info "Loading autocomplete index from : "+f.getAbsolutePath();
            def startTime = System.currentTimeMillis()
            /*Kryo kryo = new Kryo();

            kryo.register(TSTLookup);
            kryo.register(TSTAutocomplete);
            kryo.register(TernaryTreeNode);
            kryo.register(Record);
            kryo.register(ArrayList.class, new CollectionSerializer());
            kryo.register(HashMap.class, new MapSerializer());
            kryo.setReferences(false);
            kryo.setRegistrationRequired(true);
            FieldSerializer someClassSerializer = new FieldSerializer(kryo, TSTLookup.class);
            kryo.register(TSTLookup.class, someClassSerializer)

            Input input = new Input(new FileInputStream(f));
            lookup = kryo.readObject(input, TSTLookup);
             */

            f.withObjectInputStream(lookup.getClass().classLoader){ ois ->
                lookup = ois.readObject( )
            }
            log.info "Loading autocomplete index done";
            log.info "Time taken to load names index : "+((System.currentTimeMillis() - startTime)/1000) + "(sec)"
            return true;
        }
    }

	/**
	 *
	 */
	synchronized boolean store(String storeDir) {
		File f = new File(storeDir);
		if(!f.exists()) {
			if(!f.mkdir()) {
				log.error "Could not create directory : "+storeDir;
			}
		}
		if (!f.exists() || !f.isDirectory() || !f.canWrite()) {
			return false;
		}

		def startTime = System.currentTimeMillis();
		File data = new File(f, FILENAME);
		data.withObjectOutputStream { oos ->
			oos.writeObject(lookup);
		}
		log.info "Time taken to store index : "+((System.currentTimeMillis() - startTime)/1000) + "(sec)"
		return true;
	}

    boolean storeKryo(String storeDir) {
        this.load(storeDir);
		File f = new File(storeDir);
		if(!f.exists()) {
			if(!f.mkdir()) {
				log.error "Could not create directory : "+storeDir;
			}
		}
		if (!f.exists() || !f.isDirectory() || !f.canWrite()) {
			return false;
		}

        Kryo kryo = new Kryo();

        kryo.register(TSTLookup);
        kryo.register(TSTAutocomplete);
        kryo.register(TernaryTreeNode);
        kryo.register(Record);
        kryo.register(ArrayList.class, new CollectionSerializer());
        kryo.register(HashMap.class, new MapSerializer());
        kryo.setReferences(false);
        kryo.setRegistrationRequired(true);
        FieldSerializer someClassSerializer = new FieldSerializer(kryo, TSTLookup.class);
        kryo.register(TSTLookup.class, someClassSerializer)

		def startTime = System.currentTimeMillis();
		File data = new File(f, FILENAME+".kryo");
        
        Output output = new Output(new FileOutputStream(data));
        kryo.writeObject(output, lookup);
        output.close();
        println "==========================="
        Input input = new Input(new FileInputStream(storeDir+'/'+FILENAME+".kryo"));
        def lookup2 = kryo.readObject(input, TSTLookup);
        println lookup2;

        utilsService.benchmark('lookup2.lookup') {
        println lookup2.lookup('ruf', true, 5, null);
        }
        utilsService.benchmark('lookup.lookup') {
        println lookup.lookup('ruf', true, 5, null);
        }

        input.close();

		log.info "Time taken to store index : "+((System.currentTimeMillis() - startTime)/1000) + "(sec)"
		return true;

    }


	/**
	 * 	
	 */
	synchronized void setDirty(boolean flag) {
		dirty = flag;
	}

	/**
	 * 
	 */
	boolean isDirty() {
		return dirty;
	}
}
