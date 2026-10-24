"""Pretty-prints an HTTP response read from stdin.

Used by send-request.sh. Response headers printed by curl -i are passed
through unchanged. A JSON or XML body is indented; anything else, or a body
that fails to parse, is written out as-is.
"""
import json
import sys
from xml.dom import minidom


def split_headers(data):
    """Splits curl -i output into the header blocks and the body."""
    headers = b""
    while data.startswith(b"HTTP/"):
        end = data.find(b"\r\n\r\n")
        if end < 0:
            break
        headers += data[:end + 4]
        data = data[end + 4:]
    return headers, data


def remove_whitespace_nodes(node):
    for child in list(node.childNodes):
        if child.nodeType == child.TEXT_NODE and not child.data.strip():
            node.removeChild(child)
        else:
            remove_whitespace_nodes(child)


def format_body(body):
    text = body.strip()
    try:
        if text.startswith((b"{", b"[")):
            return json.dumps(json.loads(text), indent=2, ensure_ascii=False).encode() + b"\n"
        if text.startswith(b"<"):
            doc = minidom.parseString(text)
            remove_whitespace_nodes(doc)
            return doc.toprettyxml(indent="  ", encoding="UTF-8")
    except Exception:  # invalid JSON or XML, e.g. a truncated or multipart body
        pass
    return body


def main():
    data = sys.stdin.buffer.read()
    headers, body = split_headers(data)
    sys.stdout.buffer.write(headers)
    sys.stdout.buffer.write(format_body(body))


if __name__ == "__main__":
    main()
