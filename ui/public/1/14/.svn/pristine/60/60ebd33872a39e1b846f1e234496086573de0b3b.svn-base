document.observe("dom:loaded", function() {
    $('enableExtraFilterCB').checked = (window.localStorage.M1_enableExtraFilter == '1' || checkExtraFields());
    enableExtraFilterCBHandler($('enableExtraFilterCB').checked);
    jQuery('#groupAPISelector').bind('change', openGroupAPIPage);
});

function enableExtraFilterCBHandler(checked) {
    $('extra_filter_items').setStyle({display: checked ? 'block' : 'none'});
    window.localStorage.M1_enableExtraFilter = checked ? '1' : '0';

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
    if (!el.val()) return false;
    var domain = el.data('group_api_domain_name');
    var hashTag = '#/mediaplan/' + el.val() + '/' + el.data('mediaplan-id');
    window.open(domain + hashTag, '_group-api');
}

// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigMediaplan',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
