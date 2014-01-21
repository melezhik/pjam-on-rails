jQuery(document).ready(function($) {
	var fName = "";
	var uriUploadCheck = "/costs/check_upload";
	var uriUploadAuto = "/costs/upload";
	var uriUploadApprove = "/costs/upload/approve";

	window.upload = function(file) {
	//	if (!file || !file.type.match(/.*csv/)) return;
		var isAuto = !!($("#isAutoUpload").attr('checked'));

		var fd = new FormData();
		fd.append("file", file); // Append the file


		var xhr = new XMLHttpRequest();
		xhr.open("POST", isAuto ? uriUploadAuto : uriUploadCheck);
		xhr.setRequestHeader('Accept', 'application/json');
		xhr.onload = isAuto ?
			function() { showAutoResult(xhr);} :
			function() { showTable(xhr);};
		xhr.send(fd);
	};

	function resetPage() {
		fName = "";
		$("#restable").hide();
		$("#restable table tbody").empty();
		$("#resApprove").empty().hide();
	}

	$.template("costsRow",
		"<tr>" +
		"<td>${advertiser_title}</td>" +
		"<td>${mediaplan_title}</td>" +
		"<td>${placement_title}</td>" +
		"<td class='numeric'>${date}</td>" +
		"<td class='numeric'>${costs}</td>" +
		"<td class='numeric inactive'>${old_costs}</td>" +
		"</tr>"
	);

	function showTable(response) {
		resetPage();
		var responseData = $.parseJSON(response.responseText);

		if (response.status < 400) {
			var elBody = $("#restable table tbody");
			fName = responseData['filename'];

			$(responseData['data']).each(function(i, rowData) {
				$.tmpl("costsRow", rowData).appendTo(elBody);
			});

			$("#restable").show();
		} else {
			$('#resApprove').html(uploadErrorHandler(responseData)).show();
		}
	}

	function showAutoResult(response) {
		resetPage();
		var responseData = $.parseJSON(response.responseText);

		if (response.status < 400) {
			$('#resApprove').html("<div class='notice'>В базе успешно изменено строк: " + responseData['affected_rows_num'] + "</div>").show();
		} else {
			$('#resApprove').html(uploadErrorHandler(responseData)).show();
		}
	}

	function uploadErrorHandler(responseData) {
		var errMessage = "", i, id;
		switch (responseData.type) {
			case "BampoManager::Exception::Costs::Upload::NotFoundPlacements":
				errMessage = "На сервере не найдены размещения: <br/>";
				$.each(responseData['ids'], function(i, id) {errMessage += id + "<br/>"});
				break;
			case "BampoManager::Exception::Costs::Upload::File::Format":
				errMessage = "Формат файла - не CSV";
				break;
			case "BampoManager::Exception::Costs::Upload::File::Line":
				errMessage = "Ошибка в строке " + responseData['line_num'];
				break;
			case "BampoManager::Exception::Costs::Upload::File":
				errMessage = "Неверный формат CSV файла";
				break;
		}
		return 'Ошибка при обработке данных из загруженного файла: ' + errMessage;
	}

	$("#btnSubmit").click(function() {
		requestApprove();
	});

	function requestApprove() {
		if (!fName) return;
		$.post(uriUploadApprove, {filename: fName}, requestApproveHandler);
	}

	function requestApproveHandler(responseData, state, response) {
		console.info(arguments);
		resetPage();
		if (state == 'success') {
			$('#resApprove').html("<div class='notice'>В базе успешно изменено строк: " + responseData['affected_rows_num'] + "</div>").show();
		} else {
			$('#resApprove').html('Ошибка при обавлении даных из файла в базу.').show();
		}
	}
});
