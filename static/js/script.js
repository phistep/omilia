$(document).ready(function(){

	if(location.pathname.split('/')[1] == 'show'){
		window.scroll(0,60);
	} else {
		$('#search').focus();
	}

	$('[rel=tooltip]').tooltip();

	$(".fav").on("click", function(event){
		var tis = $(this);
		$.ajax({
			'url': '/show/' + tis.attr('show'),
			'dataType': 'text',
			'async': true,
			'success': function(response){
				console.log('success! ' + response);
				if (tis.hasClass('icon-star')){
					tis.removeClass('icon-star');
					tis.addClass('icon-star-empty');
				} else {
					tis.addClass('icon-star');
					tis.removeClass('icon-star-empty');
				}
				if(tis.parent().get(0).tagName == 'LI'){
				//	tis.parent().fadeOut(500, function(){ tis.parent().remove() });
				tis.parent().animate(
					{ opacity:0, height:0 },
					500,
					function(){
						tis.parent().remove();
					});
				}
			},
			'error': function(response){
				console.log('error! ' + response);
				// display helpful tooltip
			 },
			'type': tis.hasClass('icon-star') ? 'DELETE' : 'PUT'
		});
		return false;
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
