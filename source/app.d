import std.getopt, std.regex, std.stdio, std.uri;
import ircbod.client, ircbod.message;
import vibe.inet.url, vibe.inet.urltransfer, vibe.stream.operations;


void main(string[] args) {
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

	//vibe.core.log.setLogLevel(vibe.core.log.LogLevel.Trace);
	//IRCMessage msg;
	//msg.text = "http://code.dlang.org";
	auto title_match = regex(r"<title>(.*)</title>", "i");
	dtec.on(IRCMessage.Type.CHAN_MESSAGE, (msg) {
		foreach(ref url; findURLs(msg.text)) {
			try {
				writeln("Loading ", url, "");
				download(url, (scope InputStream input) {

					try {
						string data = input.readAllUTF8(false);
						//check(data);
						auto cap = match(data, title_match);
						if(!cap.empty()) {
							string title = "» [" ~ cap.captures[1] ~ "]";
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

	writeln("Connecting... ", nick, passwd.length > 0 ? ":" : "",passwd, "@", host,":",port, "/", channels);
	dtec.connect();
	writeln("Processing...");
	dtec.run();
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
			if(url.localURI.length == 0) // Retarded but vibe.d cannot fix itself
				url.localURI = "/";
			urls ~= url;

		} catch (Exception e) {
			writeln(cap);
			writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
		}
	return urls;
}
