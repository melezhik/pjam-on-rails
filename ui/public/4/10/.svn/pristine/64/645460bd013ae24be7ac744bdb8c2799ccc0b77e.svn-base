document.observe("dom:loaded", function() {
    jQuery('.f_geo').remove();
    $('f_cpoint_name').up('dl').remove();
    $('f_site_paid').up('dl').remove();
    $('enableExtraFilterCB').checked = (window.localStorage.CP1_enableExtraFilter == '1' || checkExtraFields());
    enableExtraFilterCBHandler($('enableExtraFilterCB').checked);
    jQuery('#groupAPISelector').bind('change', openGroupAPIPage);
});

function enableExtraFilterCBHandler(checked) {
    $('extra_filter_items').setStyle({display: checked ? 'block' : 'none'});
    window.localStorage.CP1_enableExtraFilter = checked ? '1' : '0';

	// Выключаем поля для скрытого расширенного фильтра
	$('extra_filter_items').select("input,select").each(function(elm) {
		elm.disabled = !checked;
	});
}

function checkExtraFields() {
	return $('extra_filter_items').select("input,select").any(function(elm) {
		return elm.name && elm.value;
	});
}

function resetExtraFields() {
	resetFields($('extra_filter_items'));
}


function openGroupAPIPage(e) {
	var el = jQuery(e.target);
	if (!el.val()) { return false; }
	var domain = el.data('group_api_domain_name');
	var hashTag = '#/mediaplan/' + el.val() + '/' + el.data('mediaplan-id');
	// перед переходом в groupAPI создаем ресурс с профайлами, показанными на текущей странице.
	jQuery.when(createProfileGroup())
		.done(function(res) {
			var uri = domain + hashTag + '/profiles/' + res.GUID;
			window.open(uri, '_group-api');
		})
		.fail(function (res) {
			console.warn('group NOT created: ', res);
		});
}

function createProfileGroup() {
	var guids = [];
	jQuery('tbody tr.placement', jQuery('.panel-tbody table')).each(function(id, el) {
		guids.push(jQuery(el).data('placement-id'));
	});
	return jQuery.ajax({
		url: '/create_placements_profiles',
		type: 'POST',
		dataType: 'json',
		contentType: 'application/json',
		data: JSON.stringify({
			lines: guids
		}),
		beforeSend: function (xhr) {
			xhr.setRequestHeader("CasXNoRedirect", "1");
		}
	});

//	return new jQuery.Deferred().resolve();
}

// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigCpoint',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
