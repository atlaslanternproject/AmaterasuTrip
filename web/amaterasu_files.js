// Amaterasu Trip: scarica un file di testo (es. CSV) e apre una pagina da
// stampare o salvare come PDF. Usato dall'esportazione delle spese.
(function () {
  window.amaterasuDownloadText = function (name, mime, text) {
    const blob = new Blob([text], {type: mime});
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = name;
    document.body.appendChild(link);
    link.click();
    link.remove();
    setTimeout(function () { URL.revokeObjectURL(url); }, 1000);
  };

  window.amaterasuPrintHtml = function (html) {
    const page = window.open('', '_blank');
    if (!page) return false;
    page.document.open();
    page.document.write(html);
    page.document.close();
    page.focus();
    setTimeout(function () { page.print(); }, 300);
    return true;
  };
})();
