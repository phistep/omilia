$(document).ready(function(){
	$('[rel=tooltip]').tooltip();

	$(".fav").on("click", function(event){
		var tis = $(this);
		$.ajax({
			'url': '/show/' + tis.attr('url'),
			'dataType': 'text',
			'async': true,
			'success': function(response){
				console.log('success! ' + response);
				if (tis.hasClass('faved')){
					tis.removeClass('faved');
				} else {
					tis.addClass('faved');
				}
				if(tis.parent().get(0).tagName == 'LI'){
					tis.parent().fadeOut(500, function(){ tis.parent().remove() });
				}
			},
			'error': function(response){
				console.log('error! ' + response);
				// display helpful tooltip
			 },
			'type': tis.hasClass('faved') ? 'DELETE' : 'PUT'
		});
	});

	$("input[type=checkbox].episode").on("change", function(event){
		var tis = $(this);
		var season = $(this).attr('id').split('_')[0];
		var episode = $(this).attr('id').split('_')[1];
		var show = location.pathname.split('/').pop();
		$.ajax({
			'url': '/show/' + show + '/' + season + '/' + episode,
			'dataType': 'text',
			'async': true,
			'success': function(response){
				console.log('success! ' + response);
			},
			'error': function(response){
				console.log('error! ' + response);
				// display helpful tooltip
				if (tis.attr('checked') == 'checked'){
					tis.removeAttr('checked');
				} else {
					tis.attr('checked', 'checked');
				}
			 },
			'type': tis.attr('checked') == 'checked' ? 'PUT' : 'DELETE'
		});

	});
});
