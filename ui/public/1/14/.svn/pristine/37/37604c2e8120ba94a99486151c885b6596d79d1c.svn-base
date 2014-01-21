document.observe("dom:loaded", function() {
    $('enableArchivedCB').checked = window.localStorage.M_enableArchivedCBValue == '1';
    enableArchivedCBHandler($('enableArchivedCB').checked);
});

function enableArchivedCBHandler(checked) {
    $$('#list_clients option.inactive').each(function(item) {
        item.setStyle({display: checked ? 'block' : 'none'});
    });
    window.localStorage.M_enableArchivedCBValue = checked ? '1' : '0';
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
