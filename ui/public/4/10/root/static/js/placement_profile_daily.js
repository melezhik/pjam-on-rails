// запуск обработчика таблицы, отложенный при необходимости до ondomready.
jQuery(function() {
	var colSelector = new columnsSelector({
		lsConfigName: 'gridConfigPlacementProfileDaily',
		selectorContainer: jQuery('.info'),
		table: '.panel-tbody table'
	});
});
