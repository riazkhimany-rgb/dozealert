(function () {
  const brandMarkup =
    '<span class="brand-name"><span class="brand-doze">Doze</span><span class="brand-alert">Alert</span></span>';
  const skipTags = new Set(['SCRIPT', 'STYLE', 'CODE', 'TITLE', 'META', 'SVG']);

  function brandifyText(text) {
    return text.replaceAll('DozeAlert', brandMarkup);
  }

  function brandifyNode(node) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (!node.textContent || !node.textContent.includes('DozeAlert')) {
        return;
      }
      const wrapper = document.createElement('span');
      wrapper.innerHTML = brandifyText(node.textContent);
      node.replaceWith(...wrapper.childNodes);
      return;
    }

    if (node.nodeType !== Node.ELEMENT_NODE) {
      return;
    }

    if (skipTags.has(node.tagName) || node.classList.contains('brand-name')) {
      return;
    }

    [...node.childNodes].forEach(brandifyNode);
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('h1').forEach(function (heading) {
      if (heading.textContent.trim() === 'DozeAlert') {
        heading.innerHTML = brandMarkup;
      }
    });
    brandifyNode(document.body);
  });
})();
