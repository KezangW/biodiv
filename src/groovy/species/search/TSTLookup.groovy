package species.search

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map;

import species.search.Lookup.LookupResult;
import species.search.Lookup.LookupPriorityQueue;

import org.apache.commons.beanutils.PropertyUtils;
import org.apache.lucene.util.PriorityQueue;

class TSTLookup<E> extends Lookup<E> implements Serializable {

	private static final long serialVersionUID = 7526472295622776157L;
	
	TernaryTreeNode root;
	TSTAutocomplete autocomplete = new TSTAutocomplete();
	Map valueKeys;
	
	TSTLookup() {
		valueKeys = new HashMap()
	}
	
	/**
	 * Adds a key with value into the index.
	 * If there are already some values at this node this new value is appended to this list
	 * @param key
	 * @param value
	 * @return
	 */
	boolean add(String key, Object value) {
		if(key) {
			/*
			if(valueKeys.containsKey(value.originalName)) {
				value = valueKeys.get(value.originalName);
			} else {
				valueKeys.put(value.originalName, value)
			}
			*/
			root = autocomplete.insert(root, key.trim(), value, 0);
			return true;
		} else
			return false;
	}

	/**
	 * returns values present below node with prefix "key".
	 * @param key
	 * @param onlyMorePopular
	 * @param num
	 * @return
	 */
	List<LookupResult> lookup(String key, boolean onlyMorePopular, int num, String nameFilter) {
		List<TernaryTreeNode> list = autocomplete.prefixCompletion(root, key, 0);
		List<LookupResult> res = new ArrayList<LookupResult>();
		if (!list) {
			return res;
		}

		key = key.toLowerCase();
		int maxCnt = Math.min(num, list.size());
		HashSet added = new HashSet();
		if (onlyMorePopular) {
			LookupPriorityQueue queue = new LookupPriorityQueue(num);
			for (TernaryTreeNode ttn : list) {
				for (obj in ttn.val) {
					//println "=====" +  obj.recoId + "  " + obj.originalName+"   "+obj.acceptedName+"  "+obj.wt 
					if(nameFilter && nameFilter.equalsIgnoreCase("scientificNames") && !obj.isScientificName){
						continue;
					}
					if(nameFilter && nameFilter.equalsIgnoreCase("commonNames") && obj.isScientificName){
						continue;
					}
					
					if(!added.contains(obj)) {
						added.add(obj);
						//TODO:Hack to push records with exact prefix to the top
						//clone not supported 
						def record = new Record()
						PropertyUtils.copyProperties(record, obj);
						String name = record.originalName.toLowerCase();
						if(name.startsWith(key)) {
							record.wt += 3;
						}
						if(record.acceptedName){
							record.wt += 3;
							
							//directly pointing to accepted name
							if(!record.synName){
								record.wt += 3;
							}
						}
						
						LookupResult r = new LookupResult(ttn.token, record);
						queue.insertWithOverflow(r);
					}
				}
			}
			for (LookupResult lr : queue.getResults()) {
				res.add(lr);
			}
		} else {
			for (int i = 0; i < maxCnt; i++) {
				TernaryTreeNode ttn = list.get(i);				
				for (obj in ttn.val) {
					if(!added.contains(obj)) {
						added.add(obj);
						res.add(new LookupResult(ttn.token, obj));
					}
				}
			}
		}
		return res;
	}

	/**
	 * returns all objects stored at this node
	 * @param key
	 * @return
	 */
	List get(String key) {
		List<TernaryTreeNode> list = autocomplete.prefixCompletion(root, key, 0);
		if (list == null || list.isEmpty()) {
			return null;
		}
		for (TernaryTreeNode n : list) {
			if (n.token.equals(key)) {
				return n.val;
			}
		}
		return null;
	}
	
	/**
	 * Get record by original name
	 */
//	Object getByName(String originalName) {
//		return valueKeys.get(originalName);
//	}
}
