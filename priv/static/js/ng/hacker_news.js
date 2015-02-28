// Module
var hackerNews = angular.module('HackerNews', [ 'ngResource', 'angular-loading-bar', 'ngAnimate']);

// Controller
hackerNews.controller('HackerNewsController', function($scope, HackerNewsModel, Languages) {

    $scope.count = 0;
    $scope.language = Languages[0];
    $scope.languages = Languages;
    $scope.stories = [];

    $scope.onChange = function() {
	$scope.stories = HackerNewsModel.getStories($scope.count, $scope.language);
    }

});

// Constants
hackerNews.constant('Languages', [
    {name: 'English', symbol: 'en'},
    {name: 'Spanish', symbol: 'es'},
    {name: 'French',  symbol: 'fr'},
    {name: 'German',  symbol: 'de'},
    {name: 'Russian', symbol: 'ru'},
    {name: 'Chinese', symbol: 'zh-CN'} 
]);

// Model
hackerNews.service('HackerNewsModel', function(HackerNewsServer) {
    var getStories = function(count, language) {
	if (count == 0) {
	    return [];
	} else {
	    var storiesResource = HackerNewsServer.storiesResource;
            return storiesResource.query({count: count, language: language.symbol});
	}
    };

    return {getStories: getStories};
});

// REST 
hackerNews.service('HackerNewsServer', function($resource) {
    var storiesResource = $resource('/api/stories');

    return {storiesResource: storiesResource} 
});

