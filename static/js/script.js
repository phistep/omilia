$(document).ready(function(){
	// scroll away or auto-focus search field
	if(location.pathname.split('/')[1] == 'show'){
		window.scroll(0,60);
	} else {
		$('#search').focus();
	}


	// activate tooltips
	$('[rel=tooltip]').tooltip();


	// search field suggestions
	var suggestions = [];
	$.ajax({
		'url': '/suggest',
		dataType: 'json',
		'async': false,
		'success': function(response){
			suggestions = response;
		},
		'type': 'GET'
	});

	$('#search').typeahead({
		'source': suggestions
	});
	

	// star hover toggle
	$('.fav[class*=icon-star]').mouseenter(function(e){
		if($(this).hasClass('icon-star')){
			$(this).removeClass('icon-star').addClass('icon-star-empty');
		}
		else if($(this).hasClass('icon-star-empty')){
			$(this).addClass('icon-star').removeClass('icon-star-empty');
		}
	});

	$('.fav[class*=icon-star]').mouseleave(function(e){
		if($(this).hasClass('changed')){
			$(this).removeClass('changed');
		}
		else{
			if($(this).hasClass('icon-star')){
				$(this).removeClass('icon-star').addClass('icon-star-empty');
			}
			else if($(this).hasClass('icon-star-empty')){
				$(this).addClass('icon-star').removeClass('icon-star-empty');
			}
		}
	});


	// Faving shows
	var faving = function(action, show, successCallback, errorCallback){
		$.ajax({
			'url': '/show/' + show,
			'dataType': 'text',
			'async': true,
			'success': successCallback,
			'error': errorCallback,
			'type': action
		});
	}

	$('li.search .fav[class*=icon-star]').on('click', function(e){
		tis = $(this);
		if(tis.hasClass('icon-star-empty')){
			faving(
				'DELETE',
				tis.attr('show'),
				function(response){
					console.log('sucess');
					tis.addClass('changed');
					tis.tooltip('destroy');
					tis.attr('title', 'Add to favorites');
					tis.tooltip();
				},
				function(resonse){
					console.log('error');
				}
			);
		}
		else if(tis.hasClass('icon-star')){
			faving(
				'PUT',
				tis.attr('show'),
				function(response){
					console.log('sucess');
					tis.addClass('changed');
					tis.tooltip('destroy');
					tis.attr('title', 'Delete from favorites');
					tis.tooltip();
				},
				function(resonse){
					console.log('error');
				}
			);
		}
		return false;
	});

	$('li.home i.fav.icon-star').on('click', function(e){
		var tis = $(this);
		faving(
			'DELETE',
			tis.attr('show'),
			function(response){
				console.log('sucess');
				tis.parent().animate(
					{ opacity:0, height:0 },
					500,
					function(){
						tis.parent().remove();
					}
				);
			},
			function(resonse){
				console.log('error');
			}
		);
		return false;
	});

	$('button.fav').on('click', function(e){
		var tis = $(this);
		if(tis.hasClass('add')){
			faving(
				'PUT',
				tis.attr('show'),
				function(response){
					console.log('sucess');
					tis.addClass('remove');
					tis.removeClass('add');
					tis.text('Remove from favorites');
				},
				function(resonse){
					console.log('error aaaaaaadd');
				}
			);
		}
		else if(tis.hasClass('remove')){
			faving(
				'DELETE',
				tis.attr('show'),
				function(response){
					console.log('sucess');
					tis.addClass('add');
					tis.removeClass('remove');
					tis.text('Add to favorites');
					$('input[type=checkbox]').removeAttr('checked');
				},
				function(resonse){
					console.log('error remooooooovee');
				}
			);
		}
		return false;
	});


	// watch ajax
	$("input[type=checkbox].episode").on("change", function(event){
		var tis = $(this);
		var [season, episode] = tis.attr('id').split('_');
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
				/* Only reasonable if auto-adding will be removed from server.
				faving(
					'PUT',
					show,
					function(res){
						console.log('success');
						var btn = $('#favbtn');
						btn.addClass('remove');
						btn.removeClass('add');
						btn.text('Remove from favorites');
					},
					function(res){
						if (tis.attr('checked') == 'checked'){
							tis.removeAttr('checked');
						} else {
							tis.attr('checked', 'checked');
						}
					}
				);
				*/
			 },
			'type': tis.attr('checked') == 'checked' ? 'PUT' : 'DELETE'
		});

	});
});

