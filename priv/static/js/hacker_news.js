var hackerNews = angular.module('HackerNews', [ 'ngResource']);

hackerNews.service('HackerNewsModel', function($resource) {
    var getStories = function(count, language) {
	if (count == 0) {
	    return [];
	} else {
	    var HackerNewsAPI = $resource('/api/titles');
            return HackerNewsAPI.query({count: count, language: language});
	}
    };

    return {getStories: getStories};
});

hackerNews.controller('HackerNewsController', function($scope, HackerNewsModel) {

    $scope.count = 0;
    $scope.language = "en";
    $scope.languages = ['en', 'fr', 'es', 'de'];
    $scope.items = [];

    $scope.onChange = function() {
	$scope.items = HackerNewsModel.getStories($scope.count, $scope.language);
    }

});



