# HITL AI Classifier

## Running locally without internet

From PowerShell in the project directory, run:

```powershell
.\start_offline.ps1
```

Open the local URL printed by Flutter. This mode talks directly to Django at
`http://127.0.0.1:8000/api` and does not start or use ngrok. PostgreSQL must be
running locally. Document classification uses the bundled local model. Document
summaries, keywords, and AI department suggestions use the local Ollama service
with `phi3:latest`; the launcher starts Ollama when necessary.

`start_demo.ps1` remains the phone/hotspot mode and continues to use ngrok.

## Document storage

Uploaded files are stored on this computer in `backend/media/documents/`.
Django stores document metadata, extracted text, classifications, review state,
and user records in the local PostgreSQL database named `hitl_ai`. The sample
training/test PDFs under `backend/dataset/` are separate from user uploads.

Runtime uploads and local database files are ignored by Git and should be
backed up separately if they need to be retained.
