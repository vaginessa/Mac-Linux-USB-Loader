$(document).ready(function() {
	$("#advert").hide();
	$("#advert").click(function() {
		$("#advert").hide();
	});
	
	$(".download-btn").click(function() {
		$("#advert").show();
	})
	$(".download-btn").attr("href", "javascript:void(0);");
});

var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));

try {
var pageTracker = _gat._getTracker("UA-46715734-1");
pageTracker._trackPageview();
} catch(err) {}
