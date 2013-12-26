import
	std.array,
	std.conv,
	std.getopt,
	std.regex,
	std.stdio,
	std.string;
import
	ircbod.client,
	ircbod.message;
import
	vibe.inet.url,
	vibe.http.client,
	vibe.stream.operations;

// Url match regex thanks to http://stackoverflow.com/a/1141962
enum url_match = regex(r"(https?://)(([\S]+\.)*([a-z0-9])+)(/?[a-z0-9\._/~%\-\+&\#\?!=\(\)@]*)?", "ig");

int main(string[] args) {
	string host = "fr.quakenet.org";
	ushort port = 6666;

	string nick = "Dtec", passwd = null;
	string[] channels = [ "#DerpsInAction" ];

	bool muted;

	getopt(args,
	       "h|host", &host,
	       "p|port", &port,
	       "n|nick|nickname", &nick,
	       "pass|password", &passwd,
	       "c|channel|channels", &channels,
		   "m|muted", &muted);

	writeln("Initialising... ");
	IRCClient dtec = new IRCClient(host, port, nick, passwd, channels);

	//debug vibe.core.log.setLogLevel(vibe.core.log.LogLevel.Trace);
	
	dtec.on(IRCMessage.Type.CHAN_MESSAGE, (msg) {
		string atMe = "@" ~ nick ~ " ";
		if(msg.text == atMe ~ "stfu") {
			msg.reply("._.");
			muted = true;
		}
		if(muted) return;

		foreach(ref url; findURLs(msg.text)) {
			try {
				writeln("Loading ", url, "");
				requestHTTP(url,
				(scope HTTPClientRequest req) {
				/* could e.g. add headers here before sending*/
				},
				(scope HTTPClientResponse res) {
					try {
						auto ap = appender!string();
						if(res.statusCode >= 400) {
							ap ~= "! ";
							ap ~= text(res.statusCode);
							ap ~= " - ";
							ap ~= res.statusPhrase;
						}

						string title = getTitle(res.bodyReader);
						if(!title.empty()) {
							if(ap.data.length != 0)
								ap ~= " ";
							ap ~= "» [";
							ap ~= title;
							ap ~= "]";
						}
						if(ap.data.length > 0) {
							msg.reply(ap.data);
							writeln(ap); 
						}
					} catch (Exception e) {
						writeln("Failed to parse");
						writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
					}
				});
			} catch (Exception e) {
				writeln("Failed to load: ", url);
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

string getTitle(InputStream stream) {
	enum string[2] titleTag = ["<title>", "</title>"];
	string data;
	try
		data = cast(string)stream.readUntil(titleTag[1].representation());
	catch(Exception e) {
		writeln(e);
		return null;
	}
	ptrdiff_t pos = data.indexOf(titleTag[0]);
	if(pos >= 0) {
		pos += titleTag[0].length;
		return data[pos..$].strip().replace("&nbsp;", " ");
	} else {
		debug writeln("First <title> tag not found");
		return data;
	}
}

URL[] findURLs(in string text) {
	debug writeln("Input text: ", text);
	
	URL[] urls;
	foreach(ref cap; match(text, url_match))
		try {
			debug writeln("URL found: ", cap);
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


