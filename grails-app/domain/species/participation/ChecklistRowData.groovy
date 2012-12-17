package species.participation

class ChecklistRowData implements Comparable {
	
	String key;
	String value;
	int rowId;
	//to keep column order same as raw file
	int columnOrderId
	//for scientific name
	Recommendation reco;
		
	static belongsTo = [checklist:Checklist];

	static constraints = {
		value nullable:true;
		reco  nullable:true;
	}

	static mapping = {
		version : false;
		value type:'text';
	}	

	@Override
	public int compareTo(Object o) {
		// TODO Auto-generated method stub
		int rowOrder = rowId.compareTo(o.rowId)
		if(rowOrder == 0){
			return columnOrderId.compareTo(o.columnOrderId)
		}
		return rowOrder
	}
}