module session

pub struct Session<T>{
	server T
	user_id string
	token string
	device_id string
}
