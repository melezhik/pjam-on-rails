
(function() {

	var selectClients = Class.create({
		initialize: function(options) {
			this.Elm = options['elm'];
			this.Elm.observe('change', function() {this.onChangeHandler(this.Elm.getValue())}.bind(this));
			this.options = options;
		},

		updateValues: function(data) {
			var id, arr = $A();
			this.Elm.update(new Element('option', {value: ''}).update('-- не назначен --'));

			for (id in data) { arr.push({id: id, value: data[id]}); }
			arr.sortBy(function(item){return item['value']}).each(function(item) {
				var option = new Element('option', {value: item['id']}).update(item['value']);
				this.Elm.insert(option);
			}.bind(this));

			// Установка начальных значений.
			if (this.options['value']) {
				this.Elm.setValue(this.options['value']);
				this.onChangeHandler(this.options['value']);
				this.options['value'] = null;
			}
			this.notify('loaded');
		},

		toElement: function() {
			return this.Elm;
		},

		onChangeHandler: function(value) {
			this.notify('onChange', value);
		}
	});
	Object.Event.extend(selectClients);

	var selectAdvert = Class.create({
		initialize: function(options) {
			this.Elm = options['elm'];
			this.ElmNew = $('create_placement_costsCampaignName');
			this.Elm.observe('change', function() {this.onChangeHandler(this.Elm.getValue())}.bind(this));
			this.options = options;
		},

		toElement: function() {
			return this.Elm;
		},

		clearValues: function() {
			this.Elm.update();
			this.Elm.setValue("");
		},

		updateValues: function(data) {
			var id, arr = $A();
			this.Elm.update(new Element('option', {value: ''}).update('-- не назначена --'));

			for (id in data) { arr.push({id: id, value: data[id]}); }
			arr.sortBy(function(item){return item['value']}).each(function(item) {
				var option = new Element('option', {value: item['id']}).update(item['value']);
				this.Elm.insert(option);
			}.bind(this));

			// Установка начальных значений.
			if (this.options['value']) {
				this.Elm.setValue(this.options['value']);
				this.onChangeHandler(this.options['value']);
				this.options['value'] = null;
			}
			this.notify('loaded');
		},

		onChangeHandler: function(value) {
			this.notify('onChange', value);
		}
	});
	Object.Event.extend(selectAdvert);

	var wCosts = Class.create({
		initialize: function(options) {
			this.options = Object.extend(
				{'accountId': '', campaignId: '', campaignName: '', placementName: '', error: ''},
				options);
			try {
				this.Elm = $('fieldsetCosts');
				this.dlList = this.Elm.select('dl');

				this.selectClients = new selectClients({
					elm: $('create_placement_costsAccountId'),
					value: this.options['accountId']
				});
				this.selectClients.observe('onChange', this.stateClientSelected.bind(this));

				this.selectAdverts = new selectAdvert({
					elm: $('create_placement_costsCampaignId'),
					value: this.options['campaignId']
				});

				this.inputNewAdvert = this.Elm.select('#create_placement_costsCampaignName')[0];
				this.inputNewAdvert.value = this.options['campaignName'];

				this.inputPlacementName = this.Elm.select('#create_placement_costsPlacementName')[0];
				this.inputPlacementName.value = this.options['placementName'];

				this.toggler = new wToggler({});
				this.toggler.observe('update', this.updateAdvertsView.bind(this));
				$(this.dlList[2]).insert({after: this.toggler});
				this.toggler.hide();

				this.stateCostsDisabled();

				this.checkServerStatus();

			} catch(e) {
				console.error(e);
			}
		},

		stateStart: function(sourceID) {
			this.stateCostsDisabled();
			this.sourceID = sourceID;

			if (this.sourceID) this.requestClients(this.sourceID);
		},

		stateCostsDisabled: function() {
			this.Elm.hide();
			this.dlList.each(function(dl, index) {
				if (index > 0) dl.hide();
				else dl.show();
			});
			this.toggler.hide();
			this.Elm.select('select').invoke('disable');
			this.Elm.select('input').invoke('disable');
		},

		stateClient: function(data) {
			this.stateCostsDisabled();
			this.Elm.show();
			this.selectClients.Elm.enable();
			if (data) this.selectClients.updateValues(data);
		},

		stateClientSelected: function(clientID) {
			this.clientID = clientID;
			if (!clientID) {
				this.stateClient(false);
			} else {
				this.dlList[3].show();
				this.inputPlacementName.enable();
				this.requestCapabilities();
			}
		},

		stateCaps: function(data) {
			this.clientCaps = data;
			if (this.clientCaps['select_campaigns']) {
				this.requestAdverts();
			}
//			if (this.clientCaps['create_campaigns']) {}
		},

		requestClients: function() {
			var url = '/costs/sources/' + this.sourceID + '/accounts';
//			url = '/data/accounts'; // FAKE
			new Ajax.Request(url, {
				method: 'get',
				requestHeaders: {'Content-Type': 'application/json'},
				onComplete: this.responseClients.bind(this),
				evalJSON: true
			});
		},

		responseClients: function(resp) {
			if (resp.status != 200) {
//				console.warn('status = ' + resp.status);
				this.stateCostsDisabled();
				return;
			}

			$('fieldsetCosts').show();
			var data = resp.responseJSON;
			this.stateClient(data['data']);
		},

		requestCapabilities: function() {
			var url = '/costs/sources/' + this.sourceID + '/accounts/' + this.clientID + '/caps';
			new Ajax.Request(url, {
				method: 'get',
				requestHeaders: {'Content-Type': 'application/json'},
				onComplete: this.responseCapabilities.bind(this),
				evalJSON: true
			});
		},

		responseCapabilities: function(resp) {
			if (resp.status != 200) {
//				console.warn('requestCapabilities: status = ' + resp.status);
//				this.stateCostsDisabled();
				return;
			}
//			console.info(resp.responseJSON);
			var data = resp.responseJSON;
			this.stateCaps(data['data']);
			this.updateAdvertsByCaps(data['data']);
		},

		requestAdverts: function() {
			this.selectAdverts.clearValues();
			var url = '/costs/sources/' + this.sourceID + '/accounts/' + this.clientID + '/campaigns';
//			url = '/data/adverts'; // FAKE
			new Ajax.Request(url, {
				method: 'get',
				requestHeaders: {'Content-Type': 'application/json'},
				onComplete: this.responseAdverts.bind(this),
				evalJSON: true
			});
		},

		responseAdverts: function(resp) {
			var data = resp.responseJSON;
			if (resp.status == 500 && data['type'] == "BampoManager::Exception::Costs::CampaignsNotSupported") {
				this.stateAdverts(null, true);
				return;
			}
			if (resp.status != 200) {
				this.stateAdverts(null);
				return;
			}
			this.selectAdverts.updateValues(data['data'] || {});
		},

		updateAdvertsByCaps: function(caps) {
			this.disableAdvertsView();
			if (caps['create_campaigns']) {
				this.dlList[2].show();
				this.inputNewAdvert.enable();
			} else if (caps['select_campaigns']) {
				this.dlList[1].show();
				this.selectAdverts.Elm.enable();
			}
			if (caps['select_campaigns'] && caps['create_campaigns']) {
				this.toggler.show();
				this.toggler.set(!this.inputNewAdvert.value, true);
			}
		},

		updateAdvertsView: function(state) {
			if (state) {
				this.dlList[1].show();
				this.dlList[2].hide();
				this.selectAdverts.Elm.enable();
				this.inputNewAdvert.disable();
			} else {
				this.dlList[1].hide();
				this.dlList[2].show();
				this.selectAdverts.Elm.disable();
				this.inputNewAdvert.enable().focus();
			}
		},



		disableAdvertsView: function() {
			// Скрываем выбор / ввод кампании
			this.dlList[1].hide();
			this.dlList[2].hide();
			this.selectAdverts.Elm.disable();
			this.inputNewAdvert.disable();
			this.toggler.hide();
		},

		checkServerStatus: function() {
			this.showDefaultError("");
			if (this.options['error']) {
				switch(true) {
					case (this.options['error'] == "BampoManager::Costs::Exception::DuplicateCampaign") :
						this.inputNewAdvert.up('dd').insert("<span class='error'>кампания с таким названием существует</span>");
						break;
					case (this.options['error'] == "BampoManager::Costs::Exception::DuplicatePlacement") :
						this.inputPlacementName.up('dd').insert("<span class='error'>размещение с таким названием существует</span>");
						break;
					case (this.options['error'] == "BampoManager::Costs::Exception::BackendPermissionDenied") :
						this.showDefaultError("ошибка прав доступа");
						break;
					default:
						this.showDefaultError("неустановленная ошибка при настройке внешнего источника затрат");
						break;
				}
			}
		},

		showDefaultError: function(msg) {
			var divErr = $('fieldsetCosts').select('div.error.msg')[0];
			if (!divErr) {
				divErr = new Element('div', {className: 'error msg'});
				$('fieldsetCosts').select('legend')[0].insert({after: divErr});
			}
			divErr.update(msg || "");
		}

	});

	var wToggler = Class.create({
		initialize: function() {
			this.items = ['Выбор из списка', 'Новая кампания'];
	//			{id: 'new', title: 'Новая кампания'},
	//			{id: 'select', title: 'Выбор из списка'}
	//		];
			this.state = false;
		},

		toElement: function() {
//			console.warn('toggler.toElement');
			if (!this.Elm) {
				this.Elm = new Element('span', {className: 'plink'})
					.observe('click', this.toggle.bind(this));
				this.hide = function() {this.Elm.hide();return this;};
				this.show = function() {this.Elm.show();return this;};
			}
			this.elmUpdate();
			return new Element('div').setStyle({'textAlign': 'right'}).insert(this.Elm);
		},

		elmUpdate: function() {
			this.Elm.update(this.getText(this.state));
		},

		getText: function(status) {
			return this.items[(status ? 1 : 0)];
		},

		set: function(status, isForce) {
			status = !!status;
			if (this.state == status && !isForce) return;
			this.state = status;
			this.Elm.update(this.getText(this.state));
			this.notify('update', this.state);
			return this;
		},

		toggle: function() {
			this.set(!this.state);
		}
	});
	Object.Event.extend(wToggler);

	var testSubmit = function() {
		console.info($('create_placement').serialize());
		return false;
	};

	function restoreState(wCosts) {
		if ($('create_placement_costsSourceId').value) {
			wCosts.stateStart($('create_placement_costsSourceId').value);
		}
	}

	function startValidator() {
		var form = $('create_placement');
		if (!form) return;
		new Form.Observer(form, 0.5, validator.bind(this, false));
	}

	function validator(fromSubmit) {
		var status = true;
		var form = $('create_placement');
		if (!form) return;
		var data = form.serialize(true);

		var fieldSet = $('fieldsetCosts');
		if (fieldSet.visible()) {
			var divErr = fieldSet.select('div.error.client')[0];
			if (!divErr) {
				divErr = new Element('div', {className: 'error client'});
				fieldSet.select('legend')[0].insert({after: divErr});
			}

			if (data['costsAccountId'] && /*(data['costsCampaignId'] || data['costsCampaignName']) &&*/ data['costsPlacementName']) {
				fieldSet.setStyle({backgroundColor: ''});
				divErr.update('');
			} else {
				status = false;
				if (fromSubmit) {
					fieldSet.setStyle({backgroundColor: '#fca'});
					( function() {fieldSet.setStyle({backgroundColor: ''})} ).delay(1.5);
				}
			}
		}
		return status;
	}

	function validateOnsubmit (mode) {
		var evName = (mode == 'create' ? 'dialog:newplacement' : 'dialog:editplacement');
		submit_dialog($(mode + '_placement'),'d_ad', function() {document.fire(evName);});
	}

	window.configureExtSelect = function(selector, status) {
		var cb = new Element('input', {type: 'checkbox'});
		cb.observe('click', function() { toggleArchivedOptions(selector, !!cb.checked);	});
		var div = new Element('div', {className: 'subfilterLine'});
		div.appendChild(document.createTextNode('показывать архивные: '));
		div.insert(cb);
		Element.insert(selector, {'after': div} );
		toggleArchivedOptions(selector, !!status)
	};

	function toggleArchivedOptions(selector, status) {
		$(selector).select('option').each(function(option) {
			if (Element.hasAttribute(option, 'data-archived')) {
				Element.addClassName(option, 'att');
				Element[status?'show':'hide'](option);
			}
		});
	}

	document.observe("dialog:newplacement", function() {
		(function() {
			var costs_values = window.costs_values || {};

			var costs = new wCosts(costs_values);
			$('create_placement_costsSourceId').observe('change', function(e) {
				costs.stateStart(e.target.value);
			});

			// Обработка списков выбора для Продукта и Формата, Канала банеров и Настройки(таргетинга) размещения сокрытие архивных значений.
			configureExtSelect('create_placement_priceProductId', false);
			configureExtSelect('create_placement_bannerFormatId', false);
			configureExtSelect('create_placement_placementTargetingId', false);
			configureExtSelect('create_placement_channelGroupId', false);

			// Восстанавливаем переданное состояние.
			restoreState(costs);

			startValidator();

			$('create_placement_submit_button').observe('click', validateOnsubmit.bind(this, 'create'));
		}.bind(this)).defer();
	});

	document.observe("dialog:editplacement", function() {
		(function() {
			// Обработка списков выбора для Продукта , Формата , Канала банеров и Настройки(таргетинга) размещения сокрытие архивных значений.
			configureExtSelect('edit_placement_priceProductId', false);
			configureExtSelect('edit_placement_bannerFormatId', false);
			configureExtSelect('edit_placement_placementTargetingId', false);
			configureExtSelect('edit_placement_channelGroupId', false);

			$('edit_placement_submit_button').observe('click', validateOnsubmit.bind(this, 'edit'));
		}.bind(this)).defer();
	});

}());

document.observe("extra_filters:render", function() {
	configureExtSelect('f_banner_format', false);
	configureExtSelect('f_product', false);
	configureExtSelect('f_channel_group', false);
	configureExtSelect('f_placement_targeting', false);

	// TODO: Добавить проверку на отображение полей про КТ в поисковой форме
});
