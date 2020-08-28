(function(){
	if (window.NEBULAHASADDEDTOUCHEVENT) {
		return;
	};
	function onDOMReady(callback){
	 	var readyRE = /complete|loaded|interactive/;
	 	 if(readyRE.test(document.readyState)) {
			 setTimeout(function() {
			            callback();
			            }, 1);
		 } else {
		 	document.defaultView.addEventListener('DOMContentLoaded', function () {
		                                       callback();
		                                       }, false);
		 }
	}
 	onDOMReady(function(){
     		document.addEventListener("touchstart",function(event){
                                      AlipayJSBridge.call("reportClickTime");
                                      }, false);
    });
 	window.NEBULAHASADDEDTOUCHEVENT = true;
 })();
