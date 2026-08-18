# HITL AI Classifier — Human-in-the-Loop Document Classification

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B.svg)
![Django](https://img.shields.io/badge/Django-6.0.5-092E20.svg)
![Python](https://img.shields.io/badge/Python-3.12%2B-3776AB.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Database-4169E1.svg)
![License](https://img.shields.io/badge/license-Educational-lightgrey.svg)

**HITL AI Classifier** is an intelligent document-management platform that combines machine learning, OCR, local large language models, and human review.

The system extracts text from uploaded PDF files, classifies documents into business departments, generates summaries and keywords, and routes uncertain predictions to a human reviewer. Reviewer decisions are recorded and displayed through an analytics dashboard, creating a transparent and auditable AI-assisted workflow.

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution](#solution)
- [Stakeholders](#stakeholders)
- [Architecture](#architecture)
- [Document Processing Workflow](#document-processing-workflow)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Supported Departments](#supported-departments)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Document Storage](#document-storage)
- [Security and Privacy](#security-and-privacy)
- [Limitations](#limitations)
- [Future Improvements](#future-improvements)

---

## Overview

HITL AI Classifier is designed to automate the processing of enterprise documents while keeping people involved in uncertain or high-risk decisions.

The platform provides:

- **Automatic PDF text extraction**
- **OCR support for scanned and image-only PDFs**
- **Machine-learning document classification**
- **AI-generated summaries and keywords**
- **Department recommendations**
- **Confidence-based decision routing**
- **Human approval, correction, or rejection**
- **Decision-history and reviewer analytics**
- **Confusion-matrix and accuracy visualization**
- **Local AI processing through Ollama**
- **Cross-platform Flutter interface**

Unlike fully automated document-classification systems, HITL AI Classifier does not blindly accept every prediction. Documents with confidence below the configured threshold are added to a review queue where a person makes the final decision.

---

## Problem Statement

Organizations receive large numbers of documents such as invoices, contracts, access requests, reports, employee records, and procurement forms.

Manually reading and routing every document creates several challenges:

- **Slow document processing**
- **Repetitive manual classification**
- **Inconsistent decisions between reviewers**
- **Difficulty processing scanned PDFs**
- **Limited visibility into model accuracy**
- **Risk of accepting uncertain AI predictions**
- **Lack of traceability for corrected decisions**
- **Dependence on external cloud AI services**

A traditional automatic classifier may process documents quickly, but it can still make incorrect decisions. A purely manual workflow provides human control but is slow and difficult to scale.

---

## Solution

HITL AI Classifier combines automated processing with human supervision.

When a PDF is uploaded, the platform:

1. Extracts embedded text using PyMuPDF.
2. Detects whether the PDF contains insufficient readable text.
3. Runs OCR on scanned or image-only pages when necessary.
4. Classifies the extracted content using a trained Scikit-learn model.
5. Calculates the most likely and second-most-likely departments.
6. Generates a summary, keywords, and department suggestion using Ollama.
7. Compares the classification confidence against a decision threshold.
8. Automatically approves high-confidence predictions.
9. Sends low-confidence predictions to the human review queue.
10. Records the final decision and reviewer information.

This workflow improves efficiency without removing human accountability.

---

## Stakeholders

- **Document Reviewers** — inspect uncertain classifications and make final decisions.
- **Business Departments** — receive documents relevant to their responsibilities.
- **Administrators** — monitor system activity and document-processing results.
- **Data Analysts** — evaluate model accuracy, reviewer corrections, and confusion patterns.
- **Machine-Learning Engineers** — train and improve the classification model.
- **Organizations** — reduce manual document-routing effort while preserving oversight.

---

## Architecture

The application follows a client-server architecture with separate interface, API, processing, AI, and storage layers.

```text
┌──────────────────────────────────────────────────────────────┐
│                    Flutter Client                            │
│                                                              │
│  • Authentication                                            │
│  • PDF upload                                                │
│  • AI review workspace                                       │
│  • Human review actions                                      │
│  • Decision history                                          │
│  • Analytics dashboard                                       │
└────────────────────────────┬─────────────────────────────────┘
                             │ HTTP/HTTPS
                             │ JWT Authentication
┌────────────────────────────▼─────────────────────────────────┐
│                   Django REST API                            │
│                                                              │
│  • User registration and authentication                      │
│  • Document upload and retrieval                             │
│  • Review queue management                                   │
│  • Human-review endpoints                                    │
│  • Statistics and analytics                                  │
└───────────────┬──────────────────────────┬───────────────────┘
                │                          │
┌───────────────▼──────────────┐  ┌────────▼──────────────────┐
│   Document Processing       │  │     AI Analysis            │
│                              │  │                           │
│  • PyMuPDF text extraction   │  │  • Local Ollama service   │
│  • OCRmyPDF                  │  │  • Document summary       │
│  • Tesseract OCR             │  │  • Keyword generation     │
│  • Text preprocessing        │  │  • Department suggestion  │
└───────────────┬──────────────┘  └────────┬──────────────────┘
                │                          │
┌───────────────▼──────────────────────────▼───────────────────┐
│              Machine-Learning Layer                          │
│                                                              │
│  • TF-IDF text vectorization                                 │
│  • Scikit-learn classification model                         │
│  • Confidence and margin calculation                         │
│  • Human-review routing                                      │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                    Data Layer                                │
│                                                              │
│  • PostgreSQL document metadata                              │
│  • User and reviewer information                             │
│  • Classification and review decisions                       │
│  • Local PDF file storage                                    │
└──────────────────────────────────────────────────────────────┘
```

---

## Document Processing Workflow

```text
PDF Upload
    │
    ▼
Embedded text extraction
    │
    ├── Readable text found ───────────────┐
    │                                      │
    └── No readable text                   │
            │                              │
            ▼                              │
       OCR processing                      │
            │                              │
            └──────────────────────────────┘
                           │
                           ▼
                  Text preprocessing
                           │
                           ▼
               ML document classification
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
       Confidence ≥ 70%          Confidence < 70%
              │                         │
              ▼                         ▼
        Auto-approved             Human review
                                        │
                              ┌─────────┼─────────┐
                              │         │         │
                              ▼         ▼         ▼
                           Approve    Change    Reject
                              │         │         │
                              └─────────┴─────────┘
                                        │
                                        ▼
                              Final decision stored
```

The default automatic-approval threshold is **70%**. Predictions below this threshold require human review.

---

## Technology Stack

### Frontend

- **Framework:** Flutter
- **Language:** Dart
- **UI:** Material Design
- **Charts:** fl_chart
- **HTTP Client:** Dart `http`
- **Local Storage:** shared_preferences
- **File Selection:** file_picker
- **External PDF Opening:** url_launcher
- **Supported Platforms:** Web, Android, iOS, Windows, macOS, and Linux

### Backend

- **Language:** Python
- **Framework:** Django 6
- **API Framework:** Django REST Framework
- **Authentication:** JSON Web Tokens with Simple JWT
- **CORS Support:** django-cors-headers
- **Production Static Files:** WhiteNoise

### Machine Learning

- **Library:** Scikit-learn
- **Text Representation:** TF-IDF vectorization
- **Model Persistence:** Joblib
- **Data Processing:** Pandas and NumPy
- **Stored Models:**
  - `classifier.pkl`
  - `vectorizer.pkl`

### OCR and PDF Processing

- **PDF Processing:** PyMuPDF
- **OCR Pipeline:** OCRmyPDF
- **OCR Engine:** Tesseract OCR
- **Scanned PDF Support:** Automatic OCR fallback

### Generative AI

- **Runtime:** Ollama
- **Purpose:**
  - Document summarization
  - Keyword extraction
  - Department suggestion
  - Follow-up document analysis
- **Configuration:** Model and server URL can be configured through environment variables.

### Database

- **Database:** PostgreSQL
- **Stored Information:**
  - Users
  - Uploaded-document metadata
  - Extracted text
  - Classification results
  - Confidence scores
  - Review states
  - Reviewer corrections
  - Final decisions

---

## Features

### Document Processing

- ✅ Upload and process PDF documents
- ✅ Extract embedded text from digital PDFs
- ✅ Detect scanned or image-only PDFs
- ✅ Apply OCR when readable text is unavailable
- ✅ Normalize and clean extracted text
- ✅ Preserve uploaded files locally

### Machine-Learning Classification

- ✅ Classify documents by business department
- ✅ Display prediction confidence
- ✅ Display the second-most-likely department
- ✅ Calculate the confidence margin
- ✅ Automatically route uncertain predictions to human review
- ✅ Automatically approve predictions above the decision threshold

### AI Analysis

- ✅ Generate concise document summaries
- ✅ Extract relevant keywords
- ✅ Suggest the receiving department
- ✅ Ask follow-up questions about an uploaded document
- ✅ Use a local Ollama model instead of requiring a cloud AI provider
- ✅ Provide deterministic local summary and keyword fallbacks when Ollama is unavailable

### Human-in-the-Loop Review

- ✅ Display uncertain documents in a review queue
- ✅ Approve the model prediction
- ✅ Change an incorrect classification
- ✅ Reject a document
- ✅ Add reviewer notes
- ✅ Record the reviewer identity
- ✅ Record whether the model required human correction
- ✅ Store the final classification and review timestamp

### Analytics

- ✅ Document-status statistics
- ✅ Department distribution
- ✅ Reviewer activity statistics
- ✅ Reviewer-correction statistics
- ✅ Classification accuracy metrics
- ✅ Confusion-matrix visualization
- ✅ Decision history

### User Experience

- ✅ Responsive Flutter interface
- ✅ Desktop and mobile layouts
- ✅ Scrollable document-analysis panels
- ✅ Keyword chips and readable summaries
- ✅ PDF preview/opening support
- ✅ Authentication and user profiles
- ✅ Local and remote demonstration modes

---

## Supported Departments

The classifier currently routes documents to six business departments:

| Department | Example Documents |
|---|---|
| **Finance** | Invoices, budgets, expense reports, financial statements |
| **HR** | Employment contracts, leave requests, performance reviews |
| **IT** | Access requests, technical incidents, cybersecurity audits |
| **Legal** | Agreements, legal notices, NDAs, service contracts |
| **Operations** | Maintenance reports, operational procedures, activity reports |
| **Procurement** | Purchase requests, supplier evaluations, procurement documents |

---

## Prerequisites

Install the following software before running the project:

- **Python 3.12 or newer**
- **Flutter SDK 3.9.2 or newer**
- **PostgreSQL**
- **Ollama**
- **Tesseract OCR**
- **Git**

For Android development, also install:

- **Android Studio**
- **Android SDK**
- An Android emulator or physical Android device

### Windows OCR Requirements

OCRmyPDF requires Tesseract OCR to process scanned PDFs.

Tesseract should be installed in a standard location such as:

```text
C:\Program Files\Tesseract-OCR\
```

Make sure the Tesseract executable is available to OCRmyPDF.

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/2sto-dev/hitl-ai-document-classifier.git
cd hitl-ai-document-classifier
```

### 2. Create a Python Virtual Environment

From the project root:

```powershell
python -m venv .venv
```

Activate it on Windows:

```powershell
.\.venv\Scripts\Activate.ps1
```

### 3. Install Backend Dependencies

```powershell
pip install -r backend\requirements.txt
```

### 4. Configure PostgreSQL

Create the PostgreSQL database and user required by the Django configuration.

Example:

```sql
CREATE DATABASE hitl_ai;
CREATE USER hitl_user WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE hitl_ai TO hitl_user;
```

Update the Django database settings for your local PostgreSQL credentials before running the backend.

### 5. Apply Database Migrations

```powershell
cd backend
python manage.py migrate
```

### 6. Create an Administrator Account

```powershell
python manage.py createsuperuser
```

### 7. Install Flutter Dependencies

```powershell
cd ..\flutter_app\hitl_flutter
flutter pub get
```

### 8. Install an Ollama Model

Install Ollama and pull the model configured by the backend.

Example:

```powershell
ollama pull qwen3-coder:30b
```

For computers with less available RAM or GPU memory, configure a smaller compatible model.

---

## Configuration

### Ollama Configuration

The backend supports the following environment variables:

| Variable | Description | Default |
|---|---|---|
| `OLLAMA_BASE_URL` | URL of the Ollama server | `http://10.10.0.14:11434` |
| `OLLAMA_MODEL` | Ollama model used for document analysis | `qwen3-coder:30b` |

Example PowerShell configuration:

```powershell
$env:OLLAMA_BASE_URL = "http://127.0.0.1:11434"
$env:OLLAMA_MODEL = "qwen3-coder:30b"
```

### Flutter API Configuration

The frontend API URL can be supplied at runtime:

```powershell
flutter run -d chrome `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

For a physical phone, replace `127.0.0.1` with an address accessible from the device or use the provided demonstration script.

---

## Running the Application

### Option 1: Local Launcher

From the project root:

```powershell
.\start_offline.ps1
```

This script:

- Starts Ollama if necessary
- Starts the Django backend
- Runs the Flutter web application
- Connects Flutter directly to the local API
- Does not require ngrok

PostgreSQL must already be running.

### Option 2: Manual Startup

#### Terminal 1 — Start Ollama

```powershell
ollama serve
```

#### Terminal 2 — Start Django

```powershell
cd backend
..\.venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

The API will be available at:

```text
http://127.0.0.1:8000/api
```

#### Terminal 3 — Start Flutter Web

```powershell
cd flutter_app\hitl_flutter
flutter run -d chrome `
  --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Other Flutter targets can also be used:

```powershell
flutter run -d windows
flutter run -d android
flutter run -d ios
```

### Option 3: Phone or Hotspot Demonstration

From the project root:

```powershell
.\start_demo.ps1
```

This mode starts the backend and exposes it through the configured ngrok address for testing on another device.

---

## API Documentation

All protected endpoints require a valid JWT access token:

```http
Authorization: Bearer <access_token>
```

### Authentication

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register/` | Register a new user |
| `POST` | `/api/auth/login/` | Obtain access and refresh tokens |
| `POST` | `/api/auth/refresh/` | Refresh an access token |
| `GET` | `/api/auth/me/` | Retrieve the authenticated user profile |

### Documents

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/documents/` | List uploaded documents |
| `GET` | `/api/documents/<id>/` | Retrieve document details |
| `POST` | `/api/upload/` | Upload and process a PDF |
| `GET` | `/api/review-queue/` | List documents requiring review |
| `POST` | `/api/documents/<id>/review/` | Submit a human-review decision |
| `POST` | `/api/ai/analyze/` | Analyze document text using Ollama |

### Analytics

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/stats/` | Retrieve overall statistics |
| `GET` | `/api/stats/departments/` | Retrieve department statistics |
| `GET` | `/api/stats/reviewers/` | Retrieve reviewer statistics |
| `GET` | `/api/stats/reviewer-corrections/` | Retrieve reviewer corrections |
| `GET` | `/api/stats/accuracy/` | Retrieve classifier accuracy data |
| `GET` | `/api/stats/confusion-matrix/` | Retrieve confusion-matrix data |

### Upload Example

```bash
curl -X POST http://127.0.0.1:8000/api/upload/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -F "filename=invoice.pdf" \
  -F "uploaded_file=@invoice.pdf"
```

### Review Example

```json
{
  "action": "change",
  "final_class": "Finance",
  "review_notes": "The uploaded file is an invoice and belongs to Finance."
}
```

Supported review actions are:

- `approve`
- `change`
- `reject`

---

## Testing

### Backend Tests

From the `backend` directory:

```powershell
..\.venv\Scripts\python.exe manage.py test
```

Run only the AI-engine tests:

```powershell
..\.venv\Scripts\python.exe manage.py test ai_engine
```

Run Django configuration checks:

```powershell
..\.venv\Scripts\python.exe manage.py check
```

### Flutter Tests

From `flutter_app/hitl_flutter`:

```powershell
flutter test
```

### Flutter Static Analysis

```powershell
flutter analyze
```

### OCR Verification

OCR behavior can be tested with an image-only PDF. The extracted text should be stored in the document’s `extracted_text` field and then used for classification, summary generation, and keyword extraction.

---

## Project Structure

```text
hitl-ai-document-classifier/
│
├── backend/
│   ├── ai_engine/
│   │   ├── classifier.py
│   │   ├── pdf_extractor.py
│   │   ├── qwen_service.py
│   │   └── services.py
│   │
│   ├── api/
│   │   ├── views.py
│   │   ├── urls.py
│   │   └── serializers.py
│   │
│   ├── documents/
│   │   ├── models.py
│   │   ├── signals.py
│   │   └── migrations/
│   │
│   ├── dashboard/
│   ├── dataset/
│   ├── models/
│   │   ├── classifier.pkl
│   │   └── vectorizer.pkl
│   │
│   ├── media/
│   ├── requirements.txt
│   └── manage.py
│
├── flutter_app/
│   └── hitl_flutter/
│       ├── android/
│       ├── ios/
│       ├── web/
│       ├── lib/
│       │   ├── config/
│       │   ├── models/
│       │   ├── screens/
│       │   ├── services/
│       │   ├── theme/
│       │   └── widgets/
│       └── pubspec.yaml
│
├── start_offline.ps1
├── start_demo.ps1
└── README.md
```

---

## Document Storage

Uploaded PDF files are stored locally in:

```text
backend/media/documents/
```

PostgreSQL stores:

- Document metadata
- Extracted text
- Predicted and suggested departments
- Confidence scores
- Summaries and keywords
- Human-review state
- Reviewer notes
- Final classifications
- User records

The sample PDFs under `backend/dataset/` are used for training and testing. They are separate from documents uploaded by users.

Runtime uploads and local databases should be backed up separately when long-term retention is required.

---

## Security and Privacy

### Authentication

- JWT-based authentication
- Access and refresh tokens
- Protected document and analytics endpoints
- Django password validation
- Authenticated reviewer tracking

### Privacy

- Uploaded documents are stored on the configured backend
- Ollama enables local document analysis
- Documents do not need to be sent to a commercial cloud LLM
- Runtime document uploads are excluded from Git

### Recommended Production Improvements

Before production deployment:

- Disable Django debug mode
- Move the Django secret key into an environment variable
- Move database credentials into environment variables
- Use HTTPS
- Restrict allowed hosts and CORS origins
- Apply upload-size limits
- Validate uploaded MIME types
- Add rate limiting
- Use secure token storage
- Configure regular database and media backups

---

## Limitations

- Classification quality depends on the quality and diversity of the training dataset.
- OCR accuracy depends on scan resolution, image quality, language, and document layout.
- Handwritten documents may not be recognized reliably.
- Large Ollama models require significant RAM or GPU resources.
- AI-generated summaries and keywords may occasionally contain inaccuracies.
- The current decision threshold may require calibration for different organizations.
- The application should be evaluated carefully before use with sensitive or regulated documents.

---

## Future Improvements

- Retrain the classifier using a larger real-world dataset
- Add multilingual OCR and classification
- Support DOCX, image, and email attachments
- Add role-based access control
- Add document versioning and audit exports
- Store per-page OCR confidence
- Add asynchronous background processing
- Add reviewer-assignment workflows
- Add notifications for pending reviews
- Add model-version tracking
- Add configurable confidence thresholds
- Use human corrections for controlled model retraining
- Add Docker and Docker Compose deployment
- Add automated CI/CD testing
- Improve explainability for classification decisions

---

## Contributors

- **Nedelcu-Holtea Catalina**

---

## Acknowledgments

- **Flutter** — cross-platform user interface
- **Django and Django REST Framework** — backend and REST API
- **Scikit-learn** — machine-learning classification
- **PyMuPDF** — PDF text extraction
- **OCRmyPDF and Tesseract** — scanned-document OCR
- **Ollama** — local large-language-model execution
- **PostgreSQL** — relational data storage

---

## Support

For problems, suggestions, or contributions, open an issue in the GitHub repository:

[https://github.com/2sto-dev/hitl-ai-document-classifier](https://github.com/2sto-dev/hitl-ai-document-classifier)

---

## Disclaimer

This project is intended for educational, research, and prototype purposes. AI-generated classifications and summaries should be reviewed before they are used for important business, legal, financial, or operational decisions.

Human review remains an essential part of the workflow.
