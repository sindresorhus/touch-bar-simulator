$.get('https://api.github.com/repos/sindresorhus/touch-bar-simulator/releases/latest', function (data) {
  $('#touchBar').attr('href', data.assets[0].browser_download_url);
});
