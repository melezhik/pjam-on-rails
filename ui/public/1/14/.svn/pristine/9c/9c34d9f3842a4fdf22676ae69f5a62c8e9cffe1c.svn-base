function submitFormByAJAX(params) {
    // form - форма
    // uri - адрес для отправки формы
    // onSuccess - на успешное выполнение
    // onFailed
    // extra - дополнительные параметры в сабмит
    // method

    if (!params['form'] || !$(params['form'])) throw new Error("incorrect form param");

    var data = params['form'].serialize(true);

    var AJAXOptions = {
        method: params['method'] || "GET",
        requestHeaders: params['requestHeaders'] || {},
        parameters: data,
        onComplete: function(res) {
            if (res['status'] > 399) {
                (params['onFailed'])(res);
            } else {
                (params['onSuccess'])(res);
            }
        },
        onFailed: function(res) {
            (params['onFailed'])(res);
        }
    };
    new Ajax.Request(params['uri'], AJAXOptions);
    return false;
}

function submit_dialog(form, divid, errback) {
	var status = true;
	if (form.checkValidity && !form.checkValidity()) {
		form.select('[required]').each(function(elm) {
			if (elm.type && !elm.disabled && !elm.value) {
				status = false;
				var dl = Element.up(elm, 'dl');
				dl.setStyle({backgroundColor: '#fca'});
				( function() {dl.setStyle({backgroundColor: ''})} ).delay(1.5);
			}
		})
	}

	if (!status) return false;

    submitFormByAJAX({
        method: form.method,
        form: form,
        uri: form.action,
        onSuccess: function(res) {
            window.location.reload();
        },
        onFailed: function(res) {
            $(divid).update(res.responseText);
	        if (errback) errback();
        }
    });
    return false;
}

function load_dialog(url,divid,params, callback) {
    new Ajax.Request(url, {
	    asynchronous: false,
        parameters: params,
        onSuccess: function(res) {
            $(divid).update(res.responseText);
	        if (callback) callback();
        },
        onFailed: function(res) {
            $(divid).update('Загрузить форму не удалось');
        }
    });
}

function reload_dialog(url,divid,params) {
    new Ajax.Request(url, {
        parameters: params,
        onComplete: function(res) {
            $(divid).update(res.responseText);
        },
        onFailed: function(res) {
            $(divid).update('Загрузить форму не удалось');
        }
    });
}