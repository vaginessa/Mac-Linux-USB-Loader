$(document).ready(function() {
	$("#advert").hide();
	$("#advert").click(function() {
		$("#advert").hide();
	});

	$(".download-btn").click(function() {
		$("#advert").show();
	})

	$("#payByIpnForm").submit(function() {
		_gat._getTracker("UA-46715734-1")._trackEvent("Events", "Donate Clicked");
	});

	$("#downloadLink").submit(function() {
		_gat._getTracker("UA-46715734-1")._trackEvent("Events", "Download MLUL");
	});

	$(".download-btn").attr("href", "javascript:void(0);");
});
