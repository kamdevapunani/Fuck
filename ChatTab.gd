extends VBoxContainer

@onready var chat_history: RichTextLabel = $ChatScroll/ChatHistory
@onready var chat_input: LineEdit = $ChatInputRow/ChatInput
@onready var send_button: Button = $ChatInputRow/SendButton

var ai_client: AIClient

func _ready() -> void:
    ai_client = get_node_or_null("/root/AIClient")
    if ai_client == null:
        push_error("AIClient not found at /root/AIClient")
    send_button.pressed.connect(_on_send_pressed)

func _on_send_pressed() -> void:
    var text := chat_input.text.strip_edges()
    if text.is_empty():
        return
    chat_input.clear()
    _add_message("You", text)

    if ai_client == null:
        _add_message("Error", "AIClient not available")
        return

    var system_msg := {
        "role": "system",
        "content": "You are a GDScript assistant. Return code inside ```gdscript fences when appropriate."
    }
    var user_msg := {
        "role": "user",
        "content": text
    }

    ai_client.send_chat([system_msg, user_msg], func(response):
        if response.has("error"):
            _add_message("Error", str(response))
            return
        var content := response["choices"][0]["message"]["content"]
        _add_message("AI", content)
    )

func _add_message(who: String, msg: String) -> void:
    chat_history.append_text("[b]%s:[/b] %s\n" % [who, msg])
    chat_history.scroll_to_line(chat_history.get_line_count() - 1)
