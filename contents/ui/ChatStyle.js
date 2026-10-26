.pragma library

// Only presentation is changed. No messages, credentials or page data leave the view.
// Keep the page function as source: QML functions stringify as native code.
var columnTracker = `function() {
    function syncSeparators(column, conversation) {
        var edge = column.getBoundingClientRect().right;
        var content = conversation.getBoundingClientRect();
        // WhatsApp also paints pane borders in a separate, non-interactive
        // background layer. Its percentage widths do not follow the real panels.
        for (var branch = column; branch && branch.parentElement && branch !== document.body; branch = branch.parentElement) {
            Array.from(branch.parentElement.children).forEach(function(layer) {
                if (layer === branch || layer.contains(column) || layer.contains(conversation)) return;
                var layerStyle = getComputedStyle(layer);
                if (layerStyle.position !== 'absolute' && layerStyle.pointerEvents !== 'none' && layer.getAttribute('aria-hidden') !== 'true') return;
                var pieces = [layer].concat(Array.from(layer.querySelectorAll('*')));
                if (pieces.length > 12 || !pieces.every(function(piece) {
                    return /^(DIV|SPAN)$/.test(piece.tagName) && piece.childNodes.length === piece.children.length;
                })) return;
                pieces.forEach(function(piece) {
                    var rect = piece.getBoundingClientRect();
                    if (rect.height < content.height * 0.7) return;
                    var style = getComputedStyle(piece);
                    var left = parseFloat(style.borderLeftWidth) > 0 && rect.left > edge + 2 && rect.left < content.right - 2;
                    var right = parseFloat(style.borderRightWidth) > 0 && rect.right > edge + 2 && rect.right < content.right - 2;
                    if (left || right) piece.setAttribute('data-wawidget-stale-separator', left && right ? 'both' : left ? 'left' : 'right');
                });
            });
        }
    }
    var side = document.getElementById("side");
    var columnAttribute = "data-wawidget-column";
    var marked = document.querySelector('[' + columnAttribute + '="chats"]');
    var markedConversation = document.querySelector('[' + columnAttribute + '="conversation"]');
    if (marked && markedConversation && side && marked.contains(side)
            && marked.parentElement === markedConversation.parentElement) {
        syncSeparators(marked, markedConversation);
        return;
    }
    document.querySelectorAll('[' + columnAttribute + ']').forEach(function(element) {
        element.removeAttribute(columnAttribute);
    });
    if (!side)
        return;

    // #side may be several wrappers below the real flex column. Resizing only its
    // immediate parent leaves the column's original width and separator behind.
    for (var column = side; column && column.parentElement; column = column.parentElement) {
        var parent = column.parentElement;
        var style = getComputedStyle(parent);
        if (!/^(inline-)?flex$/.test(style.display) || !/^row/.test(style.flexDirection))
            continue;
        if (column.querySelector("#main"))
            break;
        var bounds = parent.getBoundingClientRect();
        var columnBounds = column.getBoundingClientRect();
        if (bounds.width < 300 || columnBounds.height < bounds.height * 0.5)
            continue;
        var candidates = Array.from(parent.children).filter(function(sibling) {
            if (sibling === column)
                return false;
            var rect = sibling.getBoundingClientRect();
            var position = getComputedStyle(sibling).position;
            return position !== "absolute" && position !== "fixed"
                && rect.width >= bounds.width * 0.25 && rect.height >= bounds.height * 0.5;
        });
        if (!candidates.length)
            continue;
        var conversation = candidates.find(function(element) {
            return element.id === "main" || element.querySelector("#main");
        }) || candidates.sort(function(a, b) {
            return b.getBoundingClientRect().width - a.getBoundingClientRect().width;
        })[0];
        column.setAttribute(columnAttribute, "chats");
        conversation.setAttribute(columnAttribute, "conversation");
        syncSeparators(column, conversation);
        return;
    }
}`;

function script(narrow, compact, collapsed) {
    var css = "";
    if (narrow)
        css += '[data-wawidget-column="chats"]{flex:0 0 270px!important;width:270px!important;min-width:0!important;max-width:38%!important}'
             + '[data-wawidget-column="chats"]{box-sizing:border-box!important;border-inline-end:1px solid var(--border-strong,rgba(127,127,127,.25))!important}'
             + '[data-wawidget-column="chats"] #side{min-width:0!important;width:100%!important;max-width:100%!important}'
             + '[data-wawidget-column="conversation"]{flex:1 1 0!important;min-width:0!important;width:auto!important;max-width:none!important}'
             + '[data-wawidget-stale-separator="left"],[data-wawidget-stale-separator="both"]{border-left-color:transparent!important}'
             + '[data-wawidget-stale-separator="right"],[data-wawidget-stale-separator="both"]{border-right-color:transparent!important}';
    // WhatsApp virtualizes rows with inline pixel offsets. Zooming the list keeps
    // those offsets consistent; overriding row heights would leave holes/overlaps.
    if (compact)
        css += '#pane-side{zoom:.85!important}';
    // Do not collapse on the QR/login screen or when no conversation is open.
    if (collapsed)
        css += 'body:has(#main) [data-wawidget-column="chats"]{display:none!important}'
             + 'body:has(#main) [data-wawidget-column="conversation"]{flex:1 1 0!important;min-width:0!important;width:auto!important;max-width:none!important}';
    return '(function(){if(location.origin!=="https://web.whatsapp.com"||!document.documentElement)return;'
        + 'var s=document.getElementById("wawidget-style");'
        + 'if(!s){s=document.createElement("style");s.id="wawidget-style";(document.head||document.documentElement).appendChild(s);}'
        + 's.textContent="";'
        + 'if(window.__wawidgetColumns)window.__wawidgetColumns.disconnect();'
        + 'document.querySelectorAll("[data-wawidget-column]").forEach(function(e){e.removeAttribute("data-wawidget-column");});'
        + 'document.querySelectorAll("[data-wawidget-stale-separator]").forEach(function(e){e.removeAttribute("data-wawidget-stale-separator");});'
        + (narrow || collapsed
            ? 'var update=' + columnTracker + ';update();var pending=false;'
              + 'var observer=new MutationObserver(function(){if(pending)return;pending=true;requestAnimationFrame(function(){pending=false;if(window.__wawidgetColumns===observer)update();});});'
              + 'window.__wawidgetColumns=observer;observer.observe(document.documentElement,{childList:true,subtree:true});'
            : 'window.__wawidgetColumns=null;')
        + 's.textContent=' + JSON.stringify(css) + ';'
        + (narrow || collapsed ? 'update();' : '') + '})()';
}
