module dtec.utils;

import std.conv;
import std.array: appender;
import std.encoding;
import std.string;
import std.xml;

string decodeString(string encoding, const(ubyte)[] data) {
	if(encoding == "UTF-8")
		return cast(string)(data);

	EncodingScheme scheme = EncodingScheme.create(encoding);
	auto decoded = appender!(string);
	while(data.length)
	{
		dchar dc = scheme.safeDecode(data);
		if (dc == INVALID_SEQUENCE)
			decoded ~= "?";
		else
			decoded ~= dc;
	}
	return decoded.data;
}

string humanBytes(ulong bytes) {
	enum prefix = ["","Ki","Mi","Gi","Ti","Pi"];
	float simplify(float bytes, ref byte level) {
		return (++level == prefix.length || bytes < 750f) ? bytes : simplify(bytes/1024f, level);
	}
	byte l = -1;
	float hb = simplify(to!float(bytes), l);
	return format("%.1f %sB", hb, prefix[l]);
}

string decodeHTML(string str) {
	auto ap = appender!(string);
	long ee, es;
	while(true) {
		es = str.indexOf("&");
		if(es == -1) break;
		es++;

		ee = str[es..$].indexOf(";");
		if(ee == -1) break;
		ee += es;

		string ent = str[es..ee];
		ap ~= str[0..es-1];
		str = str[ee+1..$];

		if(ent.length < 2) continue;

		switch(ent[0]) {
			case '#':
			case 'x':
				ap ~= std.xml.decode('&' ~ ent ~ ';');
				break;
			default:
				ap ~= htmlDecode.get(ent,'�');
				break;
		}
	}
	ap ~= str[0..$];
	return ap.data;
}

private enum wchar[string] htmlDecode = [
//	&ent;	&#dec;	&#xUTF;		// c	description
	"quot":			'\u0022',	// "	quotation mark (APL quote)
	"amp":			'\u0026',	// &	ampersand
	"apos":			'\u0027',	// '	apostrophe (apostrophe-quote)
	"lt":			'\u003C',	// <	less-than sign
	"gt":			'\u003E',	// >	greater-than sign
	"nbsp":			'\u00A0',	//  	no-break space (non-breaking space)
	"iexcl":		'\u00A1',	// ¡	inverted exclamation mark
	"cent":			'\u00A2',	// ¢	cent sign
	"pound":		'\u00A3',	// £	pound sign
	"curren":		'\u00A4',	// ¤	currency sign
	"yen":			'\u00A5',	// ¥	yen sign (yuan sign)
	"brvbar":		'\u00A6',	// ¦	broken bar (broken vertical bar)
	"sect":			'\u00A7',	// §	section sign
	"uml":			'\u00A8',	// ¨	diaeresis (spacing diaeresis)
	"copy":			'\u00A9',	// ©	copyright sign
	"ordf":			'\u00AA',	// ª	feminine ordinal indicator
	"laquo":		'\u00AB',	// «	left-pointing double angle quotation mark (left pointing guillemet)
	"not":			'\u00AC',	// ¬	not sign
	"shy":			'\u00AD',	//  	soft hyphen (discretionary hyphen)
	"reg":			'\u00AE',	// ®	registered sign (registered trade mark sign)
	"macr":			'\u00AF',	// ¯	macron (spacing macron; overline; APL overbar)
	"deg":			'\u00B0',	// °	degree sign
	"plusmn":		'\u00B1',	// ±	plus-minus sign (plus-or-minus sign)
	"sup2":			'\u00B2',	// ²	superscript two (superscript digit two; squared)
	"sup3":			'\u00B3',	// ³	superscript three (superscript digit three; cubed)
	"acute":		'\u00B4',	// ´	acute accent (spacing acute)
	"micro":		'\u00B5',	// µ	micro sign
	"para":			'\u00B6',	// ¶	pilcrow sign (paragraph sign)
	"middot":		'\u00B7',	// ·	middle dot (Georgian comma; Greek middle dot)
	"cedil":		'\u00B8',	// ¸	cedilla (spacing cedilla)
	"sup1":			'\u00B9',	// ¹	superscript one (superscript digit one)
	"ordm":			'\u00BA',	// º	masculine ordinal indicator
	"raquo":		'\u00BB',	// »	right-pointing double angle quotation mark (right pointing guillemet)
	"frac14":		'\u00BC',	// ¼	vulgar fraction one quarter (fraction one quarter)
	"frac12":		'\u00BD',	// ½	vulgar fraction one half (fraction one half)
	"frac34":		'\u00BE',	// ¾	vulgar fraction three quarters (fraction three quarters)
	"iquest":		'\u00BF',	// ¿	inverted question mark (turned question mark)
	"Agrave":		'\u00C0',	// À	Latin capital letter A with grave (Latin capital letter A grave)
	"Aacute":		'\u00C1',	// Á	Latin capital letter A with acute
	"Acirc":		'\u00C2',	// Â	Latin capital letter A with circumflex
	"Atilde":		'\u00C3',	// Ã	Latin capital letter A with tilde
	"Auml":			'\u00C4',	// Ä	Latin capital letter A with diaeresis
	"Aring":		'\u00C5',	// Å	Latin capital letter A with ring above (Latin capital letter A ring)
	"AElig":		'\u00C6',	// Æ	Latin capital letter AE (Latin capital ligature AE)
	"Ccedil":		'\u00C7',	// Ç	Latin capital letter C with cedilla
	"Egrave":		'\u00C8',	// È	Latin capital letter E with grave
	"Eacute":		'\u00C9',	// É	Latin capital letter E with acute
	"Ecirc":		'\u00CA',	// Ê	Latin capital letter E with circumflex
	"Euml":			'\u00CB',	// Ë	Latin capital letter E with diaeresis
	"Igrave":		'\u00CC',	// Ì	Latin capital letter I with grave
	"Iacute":		'\u00CD',	// Í	Latin capital letter I with acute
	"Icirc":		'\u00CE',	// Î	Latin capital letter I with circumflex
	"Iuml":			'\u00CF',	// Ï	Latin capital letter I with diaeresis
	"ETH":			'\u00D0',	// Ð	Latin capital letter ETH
	"Ntilde":		'\u00D1',	// Ñ	Latin capital letter N with tilde
	"Ograve":		'\u00D2',	// Ò	Latin capital letter O with grave
	"Oacute":		'\u00D3',	// Ó	Latin capital letter O with acute
	"Ocirc":		'\u00D4',	// Ô	Latin capital letter O with circumflex
	"Otilde":		'\u00D5',	// Õ	Latin capital letter O with tilde
	"Ouml":			'\u00D6',	// Ö	Latin capital letter O with diaeresis
	"times":		'\u00D7',	// ×	multiplication sign
	"Oslash":		'\u00D8',	// Ø	Latin capital letter O with stroke (Latin capital letter O slash)
	"Ugrave":		'\u00D9',	// Ù	Latin capital letter U with grave
	"Uacute":		'\u00DA',	// Ú	Latin capital letter U with acute
	"Ucirc":		'\u00DB',	// Û	Latin capital letter U with circumflex
	"Uuml":			'\u00DC',	// Ü	Latin capital letter U with diaeresis
	"Yacute":		'\u00DD',	// Ý	Latin capital letter Y with acute
	"THORN":		'\u00DE',	// Þ	Latin capital letter THORN
	"szlig":		'\u00DF',	// ß	Latin small letter sharp s (ess-zed)
	"agrave":		'\u00E0',	// à	Latin small letter a with grave
	"aacute":		'\u00E1',	// á	Latin small letter a with acute
	"acirc":		'\u00E2',	// â	Latin small letter a with circumflex
	"atilde":		'\u00E3',	// ã	Latin small letter a with tilde
	"auml":			'\u00E4',	// ä	Latin small letter a with diaeresis
	"aring":		'\u00E5',	// å	Latin small letter a with ring above
	"aelig":		'\u00E6',	// æ	Latin small letter ae (Latin small ligature ae)
	"ccedil":		'\u00E7',	// ç	Latin small letter c with cedilla
	"egrave":		'\u00E8',	// è	Latin small letter e with grave
	"eacute":		'\u00E9',	// é	Latin small letter e with acute
	"ecirc":		'\u00EA',	// ê	Latin small letter e with circumflex
	"euml":			'\u00EB',	// ë	Latin small letter e with diaeresis
	"igrave":		'\u00EC',	// ì	Latin small letter i with grave
	"iacute":		'\u00ED',	// í	Latin small letter i with acute
	"icirc":		'\u00EE',	// î	Latin small letter i with circumflex
	"iuml":			'\u00EF',	// ï	Latin small letter i with diaeresis
	"eth":			'\u00F0',	// ð	Latin small letter eth
	"ntilde":		'\u00F1',	// ñ	Latin small letter n with tilde
	"ograve":		'\u00F2',	// ò	Latin small letter o with grave
	"oacute":		'\u00F3',	// ó	Latin small letter o with acute
	"ocirc":		'\u00F4',	// ô	Latin small letter o with circumflex
	"otilde":		'\u00F5',	// õ	Latin small letter o with tilde
	"ouml":			'\u00F6',	// ö	Latin small letter o with diaeresis
	"divide":		'\u00F7',	// ÷	division sign
	"oslash":		'\u00F8',	// ø	Latin small letter o with stroke (Latin small letter o slash)
	"ugrave":		'\u00F9',	// ù	Latin small letter u with grave
	"uacute":		'\u00FA',	// ú	Latin small letter u with acute
	"ucirc":		'\u00FB',	// û	Latin small letter u with circumflex
	"uuml":			'\u00FC',	// ü	Latin small letter u with diaeresis
	"yacute":		'\u00FD',	// ý	Latin small letter y with acute
	"thorn":		'\u00FE',	// þ	Latin small letter thorn
	"yuml":			'\u00FF',	// ÿ	Latin small letter y with diaeresis
	"OElig":		'\u0152',	// Œ	Latin capital ligature oe
	"oelig":		'\u0153',	// œ	Latin small ligature oe
	"Scaron":		'\u0160',	// Š	Latin capital letter s with caron
	"scaron":		'\u0161',	// š	Latin small letter s with caron
	"Yuml":			'\u0178',	// Ÿ	Latin capital letter y with diaeresis
	"fnof":			'\u0192',	// ƒ	Latin small letter f with hook (function; florin)
	"circ":			'\u02C6',	// ˆ	modifier letter circumflex accent
	"tilde":		'\u02DC',	// ˜	small tilde
	"Alpha":		'\u0391',	// Α	Greek capital letter Alpha
	"Beta":			'\u0392',	// Β	Greek capital letter Beta
	"Gamma":		'\u0393',	// Γ	Greek capital letter Gamma
	"Delta":		'\u0394',	// Δ	Greek capital letter Delta
	"Epsilon":		'\u0395',	// Ε	Greek capital letter Epsilon
	"Zeta":			'\u0396',	// Ζ	Greek capital letter Zeta
	"Eta":			'\u0397',	// Η	Greek capital letter Eta
	"Theta":		'\u0398',	// Θ	Greek capital letter Theta
	"Iota":			'\u0399',	// Ι	Greek capital letter Iota
	"Kappa":		'\u039A',	// Κ	Greek capital letter Kappa
	"Lambda":		'\u039B',	// Λ	Greek capital letter Lambda
	"Mu":			'\u039C',	// Μ	Greek capital letter Mu
	"Nu":			'\u039D',	// Ν	Greek capital letter Nu
	"Xi":			'\u039E',	// Ξ	Greek capital letter Xi
	"Omicron":		'\u039F',	// Ο	Greek capital letter Omicron
	"Pi":			'\u03A0',	// Π	Greek capital letter Pi
	"Rho":			'\u03A1',	// Ρ	Greek capital letter Rho
	"Sigma":		'\u03A3',	// Σ	Greek capital letter Sigma
	"Tau":			'\u03A4',	// Τ	Greek capital letter Tau
	"Upsilon":		'\u03A5',	// Υ	Greek capital letter Upsilon
	"Phi":			'\u03A6',	// Φ	Greek capital letter Phi
	"Chi":			'\u03A7',	// Χ	Greek capital letter Chi
	"Psi":			'\u03A8',	// Ψ	Greek capital letter Psi
	"Omega":		'\u03A9',	// Ω	Greek capital letter Omega
	"alpha":		'\u03B1',	// α	Greek small letter alpha
	"beta":			'\u03B2',	// β	Greek small letter beta
	"gamma":		'\u03B3',	// γ	Greek small letter gamma
	"delta":		'\u03B4',	// δ	Greek small letter delta
	"epsilon":		'\u03B5',	// ε	Greek small letter epsilon
	"zeta":			'\u03B6',	// ζ	Greek small letter zeta
	"eta":			'\u03B7',	// η	Greek small letter eta
	"theta":		'\u03B8',	// θ	Greek small letter theta
	"iota":			'\u03B9',	// ι	Greek small letter iota
	"kappa":		'\u03BA',	// κ	Greek small letter kappa
	"lambda":		'\u03BB',	// λ	Greek small letter lambda
	"mu":			'\u03BC',	// μ	Greek small letter mu
	"nu":			'\u03BD',	// ν	Greek small letter nu
	"xi":			'\u03BE',	// ξ	Greek small letter xi
	"omicron":		'\u03BF',	// ο	Greek small letter omicron
	"pi":			'\u03C0',	// π	Greek small letter pi
	"rho":			'\u03C1',	// ρ	Greek small letter rho
	"sigmaf":		'\u03C2',	// ς	Greek small letter final sigma
	"sigma":		'\u03C3',	// σ	Greek small letter sigma
	"tau":			'\u03C4',	// τ	Greek small letter tau
	"upsilon":		'\u03C5',	// υ	Greek small letter upsilon
	"phi":			'\u03C6',	// φ	Greek small letter phi
	"chi":			'\u03C7',	// χ	Greek small letter chi
	"psi":			'\u03C8',	// ψ	Greek small letter psi
	"omega":		'\u03C9',	// ω	Greek small letter omega
	"thetasym":		'\u03D1',	// ϑ	Greek theta symbol
	"upsih":		'\u03D2',	// ϒ	Greek Upsilon with hook symbol
	"piv":			'\u03D6',	// ϖ	Greek pi symbol
	"ensp":			'\u2002',	//  	en space
	"emsp":			'\u2003',	//  	em space
	"thinsp":		'\u2009',	//  	thin space
	"zwnj":			'\u200C',	//  	zero-width non-joiner
	"zwj":			'\u200D',	// ‍ 	zero-width joiner
	"lrm":			'\u200E',	// ‎ 	left-to-right mark
	"rlm":			'\u200F',	// ‏ 	right-to-left mark
	"ndash":		'\u2013',	// –	en dash
	"mdash":		'\u2014',	// —	em dash
	"lsquo":		'\u2018',	// ‘	left single quotation mark
	"rsquo":		'\u2019',	// ’	right single quotation mark
	"sbquo":		'\u201A',	// ‚	single low-9 quotation mark
	"ldquo":		'\u201C',	// “	left double quotation mark
	"rdquo":		'\u201D',	// ”	right double quotation mark
	"bdquo":		'\u201E',	// „	double low-9 quotation mark
	"dagger":		'\u2020',	// †	dagger, obelisk
	"Dagger":		'\u2021',	// ‡	double dagger, double obelisk
	"bull":			'\u2022',	// •	bullet (black small circle)
	"hellip":		'\u2026',	// …	horizontal ellipsis (three dot leader)
	"permil":		'\u2030',	// ‰	per mille sign
	"prime":		'\u2032',	// ′	prime (minutes; feet)
	"Prime":		'\u2033',	// ″	double prime (seconds; inches)
	"lsaquo":		'\u2039',	// ‹	single left-pointing angle quotation mark
	"rsaquo":		'\u203A',	// ›	single right-pointing angle quotation mark
	"oline":		'\u203E',	// ‾	overline (spacing overscore)
	"frasl":		'\u2044',	// ⁄		fraction slash (solidus)
	"euro":			'\u20AC',	// €	euro sign
	"image":		'\u2111',	// ℑ	black-letter capital I (imaginary part)
	"weierp":		'\u2118',	// ℘	script capital P (power set; Weierstrass p)
	"real":			'\u211C',	// ℜ	black-letter capital R (real part symbol)
	"trade":		'\u2122',	// ™	trademark sign
	"alefsym":		'\u2135',	// ℵ	alef symbol (first transfinite cardinal)
	"larr":			'\u2190',	// ←	leftwards arrow
	"uarr":			'\u2191',	// ↑	upwards arrow
	"rarr":			'\u2192',	// →	rightwards arrow
	"darr":			'\u2193',	// ↓	downwards arrow
	"harr":			'\u2194',	// ↔	left right arrow
	"crarr":		'\u21B5',	// ↵	downwards arrow with corner leftwards (carriage return)
	"lArr":			'\u21D0',	// ⇐	leftwards double arrow
	"uArr":			'\u21D1',	// ⇑	upwards double arrow
	"rArr":			'\u21D2',	// ⇒	rightwards double arrow
	"dArr":			'\u21D3',	// ⇓	downwards double arrow
	"hArr":			'\u21D4',	// ⇔	left right double arrow
	"forall":		'\u2200',	// ∀	for all
	"part":			'\u2202',	// ∂	partial differential
	"exist":		'\u2203',	// ∃	there exists
	"empty":		'\u2205',	// ∅	empty set (null set; diameter)
	"nabla":		'\u2207',	// ∇	nabla (backward difference)
	"isin":			'\u2208',	// ∈	element of
	"notin":		'\u2209',	// ∉	not an element of
	"ni":			'\u220B',	// ∋	contains as member
	"prod":			'\u220F',	// ∏	n-ary product (product sign)
	"sum":			'\u2211',	// ∑	n-ary summation
	"minus":		'\u2212',	// −	minus sign
	"lowast":		'\u2217',	// ∗	asterisk operator
	"radic":		'\u221A',	// √	square root (radical sign)
	"prop":			'\u221D',	// ∝	proportional to
	"infin":		'\u221E',	// ∞	infinity
	"ang":			'\u2220',	// ∠	angle
	"and":			'\u2227',	// ∧	logical and (wedge)
	"or":			'\u2228',	// ∨	logical or (vee)
	"cap":			'\u2229',	// ∩	intersection (cap)
	"cup":			'\u222A',	// ∪	union (cup)
	"int":			'\u222B',	// ∫	integral
	"there4":		'\u2234',	// ∴	therefore
	"sim":			'\u223C',	// ∼	tilde operator (varies with; similar to)
	"cong":			'\u2245',	// ≅	congruent to
	"asymp":		'\u2248',	// ≈	almost equal to (asymptotic to)
	"ne":			'\u2260',	// ≠	not equal to
	"equiv":		'\u2261',	// ≡	identical to; sometimes used for 'equivalent to'
	"le":			'\u2264',	// ≤	less-than or equal to
	"ge":			'\u2265',	// ≥	greater-than or equal to
	"sub":			'\u2282',	// ⊂	subset of
	"sup":			'\u2283',	// ⊃	superset of
	"nsub":			'\u2284',	// ⊄	not a subset of
	"sube":			'\u2286',	// ⊆	subset of or equal to
	"supe":			'\u2287',	// ⊇	superset of or equal to
	"oplus":		'\u2295',	// ⊕	circled plus (direct sum)
	"otimes":		'\u2297',	// ⊗	circled times (vector product)
	"perp":			'\u22A5',	// ⊥	up tack (orthogonal to; perpendicular)
	"sdot":			'\u22C5',	// ⋅	dot operator
	"lceil":		'\u2308',	// ⌈	left ceiling (APL upstile)
	"rceil":		'\u2309',	// ⌉	right ceiling
	"lfloor":		'\u230A',	// ⌊	left floor (APL downstile)
	"rfloor":		'\u230B',	// ⌋	right floor
	"loz":			'\u25CA',	// ◊	lozenge
	"spades":		'\u2660',	// ♠	black spade suit
	"clubs":		'\u2663',	// ♣	black club suit (shamrock)
	"hearts":		'\u2665',	// ♥	black heart suit (valentine)
	"diams":		'\u2666',	// ♦	black diamond suit
	"lang":			'\u27E8',	// 〈	mathe
];
