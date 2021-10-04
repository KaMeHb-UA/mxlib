module mxlib

import net.http
import net.urllib

[noinit]
pub struct Server {
	homeserver &urllib.URL
	identity_server &urllib.URL
	versions []string
	unstable_features map[string]bool
}

// just a shorthand
fn (s &Server) raw_call<R, A>(http_method http.Method, method string, headers map[string]string, args A) ?R {
	return call_method<R, A>(s.homeserver, http_method, 'r0', method, headers, args)
}
