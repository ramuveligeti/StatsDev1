/* potentially can contains a set of remote method to interact with Zeacom via remote-action
 */
public class ZeacomRemoteActionController {

	private ID objectId{set;get;}
	public ZeacomRemoteActionController (ApexPages.StandardController std){
		objectId=std.getId();
	}

	public PageReference finishPreviewing() {
		boolean inlineCallout = true;
		CSRActionRecorder.finishPreviewing(objectId, DateTime.now(), inlineCallout);
		return null;
	}
}