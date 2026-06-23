#!/usr/bin/env python3
import json
import os
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib import error, request


HOST = os.environ.get("HOST", "127.0.0.1")
PORT = int(os.environ.get("PORT", "18888"))
DEEPSEEK_BASE_URL = os.environ.get("DEEPSEEK_BASE_URL", "https://api.deepseek.com").rstrip("/")
DEFAULT_MODEL = os.environ.get("DEEPSEEK_MODEL", "deepseek-v4-flash")
DEFAULT_THINKING = os.environ.get("DEEPSEEK_THINKING", "disabled").strip().lower()


def text_from_content(content):
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        chunks = []
        for part in content:
            if isinstance(part, str):
                chunks.append(part)
            elif isinstance(part, dict):
                if "text" in part:
                    chunks.append(str(part["text"]))
                elif part.get("type") in {"input_text", "output_text"}:
                    chunks.append(str(part.get("text", "")))
        return "\n".join(chunk for chunk in chunks if chunk)
    return str(content)


def responses_input_to_messages(payload):
    messages = []
    instructions = payload.get("instructions")
    if instructions:
        messages.append({"role": "system", "content": str(instructions)})

    input_value = payload.get("input", "")
    if isinstance(input_value, str):
        if input_value:
            messages.append({"role": "user", "content": input_value})
        return messages

    if not isinstance(input_value, list):
        messages.append({"role": "user", "content": json.dumps(input_value, ensure_ascii=False)})
        return messages

    for item in input_value:
        if isinstance(item, str):
            messages.append({"role": "user", "content": item})
            continue
        if not isinstance(item, dict):
            continue

        item_type = item.get("type")
        if item_type == "message":
            role = item.get("role", "user")
            if role == "developer":
                role = "system"
            messages.append({"role": role, "content": text_from_content(item.get("content"))})
        elif item_type == "function_call":
            call_id = item.get("call_id") or item.get("id") or f"call_{uuid.uuid4().hex}"
            messages.append({
                "role": "assistant",
                "content": None,
                "tool_calls": [{
                    "id": call_id,
                    "type": "function",
                    "function": {
                        "name": item.get("name", "tool"),
                        "arguments": item.get("arguments", "{}"),
                    },
                }],
            })
        elif item_type == "function_call_output":
            messages.append({
                "role": "tool",
                "tool_call_id": item.get("call_id") or item.get("id") or "call_unknown",
                "content": text_from_content(item.get("output")),
            })
    return messages


def responses_tools_to_chat_tools(payload):
    chat_tools = []
    for tool in payload.get("tools") or []:
        if not isinstance(tool, dict):
            continue
        if tool.get("type") != "function":
            continue
        chat_tools.append({
            "type": "function",
            "function": {
                "name": tool.get("name", "tool"),
                "description": tool.get("description", ""),
                "parameters": tool.get("parameters") or {"type": "object", "properties": {}},
            },
        })
    return chat_tools


def responses_tool_choice_to_chat(payload):
    choice = payload.get("tool_choice")
    if choice in {"auto", "none", "required"}:
        return choice
    if isinstance(choice, dict) and choice.get("type") == "function":
        name = choice.get("name") or choice.get("function", {}).get("name")
        if name:
            return {"type": "function", "function": {"name": name}}
    return None


def responses_text_format_to_chat(payload):
    text = payload.get("text")
    if not isinstance(text, dict):
        return None
    fmt = text.get("format")
    if not isinstance(fmt, dict):
        return None
    fmt_type = fmt.get("type")
    if fmt_type in {"json_object", "json_schema"}:
        return {"type": "json_object"}
    return None


def chat_payload_from_responses(payload):
    chat_payload = {
        "model": payload.get("model") or DEFAULT_MODEL,
        "messages": responses_input_to_messages(payload),
        "stream": False,
    }
    if not chat_payload["messages"]:
        chat_payload["messages"] = [{"role": "user", "content": ""}]

    for source, target in (
        ("temperature", "temperature"),
        ("top_p", "top_p"),
        ("max_output_tokens", "max_tokens"),
        ("user", "user"),
    ):
        if payload.get(source) is not None:
            chat_payload[target] = payload[source]

    tools = responses_tools_to_chat_tools(payload)
    if tools:
        chat_payload["tools"] = tools
        tool_choice = responses_tool_choice_to_chat(payload)
        if tool_choice is not None:
            chat_payload["tool_choice"] = tool_choice

    response_format = responses_text_format_to_chat(payload)
    if response_format is not None:
        chat_payload["response_format"] = response_format

    if DEFAULT_THINKING in {"enabled", "disabled"}:
        chat_payload["thinking"] = {"type": DEFAULT_THINKING}

    reasoning = payload.get("reasoning")
    if DEFAULT_THINKING == "enabled" and isinstance(reasoning, dict) and reasoning.get("effort"):
        chat_payload["reasoning_effort"] = reasoning["effort"]

    return chat_payload


def base_response(response_id, model, status, output=None, usage=None):
    now = int(time.time())
    return {
        "id": response_id,
        "object": "response",
        "created_at": now,
        "status": status,
        "completed_at": now if status == "completed" else None,
        "error": None,
        "incomplete_details": None,
        "instructions": None,
        "max_output_tokens": None,
        "model": model,
        "output": output or [],
        "parallel_tool_calls": True,
        "previous_response_id": None,
        "reasoning": {"effort": None, "summary": None},
        "store": False,
        "temperature": 1,
        "text": {"format": {"type": "text"}},
        "tool_choice": "auto",
        "tools": [],
        "top_p": 1,
        "truncation": "disabled",
        "usage": usage or {
            "input_tokens": 0,
            "output_tokens": 0,
            "output_tokens_details": {"reasoning_tokens": 0},
            "total_tokens": 0,
        },
        "user": None,
        "metadata": {},
    }


def usage_from_chat(chat_usage):
    if not isinstance(chat_usage, dict):
        return None
    return {
        "input_tokens": chat_usage.get("prompt_tokens", 0),
        "output_tokens": chat_usage.get("completion_tokens", 0),
        "output_tokens_details": {"reasoning_tokens": 0},
        "total_tokens": chat_usage.get("total_tokens", 0),
    }


def output_from_chat_message(message):
    content = message.get("content") or ""
    tool_calls = message.get("tool_calls") or []
    if tool_calls:
        output = []
        for call in tool_calls:
            function = call.get("function") or {}
            call_id = call.get("id") or f"call_{uuid.uuid4().hex}"
            output.append({
                "id": f"fc_{uuid.uuid4().hex}",
                "type": "function_call",
                "status": "completed",
                "call_id": call_id,
                "name": function.get("name", "tool"),
                "arguments": function.get("arguments", "{}"),
            })
        return output
    return [{
        "type": "message",
        "id": f"msg_{uuid.uuid4().hex}",
        "status": "completed",
        "role": "assistant",
        "content": [{"type": "output_text", "text": content, "annotations": []}],
    }]


def call_deepseek(chat_payload):
    api_key = os.environ.get("DEEPSEEK_API_KEY")
    if not api_key:
        raise RuntimeError("DEEPSEEK_API_KEY is not set")

    body = json.dumps(chat_payload).encode("utf-8")
    req = request.Request(
        f"{DEEPSEEK_BASE_URL}/chat/completions",
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with request.urlopen(req, timeout=float(os.environ.get("DEEPSEEK_TIMEOUT", "600"))) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"DeepSeek HTTP {exc.code}: {details}") from exc


def sse_frame(event_type, data):
    return (
        f"event: {event_type}\n"
        f"data: {json.dumps(data, ensure_ascii=False, separators=(',', ':'))}\n\n"
    ).encode("utf-8")


def response_events(response_obj):
    sequence = 1
    response_id = response_obj["id"]
    model = response_obj["model"]
    created = base_response(response_id, model, "in_progress")
    yield "response.created", {"type": "response.created", "response": created, "sequence_number": sequence}
    sequence += 1
    for output_index, item in enumerate(response_obj["output"]):
        if item["type"] == "message":
            start_item = dict(item)
            start_item["status"] = "in_progress"
            start_item["content"] = []
            yield "response.output_item.added", {
                "type": "response.output_item.added",
                "output_index": output_index,
                "item": start_item,
                "sequence_number": sequence,
            }
            sequence += 1
            part = item["content"][0]
            yield "response.content_part.added", {
                "type": "response.content_part.added",
                "item_id": item["id"],
                "output_index": output_index,
                "content_index": 0,
                "part": {"type": "output_text", "text": "", "annotations": []},
                "sequence_number": sequence,
            }
            sequence += 1
            text = part.get("text", "")
            if text:
                yield "response.output_text.delta", {
                    "type": "response.output_text.delta",
                    "item_id": item["id"],
                    "output_index": output_index,
                    "content_index": 0,
                    "delta": text,
                    "sequence_number": sequence,
                }
                sequence += 1
            yield "response.output_text.done", {
                "type": "response.output_text.done",
                "item_id": item["id"],
                "output_index": output_index,
                "content_index": 0,
                "text": text,
                "sequence_number": sequence,
            }
            sequence += 1
            yield "response.content_part.done", {
                "type": "response.content_part.done",
                "item_id": item["id"],
                "output_index": output_index,
                "content_index": 0,
                "part": part,
                "sequence_number": sequence,
            }
            sequence += 1
        elif item["type"] == "function_call":
            start_item = dict(item)
            start_item["status"] = "in_progress"
            start_item["arguments"] = ""
            yield "response.output_item.added", {
                "type": "response.output_item.added",
                "output_index": output_index,
                "item": start_item,
                "sequence_number": sequence,
            }
            sequence += 1
            arguments = item.get("arguments", "{}")
            if arguments:
                yield "response.function_call_arguments.delta", {
                    "type": "response.function_call_arguments.delta",
                    "item_id": item["id"],
                    "output_index": output_index,
                    "delta": arguments,
                    "sequence_number": sequence,
                }
                sequence += 1
            yield "response.function_call_arguments.done", {
                "type": "response.function_call_arguments.done",
                "item_id": item["id"],
                "name": item.get("name", "tool"),
                "output_index": output_index,
                "arguments": arguments,
                "sequence_number": sequence,
            }
            sequence += 1
        yield "response.output_item.done", {
            "type": "response.output_item.done",
            "output_index": output_index,
            "item": item,
            "sequence_number": sequence,
        }
        sequence += 1
    yield "response.completed", {
        "type": "response.completed",
        "response": response_obj,
        "sequence_number": sequence,
    }


class Handler(BaseHTTPRequestHandler):
    server_version = "codex-deepseek-responses-proxy/0.1"

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)

    def do_GET(self):
        if self.path in {"/healthz", "/v1/healthz"}:
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok\n")
            return
        self.send_error(404)

    def do_POST(self):
        if self.path not in {"/responses", "/v1/responses"}:
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
            chat_payload = chat_payload_from_responses(payload)
            chat_response = call_deepseek(chat_payload)
            message = chat_response["choices"][0].get("message") or {}
            output = output_from_chat_message(message)
            response_id = f"resp_{uuid.uuid4().hex}"
            response_obj = base_response(
                response_id,
                chat_payload["model"],
                "completed",
                output=output,
                usage=usage_from_chat(chat_response.get("usage")),
            )
            if payload.get("stream"):
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.send_header("Cache-Control", "no-cache")
                self.send_header("Connection", "close")
                self.end_headers()
                for event_type, data in response_events(response_obj):
                    self.wfile.write(sse_frame(event_type, data))
                    self.wfile.flush()
                self.wfile.write(b"data: [DONE]\n\n")
                self.wfile.flush()
                self.close_connection = True
            else:
                body = json.dumps(response_obj, ensure_ascii=False).encode("utf-8")
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)
        except Exception as exc:
            body = json.dumps({"error": {"message": str(exc), "type": "proxy_error"}}).encode("utf-8")
            self.send_response(500)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)


def main():
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"codex-deepseek-responses-proxy listening on {HOST}:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
