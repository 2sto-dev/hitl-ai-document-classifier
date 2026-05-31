import json
import requests


OLLAMA_URL = "http://localhost:11434/api/generate"


def analyze_document(text):

    prompt = f"""
You are an enterprise document classification assistant.

Analyze the document and determine which department should receive it.

Possible departments:

- HR
- Finance
- Legal
- IT
- Procurement
- Operations

Return ONLY valid JSON.

Example:

{{
    "summary": "Employment agreement between employer and employee.",
    "keywords": ["employee", "salary", "benefits"],
    "department": "HR"
}}

Document:

{text[:5000]}
"""

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": "phi3:latest",
            "prompt": prompt,
            "stream": False
        },
        timeout=180
    )

    result = response.json()

    print("OLLAMA RAW RESPONSE:")
    print(result)

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