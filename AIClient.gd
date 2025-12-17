extends Node
class_name AIClient

var api_key: String = ""
var endpoint: String = "https://api.openai.com/v1/chat/completions"

@onready var http: HTTPRequest = HTTPRequest.new()

var _pending_callback: Callable = func(_r): pass

func _ready() -> void:
    add_child(http)
    http.request_completed.connect(_on_request_completed)

func send_chat(messages: Array, callback: Callable) -> void:
    _pending_callback = callback

    var body := {
        "model": "gpt-4o-mini", # placeholder, change as needed
        "messages": messages,
    }

    var headers := [
        "Content-Type: application/json",
        "Authorization: " + "Bearer " + api_key,
    ]

    var err := http.request(
        endpoint,
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(body)
    )
    if err != OK:
        push_error("AI request failed to start: %s" % err)
        _pending_callback.call({"error": "request_failed", "code": err})

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
    if result != HTTPRequest.RESULT_SUCCESS:
        _pending_callback.call({"error": "network_error", "code": result})
        return

    var txt := body.get_string_from_utf8()
    var data = JSON.parse_string(txt)
    if data == null:
        _pending_callback.call({"error": "json_parse_error", "raw": txt})
        return

    _pending_callback.call(data)
