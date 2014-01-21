document.observe("dom:loaded", function() {
	jQuery('.f_geo').remove();

	$('f_cpoint_name').up('dl').remove();
	$('f_site_paid').up('dl').remove();
    $('enableExtraFilterCB').checked = (window.localStorage.CPD_enableExtraFilter == '1' || checkExtraFields());
    enableExtraFilterCBHandler($('enableExtraFilterCB').checked);
});

function enableExtraFilterCBHandler(checked) {
    $('extra_filter_items').setStyle({display: checked ? 'block' : 'none'});
    window.localStorage.CPD_enableExtraFilter = checked ? '1' : '0';

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

// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	console.info('start')
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigCpointDaily',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});

