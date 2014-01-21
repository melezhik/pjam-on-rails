document.observe("dom:loaded", function() {
    $('enableArchivedCB').checked = window.localStorage.CP_enableArchivedCBValue == '1';
    enableArchivedCBHandler($('enableArchivedCB').checked);

    $('enableExtraFilterCB').checked = (window.localStorage.CP_enableExtraFilter == '1' || checkExtraFields());
    enableExtraFilterCBHandler($('enableExtraFilterCB').checked);
});

function enableArchivedCBHandler(checked) {
    $$('#list_clients option.inactive').each(function(item) {
        item.setStyle({display: checked ? 'block' : 'none'});
    });
    window.localStorage.CP_enableArchivedCBValue = checked ? '1' : '0';
}

function enableExtraFilterCBHandler(checked) {
    $('extra_filter_items').setStyle({display: checked ? 'block' : 'none'});
    window.localStorage.CP_enableExtraFilter = checked ? '1' : '0';
	$('extra_filter_items').select("input,select").each(function(elm) {
		elm.disabled = !checked;
	});
}

function submitOnSelect(elmSelect) {
    var option = elmSelect.options[elmSelect.selectedIndex];
    if (Element.hasClassName(option, 'group')) {
        $('agency_id').value = option['value'];
        $('client_id').value = '';
    } else {
        $('client_id').value = option['value'];
        $('agency_id').value = '';
    }
    var sel= $("list_format");
    var opt = sel.childElements().find(function(item) {return item.value == 'client'});
    opt.disabled = false;
    Form.Element.setValue(sel, 'client');
    document.filter.submit();
}

function checkExtraFields() {
	return $('extra_filter_items').select("input,select").any(function(elm) {
		return elm.name && elm.value;
	});
}

function resetExtraFields() {
	resetFields($('extra_filter_items'));
}

// запуск обработчика, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigControlpoints',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
