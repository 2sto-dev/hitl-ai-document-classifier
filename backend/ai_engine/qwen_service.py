import json
import os
import requests


OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = os.environ.get("OLLAMA_MODEL", "phi3:latest")
ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "summary": {"type": "string"},
        "keywords": {
            "type": "array",
            "items": {"type": "string"},
            "maxItems": 6,
        },
        "department": {
            "type": "string",
            "enum": ["HR", "Finance", "Legal", "IT", "Procurement", "Operations"],
        },
    },
    "required": ["summary", "keywords", "department"],
}


def analyze_document(text):

    prompt = (
        "Summarize this enterprise document in at most two short sentences. "
        "Return 3-6 keywords and select its department.\n\n"
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
                "num_ctx": 2048,
                "num_predict": 100,
            }
        },
        timeout=90
    )

    response.raise_for_status()

    result = response.json()

    if "response" not in result:
        raise Exception(
            f"Ollama error: {result}"
        )

    raw_response = result["response"]

    try:

        start = raw_response.find("{")
        end = raw_response.rfind("}") + 1

        json_text = raw_response[start:end]

        return json.loads(json_text)

    except Exception:

        return {
            "summary": raw_response,
            "keywords": [],
            "department": "Unknown"
        }
