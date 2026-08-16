import json
import os

import requests


OLLAMA_BASE_URL = os.environ.get(
    "OLLAMA_BASE_URL",
    "http://10.10.0.14:11434",
).rstrip("/")

OLLAMA_URL = f"{OLLAMA_BASE_URL}/api/generate"

OLLAMA_MODEL = os.environ.get(
    "OLLAMA_MODEL",
    "qwen3-coder:30b",
)

ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {
            "type": "string",
        },
        "keywords": {
            "type": "array",
            "items": {
                "type": "string",
            },
            "maxItems": 6,
        },
        "department": {
            "type": "string",
            "enum": [
                "HR",
                "Finance",
                "Legal",
                "IT",
                "Procurement",
                "Operations",
            ],
        },
    },
    "required": [
        "summary",
        "keywords",
        "department",
    ],
}


def analyze_document(text):
    prompt = (
        "Analyze the following enterprise document. "
        "Summarize it in at most two short sentences, "
        "return between 3 and 6 relevant keywords, "
        "and select the most appropriate department.\n\n"
        f"Document:\n{text[:1800]}"
    )

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "format": ANALYSIS_SCHEMA,
            "stream": False,
            "keep_alive": -1,
            "options": {
                "temperature": 0,
                "num_ctx": 4096,
                "num_predict": 200,
            },
        },
        timeout=180,
    )

    response.raise_for_status()

    result = response.json()

    if "response" not in result:
        raise RuntimeError(
            f"Invalid response received from Ollama: {result}"
        )

    raw_response = result["response"].strip()

    try:
        return json.loads(raw_response)

    except json.JSONDecodeError:
        start = raw_response.find("{")
        end = raw_response.rfind("}") + 1

        if start >= 0 and end > start:
            try:
                return json.loads(raw_response[start:end])
            except json.JSONDecodeError:
                pass

        return {
            "summary": raw_response,
            "keywords": [],
            "department": "Operations",
        }