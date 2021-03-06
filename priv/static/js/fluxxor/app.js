var React = require("react"),
    Fluxxor = require("fluxxor"),
    JQuery = require("jquery");

window.React = React // to make it available from the console for debugging

var constants = {
    REFRESH_NEWS: "REFRESH_NEWS",
    CLEAR_NEWS: "CLEAR_NEWS",
    // https://cloud.google.com/translate/v2/using_rest#language-params
    LANGUAGES: [
    {name: 'English', symbol: 'en'},
    {name: 'Spanish', symbol: 'es'},
    {name: 'French',  symbol: 'fr'},
    {name: 'Italian',  symbol: 'it'},
    {name: 'German',  symbol: 'de'},
    {name: 'Russian', symbol: 'ru'},
    {name: 'Chinese', symbol: 'zh-CN'} 
    ],
    URL: "/api/stories"
};

var NewsStore = Fluxxor.createStore({
    initialize: function() {
	this.news = [];
	this.loading = false;

        this.bindActions(
	    constants.REFRESH_NEWS, this.onRefreshNews,
 	    constants.CLEAR_NEWS, this.onClearNews
        );
    },

    onRefreshNews: function(payload) {
        this.loadNews(payload.count, payload.language);
        this.emit("change");
    },

    onClearNews: function() {
        this.news = [];
        this.emit("change");
    },

    getState: function() {
    	return {loading: this.loading, news: this.news};
    },

    loadNews: function(count, language) {
       var store = this.flux.stores.NewsStore;
       store.loading = true;
       JQuery.ajax({
        url: constants.URL + "?count=" + count + "&language=" + language.symbol,
        dataType: 'json',
	success: function(stories) {
		   store.news = stories;
                   store.loading = false;
		   store.emit("change");
                 }.bind(this),
        error: function(xhr, status, err) {
	       if (console && console.log) {
   	          console.log("[LOAD FAILED]", status, err.toString());
  	       }
               store.loading = false;
               store.emit("change");
	}.bind(this)
       });
    }
});

var actions = {
    clearNews: function() {
    	this.dispatch(constants.CLEAR_NEWS)
    },
    refreshNews: function(count, language) {
        this.dispatch(constants.REFRESH_NEWS, {count: count, language: language});
    }
};

var stores = { NewsStore: new NewsStore() };

var flux = new Fluxxor.Flux(stores, actions);

window.flux = flux; // to make it available from the console for debugging

flux.on("dispatch", function(type, payload) {
  if (console && console.log) {
    console.log("[Dispatch]", type, payload);
  }
});

var FluxMixin = Fluxxor.FluxMixin(React),
    StoreWatchMixin = Fluxxor.StoreWatchMixin;

var Application = React.createClass({displayName: "Application",
  mixins: [FluxMixin, StoreWatchMixin("NewsStore")],

  getInitialState: function() {
    return {count: 0, language: constants.LANGUAGES[0]};
  },

  getStateFromFlux: function() {
    var flux = this.getFlux();
    return flux.store("NewsStore").getState();
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
	    constants.LANGUAGES.map(function(language, i) {
	      return React.createElement("option", {key: i, value: language.symbol}, language.name);
            })
        ), 
        React.createElement("input", {type: "submit", value: "Go", style: {float: "right"}})
    ), 
    React.createElement("div", {style: {margin: "10px 0 20px 0"}}, 
      this.state.loading
         ? (React.createElement("img", {src: "/images/ajax-loader.gif", alt: "loader"}))
         : null, 
      
       React.createElement("ul", null, 
             this.state.news.map(function(story, i) {
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
        var language = constants.LANGUAGES.filter( 
	    	       	    function(lang, index, array) { return lang.symbol == s; }
			)[0];
 	this.setState({count: this.state.count, language: language});
 },

  onSubmitForm: function(e) {
    e.preventDefault();
    if (this.state.count == 0) {
      this.getFlux().actions.clearNews();
    } else {
      this.getFlux().actions.refreshNews(this.state.count, this.state.language);
    }
  }

});

var NewsItem = React.createClass({displayName: "NewsItem",
  mixins: [FluxMixin],

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

React.render(React.createElement(Application, {flux: flux}), document.getElementById("app"));