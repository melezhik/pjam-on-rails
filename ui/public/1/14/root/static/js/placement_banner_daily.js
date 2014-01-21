// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigPlacementBannerDaily',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
