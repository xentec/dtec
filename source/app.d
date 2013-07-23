import std.array, std.conv, std.getopt, std.regex, std.stdio, std.string, std.xml : decode;
import ircbod.client, ircbod.message;
import vibe.inet.url, vibe.http.client, vibe.stream.operations;

int main(string[] args) {
	string host = "fr.quakenet.org";
	ushort port = 6666;

	string nick = "Dtec",
		passwd = null;
	string[] channels = [ "#DerpsInAction" ];

	getopt(args,
	       "h|host", &host,
	       "p|port", &port,
	       "u|user|n|nick|nickname", &nick,
	       "pass|password", &passwd,
	       "c|channel|channels", &channels);

	writeln("Initialising... ");
	IRCClient dtec = new IRCClient(host, port, nick, passwd, channels);

	//debug vibe.core.log.setLogLevel(vibe.core.log.LogLevel.Trace);

	auto title_match = regex(r"<title>(.*)</title>", "is");
	dtec.on(IRCMessage.Type.CHAN_MESSAGE, (msg) {
		if(msg.text == nick ~ ", shut up") {
			msg.reply("._.");
			dtec.quit();
		}

		foreach(ref url; findURLs(msg.text)) {
			try {
				writeln("Loading ", url, "");
				requestHTTP(url,
					(scope req) {
					/* could e.g. add headers here before sending*/
					},
					(scope res) {
						try {
							string title = "";
							if(res.statusCode >= 400) {
								title = "! " ~ text(res.statusCode) ~ " - " ~ res.statusPhrase;
							}
							string data = res.bodyReader.readAllUTF8(false);
							auto cap = match(data, title_match);
							if(!cap.empty()) {
								if(title.length != 0)
									title ~= " ";
								title ~= "» [";
								title ~= decode(cap.captures[1].strip()).replace("&nbsp;", " ");
								title ~= "]";
							}
							if(title.length > 0) {
								msg.reply(title);
								writeln(title); 
							}
						} catch (Exception e) {
							writeln("Failed to parse");
							writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
						}
					});
			} catch (Exception e) {
				writeln("Failed to load");
				writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
			}
		}		
	});

	writeln("Connecting... ", nick, passwd.length > 0 ? ":" : "", passwd, "@", host, ":", port, "/", channels);
	dtec.connect();
	writeln("Processing...");
	dtec.run();
	return 0;
}

URL[] findURLs(in string text) {
	debug writeln("Input text: ", text);

	// Url match regex thanks to http://stackoverflow.com/a/1141962
	auto url_match = regex(r"(https?://)?(([\S]+\.)+(MUSEUM|TRAVEL|AERO|ARPA|ASIA|EDU|GOV|MIL|MOBI|COOP|INFO|NAME|BIZ|CAT|COM|INT|JOBS|NET|ORG|PRO|TEL|A[CDEFGILMNOQRSTUWXZ]|B[ABDEFGHIJLMNORSTVWYZ]|C[ACDFGHIKLMNORUVXYZ]|D[EJKMOZ]|E[CEGHRSTU]|F[IJKMOR]|G[ABDEFGHILMNPQRSTUWY]|H[KMNRTU]|I[DELMNOQRST]|J[EMOP]|K[EGHIMNPRWYZ]|L[ABCIKRSTUVY]|M[ACDEFGHKLMNOPQRSTUVWXYZ]|N[ACEFGILOPRUZ]|OM|P[AEFGHKLMNRSTWY]|QA|R[EOSUW]|S[ABCDEGHIJKLMNORTUVYZ]|T[CDFGHJKLMNOPRTVWZ]|U[AGKMSYZ]|V[ACEGINU]|W[FS]|Y[ETU]|Z[AMW]))(/?[a-z0-9\._/~%\-\+&\#\?!=\(\)@]*)?", "ig");

	URL[] urls;
	foreach(ref cap; match(text, url_match))
		try {
			debug writeln(cap);
			URL url = URL.parse(cap.hit);
			if(url.localURI.length == 0) //2 Retarded but vibe.d cannot fix itself
				url.localURI = "/";
			urls ~= url;
		} catch (Exception e) {
			writeln(cap);
			writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
		}
	return urls;
}


