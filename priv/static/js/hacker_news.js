var hackerNews = angular.module('HackerNews', [ 'ngResource', 'angular-loading-bar', 'ngAnimate']);

hackerNews.controller('HackerNewsController', function($scope, HackerNewsModel, Languages) {

    $scope.count = 0;
    $scope.language = Languages[0];
    $scope.languages = Languages;
    $scope.stories = [];

    $scope.onChange = function() {
	$scope.stories = HackerNewsModel.getStories($scope.count, $scope.language);
    }

});

hackerNews.constant('Languages', [
    {name: 'English', symbol: 'en'},
    {name: 'Spanish', symbol: 'es'},
    {name: 'French',  symbol: 'fr'},
    {name: 'German',  symbol: 'de'},
    {name: 'Russian', symbol: 'ru'},
    {name: 'Chinese', symbol: 'zh-CN'} 
]);

hackerNews.service('HackerNewsModel', function($resource) {
    var getStories = function(count, language) {
	if (count == 0) {
	    return [];
	} else {
	    var HackerNewsAPI = $resource('/api/stories');
            return HackerNewsAPI.query({count: count, language: language.symbol});
	}
    };

    return {getStories: getStories};
});

