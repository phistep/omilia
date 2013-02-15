$(document).ready(function(){
	// scroll away or auto-focus search field
	if(location.pathname.split('/')[1] == 'show'){
		window.scroll(0,60);
	} else {
		$('#search').focus();
	}


	// activate tooltips
	$('[rel=tooltip]').tooltip();


	// activate popover
	$('#custom-url-input').popover({
		'html': true,
		'placement': 'bottom',
		'title': 'Set your custom show URL',
		'content': '<p>You can set your own URL for this show, so the title above will be linked there.</p>' +
		           '<p>If you use the variables <code>%s</code> and <code>%e</code> to insert the season and episode number, every episode will be directly deep-linked!</p>' +
		           '<p>In case you need leading zeros (like <code>05</code>), add as many <code>0</code> between <code>%</code> and <code>s</code>/<code>e</code> as you need digits. For example <code>%000e</code> will produce: <code>003</code> and <code>034</code>.</p>' +
		           '<p>So when you happen to find an episode URL like this: <code>&hellip;.com/all/s04e13</code> the custom URL would go like this: <code>&hellip;.com/all/s%00se%00e</code>.</p>' +
		           '<p class="muted">Hint: You can also link to local files on your computer by using <code>file://</code>.</p>',
		'trigger': 'focus',
	});
	$('#custom-url-form .add-on').on('click', function(e){
		$('#custom-url-input').focus();
	});


	// show modals
	if(window.location.hash == '#delete-account'){
		$('#delete-account').modal();
	}
	if(window.location.hash == '#change-password'){
		$('#change-password').modal();
	}

	
	// Change button label for login-register-button
	$('.login-form .password-repeat').keyup(function(){
		if($(this).val() == ''){
			$('.login-register-button').text('Login');
		} else {
			$('.login-register-button').text('Register');
		}
	});


	// search field suggestions
	var suggestions = [];
	$.ajax({
		'url': '/suggest',
		'dataType': 'json',
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
					tis.addClass('changed');
					tis.tooltip('destroy');
					tis.attr('title', 'Add to favorites');
					tis.tooltip();
				},
				function(resonse){}
			);
		}
		else if(tis.hasClass('icon-star')){
			faving(
				'PUT',
				tis.attr('show'),
				function(response){
					tis.addClass('changed');
					tis.tooltip('destroy');
					tis.attr('title', 'Delete from favorites');
					tis.tooltip();
				},
				function(resonse){}
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
				tis.parent().animate(
					{ opacity:0, height:0 },
					500,
					function(){
						tis.parent().remove();
					}
				);
			},
			function(resonse){}
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
					tis.addClass('remove');
					tis.removeClass('add');
					tis.text('Remove from favorites');
					$('#custom-url-form').css('display', 'block');
				},
				function(resonse){}
			);
		}
		else if(tis.hasClass('remove')){
			faving(
				'DELETE',
				tis.attr('show'),
				function(response){
					tis.addClass('add');
					tis.removeClass('remove');
					tis.text('Add to favorites');
					$('#custom-url-form').css('display', 'none');
					$('#custom-url-input').attr('value', '');
					$('span.episode-name').unwrap();
					$('span.show-name').unwrap();
					$('input[type=checkbox]').prop('checked', false);
				},
				function(resonse){}
			);
		}
		return false;
	});


	// update info
	var set_gradient = function(element, progress){
		element.css({
			'background' :	'-webkit-gradient(linear, left top, right top, color-stop(' + progress + '% ,rgba(0, 0, 0, .05)), color-stop(' + progress + '%, rgba(0, 0, 0, 0)), color-stop(100%, rgba(0, 0, 0, 0))),' +
							'-webkit-gradient(linear, left top, left bottom, color-stop(0%, rgb(255, 255, 255)), color-stop(100%, rgb(242, 242, 242)))'
		});
		element.css({
			'background' :	'-webkit-linear-gradient(left,      rgba(0, 0, 0, .05) ' + progress + '%, rgba(0, 0, 0, 0) ' + progress + '%, rgba(0, 0, 0, 0)),' +
							'-webkit-linear-gradient(top,       rgb(255, 255, 255), rgb(242, 242, 242))'
		});
		element.css({
			'background' :	        'linear-gradient(to right,  rgba(0, 0, 0, .05) ' + progress + '%, rgba(0, 0, 0, 0) ' + progress + '%, rgba(0, 0, 0, 0)),' +
							        'linear-gradient(to bottom, rgb(255, 255, 255), rgb(242, 242, 242))'
		}); 
	}


	// watching episodes
	var watching = function(action, async, show, id, successCallback, errorCallback){
		// js 1.7, does not work in Chrome
		// https://developer.mozilla.org/en-US/docs/JavaScript/New_in_JavaScript/1.7#Destructuring_assignment_%28Merge_into_own_page.2Fsection%29
		// var [season, episode] = id.split('_');
		var season = id.split('_')[0];
		var episode = id.split('_')[1];
		$.ajax({
			'url': '/show/' + show + '/' + season + '/' + episode,
			'dataType': 'text',
			'async': async,
			'success': successCallback,
			'error': errorCallback,
			'type': action
		});
	}
	
	$('input[type=checkbox].episode').on('change', function(event){
		var tis = $(this);
		watching(
			tis.prop('checked') ? 'PUT' : 'DELETE',
			tis.prop('no-async') ? false : true,
			show = location.pathname.split('/').pop(),
			tis.attr('id'),
			function(response){},
			function(response){
				faving(
					'PUT',
					show,
					function(res){
						var btn = $('#favbtn');
						btn.addClass('remove');
						btn.removeClass('add');
						btn.text('Remove from favorites');
						$('#custom-url-form').css('display', 'block');
						watching(
							tis.prop('checked') ? 'PUT' : 'DELETE',
							true,
							show,
							tis.attr('id'),
							function(response){},
							function(res){
								if (tis.prop('checked')){
									tis.prop('checked', false);
								} else {
									tis.prop('checked', true);
								}
							}
						);
					},
					function(res){
						if (tis.prop('checked')){
							tis.prop('checked', false);
						} else {
							tis.prop('checked', true);
						}
					}
				);
			}
		);
	});

	$('button.next-up').on('click', function(event){
		var tis = $(this);
		tis.button('loading');
		watching(
			'PUT',
			false,
			tis.attr('show'),
			tis.attr('next-up'),
			function(response){
				var info;
				$.ajax({
					'url': '/info/' + tis.attr('show'),
					'dataType': 'json',
					'async': false,
					'success': function(response){ info = response},
					'error': function(response){info = null},
					'type': 'GET'
				});
				if(info){
					if(info.unwatched && info.next_season && info.next_episode){
						tis.attr('next-up', info.next_id);
						tis.siblings('.badge.unwatched').text(info.unwatched);
						tis.siblings('.badge.unwatched').tooltip('destroy');
						tis.siblings('.badge.unwatched').attr('title', info.unwatched + ' unwatched episode' + (info.unwatched > 1 ? 's' : ''));
						tis.siblings('.badge.unwatched').tooltip();
						tis.tooltip('destroy');
						tis.attr('title', 'Mark s' + info.next_season + 'e' + info.next_episode + ' as watched')
						tis.tooltip();
						set_gradient(tis.parent(), info.progress);
						tis.button('reset');
						tis.text('next up: s' + info.next_season + 'e' + info.next_episode);
					} else if(info.unwatched && !info.next_season && !info.next_episode){
						tis.siblings('.badge.unwatched').text(info.unwatched);
						tis.siblings('.badge.unwatched').tooltip('destroy');
						tis.siblings('.badge.unwatched').attr('title', info.unwatched + ' unwatched episode' + (info.unwatched > 1 ? 's' : ''));
						tis.siblings('.badge.unwatched').tooltip();
						set_gradient(tis.parent(), info.progress);
						tis.tooltip('destroy');
						tis.remove();
					} else {
						tis.siblings('.badge.unwatched').html('<i class="icon-ok icon-white"></i>');
						tis.siblings('.badge.unwatched').tooltip('destroy');
						tis.siblings('.badge.unwatched').attr('title', 'No unwatched episodes');
						tis.siblings('.badge.unwatched').tooltip();
						set_gradient(tis.parent(), info.progress);
						tis.tooltip('destroy');
						tis.remove();
					}
				} else {
					tis.button('reset');
				}
			},
			function(response){
				tis.button('reset');
			}
		);
		return false;
	});


	// mark all in season as watched
	$('a[watch-season]').on('click', function(){
		$('input[type=checkbox].episode[id^=' +$(this).attr('watch-season') + '_]:not(:checked)').prop('no-async', true).trigger('click').prop('no-sync', false);
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

