import
	std.array,
	std.conv,
	std.datetime,
	std.getopt,
	std.net.curl,
	std.regex,
	std.stdio,
	std.string;
import
	ircbod.client,
	ircbod.message;


// Url match regex thanks to http://stackoverflow.com/a/1141962
enum url_match = regex(r"(https?://)(([\S]+\.)*([a-z0-9])+)(/?[a-z0-9\._/~%\-\+&\#\?!=\(\)@]*)?", "ig");

bool muted;
string nick = "Dtec";

int main(string[] args) {
	string host = "fr.quakenet.org";
	ushort port = 6666;

	string passwd = null;
	string[] channels = [ "#DerpsInAction" ];

	getopt(args,
	       "h|host", &host,
	       "p|port", &port,
	       "n|nick|nickname", &nick,
	       "pass|password", &passwd,
	       "c|channel|channels", &channels,
		   "m|muted", &muted);

	writeln("Initialising... ");

	IRCClient dtec = new IRCClient(host, port, nick, passwd, channels);

	dtec.on(IRCMessage.Type.CHAN_MESSAGE, &onChannelMessage);

	writeln("Connecting... ", nick, passwd.length > 0 ? ":" : "", passwd, "@", host, ":", port, "/", channels);
	dtec.connect();
	writeln("Processing...");
	dtec.run();

	return 0;
}

void onChannelMessage(IRCMessage msg) {
	string atMe = "@" ~ nick ~ " ";
	if(msg.text == atMe ~ "stfu") {
		msg.reply("._.");
		muted = true;
	}
	if(muted) return;

	printURLs(msg);
}

void printURLs(ref IRCMessage msg) {

	string[] urls;
	foreach(ref cap; match(msg.text, url_match)) {
		string url = cap.hit;
		try {
			string title;
			HTTP.StatusLine status;
			auto ap = appender!string();

			try {
				writeln("Loading ", url);
				status = getTitle(url, title);
				if(status.code >= 400) {
					ap ~= "! ";
					ap ~= text(status.code);
					//	ap ~= " - ";
					//	ap ~= status.reason;
				}

				if(!title.empty()) {
					if(ap.data.length != 0)
						ap ~= " ";
					ap ~= "» [";
					ap ~= title;
					ap ~= "]";
				}
			} catch(CurlTimeoutException ex) {
				ap.put("! Timed out");
			}


			if(ap.data.length > 0) {
				msg.reply(ap.data);
				writeln(ap.data);
			}
		} catch (Exception e) {
			writeln("Failed to load: ", url);
			writeln(e.file,":", e.line, "::", e.classinfo.name, ": ", e.msg);
		}
	}
}

HTTP.StatusLine getTitle(in string url, ref string title) {
	auto aTitle = appender!string;
	auto content = appender!string;

	HTTP client = HTTP(url);
	client.method = HTTP.Method.get;

	HTTP.StatusLine status;
	client.onReceiveStatusLine = (HTTP.StatusLine sl) { status = sl; };

	//string encoding = "ISO-8859-1";
	/*client.onReceiveHeader = (in char[] key, in char[] value) {
		enum charset_match = regex("charset=([^;,]*)", "i");

		if ("content-type" == key.toLower) {
			auto m = match(value, charset_match);
			if (!m.empty && m.captures.length > 1)
				encoding = m.captures[1].idup;
		}
	};*/
	long ix,ex=ix=-1;
	client.onReceive = (ubyte[] data) {
		content ~= (cast(char[])data).idup;

		if(ix == -1) {
			ix = content.data.indexOf("<title>");
			if(ix > -1)
				ix += "<title>".length;
		}
		if(ix > -1 && ex == -1) {
			ex = content.data.indexOf("</title>");
			if(ex == -1) {
				aTitle ~= content.data[ix .. $];
			} else {
				aTitle ~= content.data[ix .. ex];
				return HTTP.requestAbort;
			}
		}
		return data.length;
	};

	try
		client.perform();
	catch(CurlTimeoutException ex)
		throw ex;
	catch(CurlException ex) {
		if(!ex.msg.startsWith("Failed writing received data to disk/application on handle"))
			throw ex;
	}
	title = aTitle.data;
	return status;
}

