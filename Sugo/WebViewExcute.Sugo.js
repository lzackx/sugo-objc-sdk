    sugo.init_path();
    sugo.track('浏览', sugo.view_props);
    sugo.trackStayEvent();
    sugo.bindEvent();
    window.addEventListener('hashchange', function() {
        sugo.view_props = {};
    	sugo.init_path();
    	sugo.track('浏览', sugo.view_props);
    	sugo.trackStayEvent();
    })
