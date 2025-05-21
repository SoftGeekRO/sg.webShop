
let timestamp = Math.floor(Date.now() / 1000),
	cdn_domain_url = '//cdn.softgeek.ro/errorPages';

function StarWarsQuote(swQuote, swMovie, swCharacter) {
	this.swQuote = swQuote;
	this.swMovie = swMovie;
	this.swCharacter = swCharacter;


	this.fetchQuotes = async function() {
		const response = await fetch(`${cdn_domain_url}/assets/json/starwarsquotes.json?t=${timestamp}`);
		return await response.json();
	};

	this.render = function() {

		this.fetchQuotes().then(r => {
			let swObject = r.quotes,
				randomNumber= Math.floor(Math.random() * (swObject.length + 1)),
				quote = swObject[randomNumber];

			$(this.swQuote).html(quote.quote);
				$(this.swCharacter).html(quote.character);
				$(this.swMovie).html(` - ${quote.movie}`);
		});

	};

	this.render();

}

function SGSQuery(errorNumber, phrase, description, spec_title, spec_href) {
	this.errorNumber = errorNumber;
	this.phrase = phrase;
	this.description = description;
	this.spec_title = spec_title;
	this.spec_href = spec_href;

	if (window.documentError === null) { return; }

	let _error_ = window.documentError;

	$(this.errorNumber).html(_error_.code);
	$(this.phrase).html(_error_.phrase);
	$(this.description).html(_error_.description);
	$(this.spec_title).html(_error_.spec_title);
	$(this.spec_href).attr({'href': _error_.spec_href});
}

$(function () {

	let search = new SGSQuery(
		".errorNumber", ".errorPhrase", ".error-description",
		'#rfc9110-title', '#rfc9110-url');
	let SW = new StarWarsQuote(".sw-quote", ".sw-movie", ".sw-character");


	if (window.sgs_redirect_url) {
		$(".back_home_link").attr("href", window.sgs_redirect_url);
	} else {
		$(".sgs_redirect_url").hide();
	}

	particlesJS.load("particles-js", `${cdn_domain_url}/assets/json/particles.json`, () => {});

	VanillaTilt.init(document.querySelectorAll(".card-main"), {
		max: 8,
		speed: 400,
		glare: true,
		"max-glare": 0.2,
	});
});