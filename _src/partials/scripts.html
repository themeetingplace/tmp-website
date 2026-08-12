(function () {
  var revealSelectors = [
    '.page > section',
    '.page > .v2-section',
    '.page > .v2-highlight-wrap',
    '.page > .v2-scope-wrap',
    '.banner-card',
    '.service-card',
    '.testimonial-photo',
    '.v2-case-pair'
  ];
  var targets = document.querySelectorAll(revealSelectors.join(','));
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
    targets.forEach(function (el) {
      el.classList.add('reveal');
      io.observe(el);
    });
  } else {
    targets.forEach(function (el) { el.classList.add('in-view'); });
  }
})();
(function () {
  document.querySelectorAll('.landlord-form').forEach(function (llForm) {
    var llSuccess = llForm.parentElement.querySelector('.landlord-form-success');
    if (!llSuccess) return;
    llForm.addEventListener('submit', function (e) {
      e.preventDefault();
      llForm.classList.add('is-hidden');
      llSuccess.classList.add('is-shown');
    });
  });
})();
(function () {
  var btn = document.getElementById('back-to-top');
  if (!btn) return;
  function toggle() {
    if (window.scrollY > 400) { btn.classList.add('is-visible'); }
    else { btn.classList.remove('is-visible'); }
  }
  window.addEventListener('scroll', toggle, { passive: true });
  toggle();
  btn.addEventListener('click', function () {
    window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
  });
})();
(function () {
  // 延遲載入用 data-bg 標記背景圖的元素（例如首頁輪播），
  // 等容器接近可視範圍才真正設定 background-image，避免一開始就下載所有輪播圖。
  var lazyEls = document.querySelectorAll('.lazy-bg[data-bg]');
  if (!lazyEls.length) return;
  function load(el) {
    el.style.backgroundImage = 'url(' + el.getAttribute('data-bg') + ')';
    el.removeAttribute('data-bg');
  }
  if ('IntersectionObserver' in window) {
    var lazyContainers = new Set();
    lazyEls.forEach(function (el) {
      var container = el.closest('.v2-carousel') || el.parentElement;
      lazyContainers.add(container);
    });
    var lazyIo = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.querySelectorAll('.lazy-bg[data-bg]').forEach(load);
          lazyIo.unobserve(entry.target);
        }
      });
    }, { rootMargin: '400px 0px' });
    lazyContainers.forEach(function (c) { lazyIo.observe(c); });
  } else {
    lazyEls.forEach(load);
  }
})();
(function () {
  // 數字滾動效果：進入畫面時像老虎機一樣快速轉動每一位數字，最後統一同時停在正確數字（信任數字區塊）
  var digits = document.querySelectorAll('.v2-stats-digit[data-target]');
  if (!digits.length) return;

  function animateDigit(el) {
    var target = parseInt(el.getAttribute('data-target'), 10);
    if (isNaN(target)) return;
    var duration = 2400;
    var startTime = null;
    function step(ts) {
      if (!startTime) startTime = ts;
      var elapsed = ts - startTime;
      var progress = Math.min(elapsed / duration, 1);
      if (progress < 1) {
        var speed = 40 + progress * progress * 220;
        el.textContent = Math.floor(elapsed / speed) % 10;
        requestAnimationFrame(step);
      } else {
        el.textContent = target;
      }
    }
    requestAnimationFrame(step);
  }

  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          animateDigit(entry.target);
          io.unobserve(entry.target);
        }
      });
    }, { threshold: 0.4 });
    digits.forEach(function (el) { io.observe(el); });
  } else {
    digits.forEach(function (el) { el.textContent = el.getAttribute('data-target'); });
  }
})();
