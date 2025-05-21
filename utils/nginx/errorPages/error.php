<?php
	include(dirname(__FILE__)."/lib/errorCodes.php");

	$error_query = filter_input(INPUT_GET, 'error', FILTER_SANITIZE_NUMBER_INT);
	$js_error = get_status_code_info($error_query, $http_status_codes);
	$redirect_url = $_SERVER['REDIRECT_URL'] ?? null;
?>
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title></title>
	<link rel="icon" href="//cdn.softgeek.ro/errorPages/assets/img/favicon.ico"
				sizes="any">
	<link rel="icon" href="//cdn.softgeek.ro/errorPages/assets/img/icon.svg"
				type="image/svg+xml">
	<link rel="apple-touch-icon"
				href="//cdn.softgeek.ro/errorPages/assets/img/icon.png">
	<meta name="theme-color" content="#fafafa">
	<link rel="stylesheet"
				href="//cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css"
				integrity="sha512-DTOQO9RWCH3ppGqcWaEA1BIZOC6xxalwEsw9c2QQeAIftl+Vegovlnee1c9QX4TctnWMn13TZye+giMm8e2LwA=="
				crossorigin="anonymous" referrerpolicy="no-referrer"/>
	<link href="//cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css"
				rel="stylesheet"
				integrity="sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN"
				crossorigin="anonymous">
	<link rel="stylesheet" href="//cdn.softgeek.ro/errorPages/css/style.css"
				crossOrigin="anonymous">
	<script>
		<?php
		echo "window.documentError = ".json_encode($js_error).";\r\n";
		echo "window.sgs_redirect_url = '{$redirect_url}';\r\n";
		?>
	</script>
</head>
<body>
<div id="particles-js"></div>
<div class="container-fluid base">
	<div class="d-flex align-items-center justify-content-center">
		<div class="polygonS d-sm-none d-md-block"></div>
		<div class="polygonC d-sm-none d-md-block"></div>
		<div class="polygonV d-sm-none d-md-block"></div>
		<div class="polygonX d-sm-none d-md-block"></div>
		<div class="card-main align-self-lg-center wv-100"
				 style="transform-style: preserve-3d;transform: perspective(1000px);">
			<div class="content documentError" style="transform: translateZ(200px);">
				<h2 class="text-center errorNumber"></h2>
				<p class="fs-4 text-center phrase">
<!--					<i class="fa-regular fa-triangle-exclamation"></i>-->
					<span class="errorPhrase"></span>
				</p>
				<p class="fs-6 error-description-wrap">
<!--					<i class="fa fa-circle"></i>-->
					<span class="error-description"></span>
				</p>
				<div>
					<?php
						if (!is_null($redirect_url)) :
					?>
					<p class="sgs_back_home">
						<i class="fa fa-square-full"></i>
						Please use the button below to go to the home page
					</p>
					<div class="link">
						<a class="btn btn-outline-light back_home_link" href="<?php $redirect_url ?>">
							Back to Home <i class="fa fa-home"></i>
						</a>
					</div>
					<?php endif; ?>
				</div>
			</div>
			<a href="" target="_blank" id="rfc9110-url"><small id="rfc9110-title"></small></a>
		</div>
	</div>
	<div class="fixed-bottom text-center mt-2 me-5 starwars-quote">
		<figure class="text-end">
			<blockquote class="blockquote">
				<p class="sw-quote fs-6"></p>
			</blockquote>
			<figcaption class="blockquote-footer">
				<span>
					<cite title="" class="sw-character"></cite>
					<span class="sw-movie"></span>
			</figcaption>
		</figure>
	</div>
</div>
<script src="//cdn.jsdelivr.net/npm/jquery@3.7.1/dist/jquery.min.js"
				integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo="
				crossorigin="anonymous"></script>
<script
	src="//cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"
	integrity="sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL"
	crossorigin="anonymous"></script>
<script src="//cdn.jsdelivr.net/npm/vanilla-tilt@1.8.1/dist/vanilla-tilt.min.js"
				integrity="sha256-3m+o0/QNuuJyanL30a5GuwWIJnrwU1W+8dEo9zf0ooI="
				crossorigin="anonymous"></script>
<script
	src="//cdn.jsdelivr.net/npm/particles.js@2.0.0/particles.min.js"></script>
<script src="//cdn.softgeek.ro/errorPages/js/app.js" type="module"
				crossOrigin="anonymous"></script>
</body>
</html>