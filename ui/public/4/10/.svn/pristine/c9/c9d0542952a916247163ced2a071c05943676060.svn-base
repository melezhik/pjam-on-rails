function delete_object(url, comment) {
    if (confirm(comment)) {
        var req = new Ajax.Request(url, {
                asynchronous: true,
                method: 'get',
                onComplete: function (res) {
                    if (res.status == 200 ) {
                        window.location.reload();
                    } else {
                        alert('ERROR: ' + res.responseText);
                    }
                },
                onError: function (res) {
                    alert('SERVER INTERNAL ERROR');
                }
            }
        );
    }
}


jQuery.datepicker.setDefaults({
	numberOfMonths: 1,
	showOtherMonths: true,
	selectOtherMonths: true,
	changeMonth: false,
	changeYear: false,
	dateFormat: 'd MM yyг.',
	navigationAsDateFormat: true,
	yearSuffix: 'г.',
//	showOn: "both",
	buttonText: '',
	showButtonPanel: true
});


function clearBlankDates(dateText, inst) {
	var instance = inst || jQuery( this ).data( "datepicker" );
    if (!dateText) {
	    jQuery(instance).datepicker('setDate', null);
    }
}

function initDateRange(start, stop) {
	var elmStart, elmStop;

	start['extra'] || (start['extra'] = {});
	start['extra']['beforeShow'] = function() {
		var maxDate = jQuery( elmStop ).datepicker('getDate');
		jQuery(this).datepicker( "option", "maxDate", maxDate || null );
	};

	stop['extra'] || (stop['extra'] = {});
	stop['extra']['beforeShow'] = function() {
		var minDate = jQuery( elmStart ).datepicker('getDate');
		jQuery(this).datepicker( "option", "minDate", minDate || null );
	};

	elmStart = initDateSelect(start);
	elmStop = initDateSelect(stop);
}

function initDateSelect(config) {
	var input, elmValue, currentDate, date;

	try {
		elmValue = config['elmValue'] = config['elmValue'] ? document.getElementsByName(config['elmValue']) : null;

		currentDate = elmValue ? jQuery(elmValue).val() : null;
		date = jQuery.datepicker.parseDate('yy-mm-dd', currentDate);

		if (elmValue && jQuery(elmValue).attr('readOnly')) {
			input = jQuery("<span>").text(jQuery.datepicker.formatDate( 'd MM yyг.', date));
		} else {
			input = jQuery(config['elmInput'] || "<input>")
				.datepicker(Object.extend({
					altField: jQuery(elmValue),
					altFormat: 'yy-mm-dd',
					dateFormat: 'd MM yy'
				}, config['extra'] || {}));

			// обработка атрибута на разрешение очистки поля с датой.
			if (jQuery(elmValue).attr('data-reset-enable')) {
				setTimeout(function() {
					var iconClear = jQuery("<span class='ui-icon ui-icon-close ui-datepicker-icon-clear' title='Очистить поле'></span>");
					jQuery(iconClear).click(function() {clearBlankDates(null, input);} );
					jQuery(input).after(jQuery(iconClear));
				}, 1);
			}

			if (currentDate) {
				jQuery(input).datepicker("setDate", jQuery.datepicker.parseDate('yy-mm-dd', currentDate));
			}
			jQuery(input).attr('readOnly', true);
		}

		if (config['holder']) {
			jQuery(config['holder']).append(input);
		}
	} catch(e) {
		console.error(e);
	}

	return input;
}

function resetFields(container) {
	container.select("select,input").each(function(elm) {
		switch(true) {
			case (elm.type && elm.type == 'button'):
				break;
			case (elm.type && elm.type == 'checkbox'):
				elm.checked = false;
				break;
			default:
				elm.value = '';
				break;
		}
	});
}

function showCPointDialog(id) {
	showDialog(id);
	onShowCPointDialog();
}

function onShowCPointDialog() {
	var form = $(document.cpointForm);
	var inpSZ = form['siteZoneId'];
	var inpPageCount = form['leadPagesNum'];

	var observer = function(elm, ev) {
		if (ev) elm.enable();
		var other = (elm === inpSZ ? inpPageCount : inpSZ);
		other[elm.value?'disable':'enable']();
	};

	inpSZ.observe('keyup', observer.bind(this, inpSZ));
	inpPageCount.observe('keyup', observer.bind(this, inpPageCount));

	// Зависимость {тип цены} == 'clicks' => [siteZoneID, leadPagesNum].disable();
	var priceTypeHandler = function(value) {
		var elmSiteInputs = jQuery('.site_sitezone input', document.cpointForm);
		jQuery(elmSiteInputs).removeAttr('disabled');
		if (value == 'CPC') {
			var elmSet = jQuery("input[name='siteZoneId'],input[name='leadPagesNum']", document.cpointForm);
			elmSet.attr('disabled', status).val('');
		} else if (value == 'CPM') {
			var elmSet = jQuery("input[name='siteZoneId'],input[name='leadPagesNum'],input[name='siteId']", document.cpointForm);
			elmSet.attr('disabled', status).val('');
		} else {
			observer(inpPageCount);
			observer(inpSZ);
		}
	};

	jQuery("input[name='priceType']", document.cpointForm).change(function(e) {
		priceTypeHandler(e.target.value || '')
	});


	observer(inpPageCount);
	observer(inpSZ);
	priceTypeHandler(form.serialize(true)['priceType'] || '');
}


function columnsSelector(options) {
	var j = jQuery;
	this.options = jQuery.extend(options || {}, {
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});

	this.ls = window.localStorage;
	this.hiddenColumns =  this.ls[options['lsConfigName']] ? this.ls[options['lsConfigName']].split(',') : [];
	this.table = jQuery(options['table']);

	this.parseTable();
	this.buildColSelector();

}

Object.extend(columnsSelector.prototype, {
	Hider: function() {
		this.table.hide();
	},

	Shower: function() {
		this.table.show();
	},

	ColumnToggler: function() {
		var cols = this.hiddenColumns;
		// Скрываем / показываем ячейки

		jQuery("tr", this.table).each(function(ind, tr) {
			jQuery('td', tr).each(function(index, tdElm) {
				jQuery(tdElm).css({'display': (cols.indexOf(index+'') > -1 ? 'none' : 'table-cell')});
			});
		});

		// Схлоп/расхлоп колонок.
		jQuery('col', this.table).each(function(index, colElm) {
			if (cols.indexOf(index+'') > -1) {
				jQuery(colElm).css({'visibility': 'collapse', display: 'none'});
			} else {
				jQuery(colElm).css({'visibility': 'visible', display: ''});
			}
		});

	},

	buildColSelector: function() {
		var cols = this.hiddenColumns;
		var elmSelector = this.elmSelector = jQuery('<select>', {multiple: true});
		jQuery("thead tr td", this.table).each(function(ind, cell) {
			var colheader = jQuery('.colheader', cell);
			if (colheader.length) {
				var option = jQuery("<option>", {
					'selected': !(cols.indexOf(ind+'') > -1),
					'value': ind,
					'text': jQuery(cell).text()
				});
				if (!jQuery(cell).hasClass('collapsable')) {
					option.attr('disabled', true);
				}
				option.appendTo(elmSelector);
			}
		});

		var box = jQuery("<div>").css({float: 'right'});
		jQuery('<span>Настройка колонок таблицы: </span>').appendTo(box);
		this.elmSelector.appendTo(box);

		jQuery(this.elmSelector).multiselect({
			checkAllText: 'показать все',
			uncheckAllText: 'скрыть все',
			noneSelectedText: 'Настройка столбцов...',
			selectedText: '# из # колонок выбрано',
			close: this.colSelectorHandler.bind(this)
		});

		box.appendTo(this.options['selectorContainer']);
	},

	colSelectorHandler: function() {
		// var res = jQuery(this.elmSelector).val()); - пропускает задизабленные елементы...
		var res = jQuery(this.elmSelector).multiselect("getUnchecked").map(function(){ return this.value; }).get();
		console.info(res);
		this.hiddenColumns = this.ls[this.options['lsConfigName']] = res;
		this.parseTable();
	},

	parseTable: function() {
		this.Hider();
		this.ColumnToggler();
		this.Shower();
	}
});

