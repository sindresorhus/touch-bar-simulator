$.get('https://api.github.com/repos/sindresorhus/touch-bar-simulator/releases/latest', data => {
	$('#download-button').attr('href', data.assets[0].browser_download_url);
});
