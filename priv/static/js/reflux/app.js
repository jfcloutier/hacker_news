var React = require("react"),
    Reflux = require("reflux"),
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

var Actions = { refreshNews: Reflux.createAction({asyncResult: true}),
               	clearNews : Reflux.createAction() };


var NewsStore = Reflux.createStore({
    listenables: [Actions], // callbacks automatically generated, including for sub-actions (e.g. completed and failed)

    getInitialState: function() {
        this.news = [];
        this.loading = false;
	return this.getState();
    },

    getState: function() {
        return {news: this.news, loading: this.loading};
    },

    onRefreshNews: function(payload) {
        this.loading = true;
        Request
		.get(Constants.url)
		.query({count: payload.count, language: payload.language.symbol})
                .promise()
		.then(function(response) {
		   Actions.refreshNews.completed(response);
		 })
                .catch(function(response) {
		   Actions.refreshNews.failed(response);
                 });
        this.trigger(this.getState());
    },

    onRefreshNewsCompleted: function(response) {
       console.log("Completed response: ", response);
       var update = JSON.parse(response.text);
       this.news = update;
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

  mixins: [Reflux.connect(NewsStore, "newsState")], // the store's state will be automagically added 
                                                    // to the component's state and kept up-to-date

  getInitialState: function() {
    return {count: 0, 
    	    language: Constants.languages[0]};
  },

  render: function() {
    return ( // parenthesis required for JSX to work
  React.createElement("div", null, 
    React.createElement("form", {onSubmit: this.onSubmitForm}, 
         "Get me the to", '\u00A0', 
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
      
       React.createElement("ul", null, 
             this.state.newsState.news.map(function(story, i) {
              return ( // parenthesis required for JSX to work
               React.createElement("li", {key: i}, 
	           React.createElement(NewsItem, {story: story})
	     	    ));
       	       })
      )
    )
  )
    );
  },

  isSelected: function(language) {
    return this.state.language == language;
  },

  handleNewsCountChange: function(e) {
  	this.setState({count: e.target.value, language: this.state.language});		 	  
  },

  handleNewsLanguageChange: function(e) {
        var s = e.target.value;
        var language = Constants.languages.filter( 
	    	       	    function(lang, index, array) { return lang.symbol == s; }
			)[0];
 	this.setState({count: this.state.count, language: language});
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