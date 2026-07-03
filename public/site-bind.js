(function () {
  var site = window.SITE;
  if (!site) {
    throw new Error('window.SITE is not defined — site.js must load before site-bind.js');
  }
  document.querySelectorAll('[data-site-field]').forEach(function (el) {
    var key = el.getAttribute('data-site-field');
    var val = site[key];
    if (val == null || val === '') {
      throw new Error('SITE.' + key + ' is not set');
    }
    var attr = el.getAttribute('data-site-attr');
    var prefix = el.getAttribute('data-site-prefix') || '';
    if (attr) {
      el.setAttribute(attr, prefix + val);
    } else {
      el.textContent = val;
    }
  });
})();
