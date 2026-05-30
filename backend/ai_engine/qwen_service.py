import json
import requests

OLLAMA_URL = "http://localhost:11434/api/generate"


def analyze_document(text):

    prompt = f"""
You are an enterprise document classification assistant.

Analyze the document and return ONLY valid JSON.

Possible departments:
- HR
- Finance
- Legal
- IT
- Procurement
- Operations

Document:

{text[:5000]}

Return:

{{
    "summary": "...",
    "keywords": ["keyword1", "keyword2"],
    "department": "HR"
}}
"""

    response = requests.post(
        OLLAMA_URL,
        json={
            "model": "qwen3:14b",
            "prompt": prompt,
            "stream": False
        },
        timeout=180
    )

    result = response.json()

    print(result)

    return result