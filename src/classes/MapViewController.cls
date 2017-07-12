public with sharing class MapViewController {
    
    public transient String mapURL {get; private set;}

    public MapViewController(){
    	if(Logger.isEnabled()){
    		System.debug('Started controller constructor');
    	}
        mapURL = SystemSettings.getValue('map.url');
    }
}