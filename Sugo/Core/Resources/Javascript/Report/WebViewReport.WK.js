sugo.isElementInViewport = function(rect) {
    return (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= sugo.clientHeight &&
        rect.right <= sugo.clientWidth
    );
};

sugo.handleNodeChild = function(childrens, jsonArry, parent_path) {
    var index_map = {};
    for (var i = 0; i < childrens.length; i++) {
        var children = childrens[i];
        var path = sugoioKit.cssPath(children);
        var htmlNode = {};
        htmlNode.innerText = children.innerText;
        htmlNode.path = path;

        var rect = children.getBoundingClientRect();
        if (sugo.isElementInViewport(rect) == true) {
            var temp_rect = {
                top: rect.top,
                left: rect.left,
                width: rect.width,
                height: rect.height
            };
            htmlNode.rect = temp_rect;
            jsonArry.push(htmlNode);
        }

        if (children.children) {
            sugo.handleNodeChild(children.children, jsonArry, path);
        }
    }
};

sugo.reportNodes = function() {
    var jsonArray = [];
    var body = document.getElementsByTagName('body')[0];
    var childrens = body.children;
    var parent_path = '';
    sugo.clientWidth = (window.innerWidth || document.documentElement.clientWidth);
    sugo.clientHeight = (window.innerHeight || document.documentElement.clientHeight);
    sugo.viewportContent = (document.querySelector('meta[name=viewport]').content || '');
    sugo.handleNodeChild(childrens, jsonArray, parent_path);
    if (window.webkit.messageHandlers.SugoWKWebViewReporter) {
        var message = {
            'title': window.document.title,
            'path': sugo.relative_path,
            'clientWidth': sugo.clientWidth,
            'clientHeight': sugo.clientHeight,
            'viewportContent': sugo.viewportContent,
            'nodes': JSON.stringify(jsonArray)
        };
        window.webkit.messageHandlers.SugoWKWebViewReporter.postMessage(message);
    }
};