module server

import net.http
import net.urllib
import session

[noinit]
pub struct Server {
	homeserver &urllib.URL
	identity_server &urllib.URL
	versions map[string]map[string][]string
	unstable_features map[string]bool
	mut:
	login_flows []string
}

fn (s &Server) get_suitable_version(versions []string) ?string {
	for version in versions {
		version_parts := version.split('.')
		if version_parts.len == 1 {
			if version_parts[0] in s.versions {
				return version_parts[0]
			}
		} else if version_parts.len == 2 {
			if version_parts[0] in s.versions && version_parts[1] in s.versions[version_parts[0]] {
				return version_parts[0]
			}
		} else if version_parts.len == 3 {
			if version_parts[0] in s.versions && version_parts[1] in s.versions[version_parts[0]] && version_parts[2] in s.versions[version_parts[0]][version_parts[1]] {
				return version_parts[0]
			}
		}
	}
	return error('Server does not run support suitable API version')
}

fn (s &Server) raw_call<R, A>(http_method http.Method, versions []string, method string, headers map[string]string, args A) ?R {
	return call_method<R, A>(s.homeserver, http_method, s.get_suitable_version(versions)?, method, headers, args)
}

/**
 * -----------------------------------------------------------------------------------------------------------------------------
 *                                                   PUBLIC METHODS
 * -----------------------------------------------------------------------------------------------------------------------------
 */

pub fn (s &Server) supports_unstable_feature(unstable_feature string) bool {
	return unstable_feature in s.unstable_features && s.unstable_features[unstable_feature]
}

pub fn (s &Server) supports_version(version string) bool {
	s.get_suitable_version([version]) or {
		return false
	}
	return true
}

pub fn (mut s Server) get_login_flows() ? {
	resp := s.raw_call<RespLoginGet, Null>(http.Method.get, ['r0'], 'login', map[string]string{}, Null{})?
	s.login_flows = resp.flows.map(fn(flow LoginFlow) string {
		return flow.typ
	})
}

type StrOrMap = string | map[string]string

fn (s &Server) gen_session(user_id string, token string, device_id string, well_known RespWellKnown) ?&session.Session<Server> {
	rewrite_homeserver := well_known.homeserver.base_url != '' && well_known.homeserver.base_url != s.homeserver.str()
	rewrite_identity_server := well_known.identity_server.base_url != '' && well_known.identity_server.base_url != s.identity_server.str()
	if rewrite_homeserver || rewrite_identity_server {
		mut homeserver := *s.homeserver
		mut identity_server := *s.identity_server
		if rewrite_homeserver {
			homeserver = urllib.parse(well_known.homeserver.base_url) or { *s.homeserver }
		}
		if rewrite_identity_server {
			identity_server = urllib.parse(well_known.identity_server.base_url) or { *s.identity_server }
		}
		return &session.Session<Server>{Server{&homeserver, &identity_server, s.versions, s.unstable_features, s.login_flows}, user_id, token, device_id}
	}
	return &session.Session<Server>{*s, user_id, token, device_id}
}

pub fn (s &Server) login_password(devname string, user string, pass string) ?&session.Session<Server> {
	mut args := map[string]StrOrMap{}
	args['type'] = 'm.login.password'
	args['identifier'] = {
		'type': 'm.id.user',
		'user': user,
	}
	args['password'] = pass
	args['initial_device_display_name'] = devname
	resp := s.raw_call<RespLogin, map[string]StrOrMap>(http.Method.post, ['r0.4'], 'login', map[string]string{}, args)?
	return s.gen_session(resp.user_id, resp.access_token, resp.device_id, resp.well_known)
}
