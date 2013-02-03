$(document).ready(function(){
	// scroll away or auto-focus search field
	if(location.pathname.split('/')[1] == 'show'){
		window.scroll(0,60);
	} else {
		$('#search').focus();
	}


	// activate tooltips
	$('[rel=tooltip]').tooltip();


	// show modals
	if(window.location.hash == '#delete-account'){
		$('#delete-account').modal();
	}
	if(window.location.hash == '#change-password'){
		$('#change-password').modal();
	}

	
	// Change button label for login-register-button
	$('#login-form #password_repeat').keyup(function(){
		if($(this).val() == ''){
			$('#login-register-button').text('Login');
		} else {
			$('#login-register-button').text('Register');
		}
	});


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
					$('input[type=checkbox]').prop('checked', false);
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
		// js 1.7, does not work in Chrome
		// https://developer.mozilla.org/en-US/docs/JavaScript/New_in_JavaScript/1.7#Destructuring_assignment_%28Merge_into_own_page.2Fsection%29
		// var [season, episode] = tis.attr('id').split('_');
		var season = tis.attr('id').split('_')[0];
		var episode = tis.attr('id').split('_')[1];
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
						if (tis.prop('checked')){
							tis.prop('checked', false);
						} else {
							tis.prop('checked', true);
						}
					}
				);
				*/
			 },
			'type': tis.prop('checked') ? 'PUT' : 'DELETE'
		});
	});


	// mark all in season as watched
	$('a[watch-season]').on('click', function(){
		$('input[type=checkbox].episode[id^=' +$(this).attr('watch-season') + '_]:not(:checked)').trigger('click');
	});


	// collapsing
	$('.season.collapsed ol').hide();

	$('i[class*=icon-chevron]').on('click', function(){
		tis = $(this);
		var show = location.pathname.split('/').pop();
		$.ajax({
			'url': '/collapse/' + show + '/' + tis.attr('collapse-season'),
			'dataType': 'text',
			'async': true,
			'success': function(response){
				console.log('success! ' + response);
			},
			'type': tis.hasClass('icon-chevron-down') ? 'PUT' : 'DELETE'
		});

		if(tis.hasClass('icon-chevron-right')){
			tis.addClass('icon-chevron-down');
			tis.removeClass('icon-chevron-right')
		}
		else if(tis.hasClass('icon-chevron-down')){
			tis.removeClass('icon-chevron-down');
			tis.addClass('icon-chevron-right')
		}
		tis.parent().siblings('ol').slideToggle();
	});
});

