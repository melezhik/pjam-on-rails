// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigPlacementDaily',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
