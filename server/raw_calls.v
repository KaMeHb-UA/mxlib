module server

import net.http
import net.urllib
import json

fn raw_call<R, A>(base &urllib.URL, method http.Method, path string, headers map[string]string, args A) ?R {
	mut fetch_config := &http.FetchConfig {
		url: base.parse(path)?.str()
		method: method
	}
	if method == http.Method.post || method == http.Method.put || method == http.Method.patch {
		mut header := http.new_header(http.HeaderConfig {
			key: http.CommonHeader.content_type
			value: 'application/json'
		})
		header.add_custom_map(headers)?
		fetch_config.header = header
		fetch_config.data = json.encode(args)
	}
	r := http.fetch(fetch_config)?

	// compile-time type fields definition
	mut type_fields := map[string]bool
	$for field in R.fields {
        type_fields[field.name] = true
    }

	dmap := json.decode(map[string]bool, r.text)?
	if !('errcode' in type_fields) && 'errcode' in dmap {
		err := json.decode(ErrResp, r.text)?
		return error('$err.errcode: $err.error')
	}
	return json.decode(R, r.text)
}

fn call_method<R, A>(base &urllib.URL, http_method http.Method, version string, method string, headers map[string]string, args A) ?R {
	return raw_call<R, A>(base, http_method, '/_matrix/client/$version/$method', headers, args)
}

fn call_method_wo_version<R, A>(base &urllib.URL, http_method http.Method, method string, headers map[string]string, args A) ?R {
	return raw_call<R, A>(base, http_method, '/_matrix/client/$method', headers, args)
}
