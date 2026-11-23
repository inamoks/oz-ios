/* oz真神了 —— 页面净化层（去广告 / 去埋点 / 去弹窗 / 外链去毒） */
(function () {
  if (window.__ozClean) return;
  window.__ozClean = 1;

  var CSS = [
    '[aria-label="广告"]', '[aria-label="ad"]',
    '[class*="ad-box"]', '[class*="ad-label"]', '[class*="play-page-ad"]',
    '[class*="ad-banner"]', '[class*="banner-ad"]', '[class*="ad-container"]',
    '[class*="ad-wrapper"]', '[class*="advert"]', '[class*="Advert"]',
    '[class*="adsbygoogle"]', '[class*="CommentAd"]', '[class*="comment-ad"]',
    '[class*="ad-cell"]', '[class*="adCell"]', '[class*="pop-ad"]', '[class*="float-ad"]',
    '[id^="ad_"]', '[id^="AS_AD"]', '[data-ad-slot]', '[data-ad-client]', 'ins.adsbygoogle'
  ].join(',') + '{display:none!important;visibility:hidden!important;height:0!important;width:0!important;margin:0!important;padding:0!important}';

  function style() {
    var host = document.head || document.documentElement;
    if (!host) { setTimeout(style, 30); return; }
    var st = document.createElement('style');
    st.type = 'text/css';
    st.appendChild(document.createTextNode(CSS));
    host.appendChild(st);
  }

  /* 站内/白名单链接放行（同窗打开），站外弹窗一律吞掉 */
  window.open = function (url) {
    try {
      if (!url) return null;
      var u = new URL(String(url), location.href);
      if (u.protocol !== 'http:' && u.protocol !== 'https:') return null;
      if (hostAllowed(u.href)) { location.href = u.href; return null; }
      return null;
    } catch (e) { return null; }
  };

  var AD_RE = /eventTracking|batchReport|all\/ad\/|\.cyou|googletagmanager|google-analytics|doubleclick|adsystem|googlesyndication/i;
  try {
    var _fetch = window.fetch;
    if (_fetch) {
      window.fetch = function (u) {
        try {
          var s = String(u && u.url ? u.url : u);
          if (AD_RE.test(s)) {
            return Promise.resolve(new Response('{"code":200,"msg":"success","data":[]}',
              { status: 200, headers: { 'Content-Type': 'application/json' } }));
          }
        } catch (e) { }
        return _fetch.apply(this, arguments);
      };
    }
  } catch (e) { }
  try {
    var _open = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (m, u) {
      try { if (AD_RE.test(String(u))) this.__ozBlock = 1; } catch (e) { }
      return _open.apply(this, arguments);
    };
    var _send = XMLHttpRequest.prototype.send;
    XMLHttpRequest.prototype.send = function () {
      if (this.__ozBlock) { try { this.abort(); } catch (e) { } return; }
      return _send.apply(this, arguments);
    };
  } catch (e) { }

  var ALLOW = ['acfan.com', 'acfan.shop', 'acfan.pro', 'acfansm07.com',
    'ccsnak4i.work', 'sy29wrn1.work', '47u3j9k8.work', 'ohj0zte6.work',
    'bdjyu9ur.work', 'edfj4k9d.work', 'byg3e85j.work', 'jgdfrpwk.work',
    'czskhb.com', 'wosvoj.com', 'kgjci.com', 'dfgwsx.com', 'dcjrsb.com', 'eldtbz.com',
    'lugj0kg1.work', '9ucu0vev.work', '3xruzfy3.work', 'xruzfy3.work'];

  function hostAllowed(href) {
    try {
      var h = new URL(href, location.href).hostname.toLowerCase();
      for (var i = 0; i < ALLOW.length; i++) {
        var d = ALLOW[i];
        if (h === d || h.slice(-(d.length + 1)) === '.' + d) return true;
      }
      return false;
    } catch (e) { return true; }
  }

  function defang() {
    var as = document.querySelectorAll('a[href^="http"]');
    for (var i = 0; i < as.length; i++) {
      var a = as[i];
      if (a.getAttribute('data-oz-defanged')) continue;
      var href = a.getAttribute('href') || '';
      if (hostAllowed(href)) continue;
      a.setAttribute('data-oz-defanged', '1');
      a.removeAttribute('href');
      a.removeAttribute('target');
      a.style.color = '#9aa0a6';
      a.style.textDecoration = 'line-through';
      a.style.pointerEvents = 'none';
      a.title = '站外链接已屏蔽';
    }
  }

  var LABEL = /^(广告|赞助|推广|AD|Ads)$/;
  function sweep() {
    var nodes = document.querySelectorAll('[aria-label="广告"],[aria-label="ad"],[class*="ad"],[class*="Ad"]');
    for (var i = 0; i < nodes.length; i++) {
      var e = nodes[i];
      if (!e || !e.parentNode) continue;
      var t = (e.innerText || '').replace(/\s+/g, '');
      var cls = String(e.className || '');
      if (t && t.length < 20 && LABEL.test(t)) { e.remove(); continue; }
      if (/ad-box|ad-label|play-page-ad|adsbygoogle|CommentAd|ad-cell|adCell|advert/i.test(cls)) e.remove();
    }
    var iframes = document.querySelectorAll('iframe');
    for (var j = 0; j < iframes.length; j++) {
      var f = iframes[j], src = f.getAttribute('src') || '';
      if (!src || AD_RE.test(src) || /ad/.test(src)) f.style.display = 'none';
    }
  }

  function run() {
    try { sweep(); } catch (e) { }
    try { defang(); } catch (e) { }
  }

  window.__ozDefang = defang;
  window.__ozRun = run;

  var booted = false;
  function boot() {
    if (booted) return;
    booted = true;
    try { style(); } catch (e) { }
    try { run(); } catch (e) { }
    try {
      var root = document.documentElement || document.body;
      if (root) new MutationObserver(run).observe(root, { childList: true, subtree: true });
    } catch (e) { }
    var tick = 0;
    var timer = setInterval(function () {
      tick++;
      try { run(); } catch (e) { }
      if (tick >= 14) clearInterval(timer);
    }, 1200);
    setTimeout(run, 600);
    setTimeout(run, 2200);
    setTimeout(run, 5000);
  }

  if (document.readyState === 'loading') {
    try { document.addEventListener('DOMContentLoaded', boot, false); } catch (e) { }
    setTimeout(boot, 50);
  } else {
    boot();
  }
  try { window.addEventListener('load', boot, false); } catch (e) { }
})();
