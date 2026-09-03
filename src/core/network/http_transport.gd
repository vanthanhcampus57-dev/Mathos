class_name HttpTransport
extends RefCounted

## Reusable Async HTTP Networking Transport Layer for Mathos Engine.
## Wraps Godot HTTPRequest with injectable mock delegate for unit testing without a live server.

# Mock Transport Handler Signature for Unit Testing
var mock_handler: Callable = Callable()

func request(url: String, method: int = HTTPClient.METHOD_GET, headers: Array = [], body_json: String = "", timeout_seconds: float = 10.0) -> Dictionary:
	# 1. Use Mock Handler if injected
	if mock_handler.is_valid():
		var mock_res: Variant = mock_handler.call(url, method, headers, body_json, timeout_seconds)
		if mock_res is Dictionary:
			return mock_res as Dictionary

	# 2. Production HTTPRequest Execution
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return {
			"status_code": 0,
			"error_code": "NETWORK_ERROR",
			"error_message": "Engine SceneTree root unavailable for HTTP request",
			"body": "",
			"headers": []
		}

	var http_req: HTTPRequest = HTTPRequest.new()
	http_req.timeout = timeout_seconds
	tree.root.add_child(http_req)

	var req_headers: PackedStringArray = PackedStringArray()
	req_headers.append("Content-Type: application/json")
	for h in headers:
		req_headers.append(str(h))

	var err: Error = http_req.request(url, req_headers, method, body_json)
	if err != OK:
		http_req.queue_free()
		return {
			"status_code": 0,
			"error_code": "NETWORK_ERROR",
			"error_message": "Failed to initiate HTTP request (Error code: %d)" % err,
			"body": "",
			"headers": []
		}

	var res_array: Array = await http_req.request_completed
	http_req.queue_free()

	if res_array.size() < 4:
		return {
			"status_code": 0,
			"error_code": "INVALID_RESPONSE",
			"error_message": "Incomplete HTTP request completion signal",
			"body": "",
			"headers": []
		}

	var result_code: int = res_array[0] as int
	var response_code: int = res_array[1] as int
	var raw_headers: PackedStringArray = res_array[2] as PackedStringArray
	var body_bytes: PackedByteArray = res_array[3] as PackedByteArray

	if result_code == HTTPRequest.RESULT_TIMEOUT:
		return {
			"status_code": 0,
			"error_code": "TIMEOUT",
			"error_message": "Network request timed out",
			"body": "",
			"headers": raw_headers
		}

	if result_code != HTTPRequest.RESULT_SUCCESS:
		return {
			"status_code": 0,
			"error_code": "NETWORK_ERROR",
			"error_message": "Network transport error (Code: %d)" % result_code,
			"body": "",
			"headers": raw_headers
		}

	var body_str: String = body_bytes.get_string_from_utf8()

	return {
		"status_code": response_code,
		"error_code": "OK" if response_code >= 200 and response_code < 300 else "HTTP_ERROR",
		"error_message": "",
		"body": body_str,
		"headers": raw_headers
	}
