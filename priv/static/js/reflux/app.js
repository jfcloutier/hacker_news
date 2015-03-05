var React = require("react"),
    Reflux = require("reflux"),
    Immutable = require("immutable"),
    ImmutableRenderMixin = require('react-immutable-render-mixin'),
    Request = require("superagent");

require('superagent-bluebird-promise');

window.React = React // to make it available from the console for debugging

var Constants = {
    // https://cloud.google.com/translate/v2/using_rest#language-params
    languages: [
    {name: 'English', symbol: 'en'},
    {name: 'Spanish', symbol: 'es'},
    {name: 'French',  symbol: 'fr'},
    {name: 'Italian',  symbol: 'it'},
    {name: 'German',  symbol: 'de'},
    {name: 'Russian', symbol: 'ru'},
    {name: 'Chinese', symbol: 'zh-CN'} 
    ],
    url: "/api/stories"
};

var Actions = { refreshNews: Reflux.createAction({asyncResult: true}), // creates async sub-actions completed and failed
               	clearNews : Reflux.createAction() };


var NewsStore = Reflux.createStore({
    listenables: [Actions], // callbacks automatically generated, 
    		 	    // including for async sub-actions completed and failed

    init: function() { 
        // Will automatically call trigger completed or failed sub-actions
        // which will execute the default callbacks on success (promise().then(...).catch(...)
        Actions.refreshNews.listenAndPromise(this.loadNews);
    },

    getInitialState: function() {
        this.news = Immutable.List();
        this.loading = false;
	return this.getState();
    },

    getState: function() {
        return {news: this.news, loading: this.loading};
    },

    loadNews: function(payload) {
       this.loading = true;
       this.trigger(this.getState());
       return Request
		.get(Constants.url)
		.query({count: payload.count, language: payload.language.symbol})
                .promise(); 
    },

/*
// Now implied by listenAndPromise in this.init
    onRefreshNews: function(payload) {
        this.loading = true;
        this.loadNews(payload)
		.then(function(response) {
		   Actions.refreshNews.completed(response);
		 })
                .catch(function(response) {
		   Actions.refreshNews.failed(response);
                 });
        this.trigger(this.getState());
    },
*/

    onRefreshNewsCompleted: function(response) {
       this.news = Immutable.List(JSON.parse(response.text));
       this.loading = false;
       this.trigger(this.getState());
    },

    onRefreshNewsFailed: function(response) {
       console.log("Failed response: ", response);
       this.loading = false;
       this.trigger(this.getState());
    },

    onClearNews: function() {
        this.news = [];
        this.trigger(this.getState());
    }

});


var Application = React.createClass({displayName: "Application",

  mixins: [ImmutableRenderMixin,
  	   Reflux.connect(NewsStore, "newsState")], // the store's state will be automagically added 
                                                    // to the component's state and kept up-to-date

  getInitialState: function() {
    return {count: 0, 
    	    language: Constants.languages[0]};
  },

  render: function() {
    var itemsList =  
             this.state.newsState.news.toArray().map(function(story, i) {
              return (
               React.createElement("li", {key: i}, 
	           React.createElement(NewsItem, {story: story})
	     	    ));
       	       });
    console.log("itemslist", itemsList);
    return ( // parenthesis required by JSX
  React.createElement("div", null, 
    React.createElement("form", {onSubmit: this.onSubmitForm}, 
         "Get me the top", '\u00A0', 
         React.createElement("input", {type: "number", 
			  step: "1", 
			  min: "0", 
			  max: "100", 
                          value: this.state.count, 
                          onChange: this.handleNewsCountChange}), 
	'\u00A0', "news stories and list them in", '\u00A0', 
        React.createElement("select", {onChange: this.handleNewsLanguageChange, value: this.state.language.symbol}, 
	    Constants.languages.map(function(language, i) {
	      return React.createElement("option", {key: i, value: language.symbol}, language.name);
            })
        ), 
        React.createElement("input", {type: "submit", value: "Go", style: {float: "right"}})
    ), 
    React.createElement("div", {style: {margin: "10px 0 20px 0"}}, 
      this.state.newsState.loading
         ? (React.createElement("img", {src: "/images/ajax-loader.gif", alt: "loader"}))
         : null, 
      
      React.createElement("ul", null, itemsList)
    )
  )
    );
  },

  handleNewsCountChange: function(e) {
  	this.setState({count: e.target.value});		 	  
  },

  handleNewsLanguageChange: function(e) {
        var s = e.target.value;
        var language = Constants.languages.filter( 
	    	       	    function(lang, index, array) { return lang.symbol == s; }
			)[0];
 	this.setState({language: language});
 },

  onSubmitForm: function(e) {
    e.preventDefault();
    if (this.state.count == 0) {
      Actions.clearNews();
    } else {
      Actions.refreshNews({count: this.state.count, language: this.state.language});
    }
  }

});

var NewsItem = React.createClass({displayName: "NewsItem",

 propTypes: {
    story: React.PropTypes.object.isRequired
 },

  render: function() {
           story = this.props.story;
  	   return ( // parenthesis required for JSX to work
              React.createElement("span", null, 
      	        React.createElement("a", {href: story.url, target: "blank"}, story.title), 
	        React.createElement("span", {style: {color:"LightGray"}}, '\u00A0', "(", story.score, ")")
             ));
      }

});

React.render(React.createElement(Application, null), document.getElementById("app"));