import importlib.util
import pathlib
import unittest


MODULE_PATH = pathlib.Path(__file__).with_name("codex-deepseek-responses-proxy.py")
SPEC = importlib.util.spec_from_file_location("codex_deepseek_responses_proxy", MODULE_PATH)
PROXY = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PROXY)


class ResponsesInputToMessagesTest(unittest.TestCase):
    def test_groups_parallel_function_calls_in_one_assistant_message(self):
        payload = {
            "input": [
                {"type": "function_call", "call_id": "call_a", "name": "read", "arguments": "{}"},
                {"type": "function_call", "call_id": "call_b", "name": "grep", "arguments": "{}"},
                {"type": "function_call_output", "call_id": "call_a", "output": "a"},
                {"type": "function_call_output", "call_id": "call_b", "output": "b"},
            ]
        }

        messages = PROXY.responses_input_to_messages(payload)

        self.assertEqual([call["id"] for call in messages[0]["tool_calls"]], ["call_a", "call_b"])
        self.assertEqual([message["role"] for message in messages], ["assistant", "tool", "tool"])


if __name__ == "__main__":
    unittest.main()
