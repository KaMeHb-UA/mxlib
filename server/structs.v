module server

struct Null{}

struct ErrResp{
	errcode string
	error string
}

struct RespVersions {
	versions []string
	unstable_features map[string]bool
}

struct Homeserver {
	base_url string
}

struct IdentityServer {
	base_url string
}

struct LoginFlow {
	typ string [json: 'type']
}

struct RespWellKnown {
	homeserver Homeserver [json: 'm.homeserver']
	identity_server IdentityServer [json: 'm.identity_server']
}

struct RespLogin {
	flows []LoginFlow
}
