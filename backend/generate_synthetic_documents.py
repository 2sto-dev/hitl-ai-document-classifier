import os
import re
from pathlib import Path

from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas

BASE_DIR = Path(__file__).resolve().parent
DATASET_ROOT = BASE_DIR / "dataset"

TEMPLATES = {
    "Finance": [
        "budget report",
        "expense report",
        "invoice",
        "financial review",
        "cash flow summary",
        "quarterly forecast",
    ],
    "HR": [
        "employment contract",
        "leave request",
        "performance review",
        "benefits enrollment",
        "salary adjustment",
        "employee handbook",
    ],
    "IT": [
        "access request",
        "incident report",
        "security audit",
        "system change request",
        "network troubleshooting",
        "cyber review",
    ],
    "Legal": [
        "nda agreement",
        "service contract",
        "compliance review",
        "policy exception",
        "legal notice",
        "contract amendment",
    ],
    "Operations": [
        "maintenance report",
        "facility checklist",
        "operational review",
        "supply log",
        "dispatch report",
        "work order",
    ],
    "Procurement": [
        "supplier evaluation",
        "purchase order",
        "vendor audit",
        "procurement approval",
        "request for quote",
        "sourcing review",
    ],
}

SAMPLE_TEXT = {
    "Finance": [
        "The finance department reviewed operating expenses for the quarter and approved budget allocations for regional expansion.",
        "The invoice was matched to the purchase order and routed for payment approval by the accounts payable team.",
        "The budget report documents cash flow adjustments, investment reserve planning, and forecasting assumptions.",
        "The monthly variance analysis identified favorable margins and flagged cost overruns in logistics and travel.",
        "The cash forecast recommended reserve adjustments and updated treasury assumptions for the next fiscal quarter.",
        "The financial review noted treasury reserve rebalancing, currency risk exposure, and capital expenditure controls.",
        "The accounts payable memo documented vendor settlement timing, accrual adjustments, and reimbursement approvals.",
    ],
    "HR": [
        "The HR team processed an employment contract and verified employee eligibility for the benefits plan.",
        "The leave request was reviewed by management and approved with compensation adjustment for the holiday period.",
        "The performance review summarized employee development goals, compensation feedback, and leadership expectations.",
        "The employee handbook update clarified salary review procedures, onboarding steps, and disciplinary guidance.",
        "The benefits enrollment form recorded dependent coverage options and payroll deduction preferences for the new plan year.",
        "The employee review documented development milestones, coaching notes, and compensation calibration for leadership.",
        "The staffing memo summarized hiring needs, internal mobility, and succession planning for critical roles.",
    ],
    "IT": [
        "The IT department approved an access request for privileged network administration and updated the identity management records.",
        "An incident report documented the security event, recovery steps, and the follow-up audit review.",
        "The system change request included a technical risk assessment and rollback plan for the production environment.",
        "The network troubleshooting ticket logged routing failures, firewall changes, and endpoint recovery actions.",
        "The security audit documented privileged account review, MFA enforcement, and access log retention controls.",
        "The IAM request described privileged access to the directory controller, MFA reset workflow, and service account lifecycle controls.",
        "The system access request included workstation provisioning, role assignment, and temporary escalation permission review.",
    ],
    "Legal": [
        "The legal team reviewed the NDA agreement and confirmed the confidentiality obligations for the partner organization.",
        "The service contract outlines commercial obligations, payment milestones, and dispute resolution mechanisms.",
        "The compliance review highlighted policy exceptions and required remediation before renewal.",
        "The contract amendment updated governing law, termination rights, and indemnity obligations for the vendor relationship.",
        "The legal notice documented notice requirements, jurisdiction clauses, and document retention instructions.",
        "The access provision agreement specified confidentiality duties, data handling obligations, and review rights under the governing policy.",
        "The legal review memo addressed restricted data access, retention schedules, and regulatory reporting obligations for the platform.",
    ],
    "Operations": [
        "The operations team recorded maintenance activity, equipment downtime, and the required corrective actions.",
        "The facility checklist tracked safety readiness, inspections, and shift handover completion across the site.",
        "The operational review summarized dispatch performance, backlog trends, and labor planning decisions.",
        "The work order logged preventive maintenance tasks and required spare parts for the production line.",
        "The dispatch report captured service timing, site readiness, and route completion metrics.",
    ],
    "Procurement": [
        "The procurement team completed the supplier evaluation and documented pricing, quality, and service level results.",
        "The purchase order was approved after vendor review and aligned with the current sourcing policy.",
        "The vendor audit confirmed compliance with procurement controls and contract obligations.",
        "The sourcing review evaluated supplier lead times, demand forecasts, and contract renewal risks.",
        "The request for quote captured specifications, delivery requirements, and commercial terms for the bid package.",
    ],
}


def create_pdf(path: Path, department: str, index: int, paragraphs=None, doc_type=None, title=None):
    c = canvas.Canvas(str(path), pagesize=letter)
    c.setFont("Helvetica", 12)
    c.drawString(50, 770, f"{department.upper()} DOCUMENT")
    selected_type = doc_type or TEMPLATES[department][index % len(TEMPLATES[department])]
    c.drawString(50, 740, f"Document Type: {selected_type}")
    c.drawString(50, 710, title or "Generated Synthetic Training Sample")

    y = 660
    for paragraph in (paragraphs or SAMPLE_TEXT[department]):
        c.drawString(50, y, paragraph)
        y -= 40

    c.drawString(50, y - 20, f"Reference ID: {department.lower()}-{index:03d}")
    c.save()


def generate_documents(count_per_department: int = 10):
    for department in TEMPLATES:
        dept_dir = DATASET_ROOT / department
        dept_dir.mkdir(parents=True, exist_ok=True)

        for i in range(count_per_department):
            filename = f"synthetic_{department.lower()}_{i + 1:02d}.pdf"
            output_path = dept_dir / filename
            if output_path.exists():
                continue
            create_pdf(output_path, department, i)
            print(f"Created {output_path}")


def generate_confusion_documents():
    confusion_specs = {
        "Legal": [
            {
                "filename": "synthetic_legal_confusion_01.pdf",
                "doc_type": "data access policy",
                "title": "Generated Synthetic Legal Confusion Sample",
                "paragraphs": [
                    "The legal review concluded that the data access policy must preserve confidentiality obligations while allowing controlled access to verified personnel.",
                    "The contract amendment specified retention terms, notice obligations, and governing law for the restricted system under the enterprise policy.",
                    "The compliance memo documented regulator reporting deadlines, disclosure restrictions, and approved review pathways for sensitive information.",
                ],
            },
            {
                "filename": "synthetic_legal_confusion_02.pdf",
                "doc_type": "restricted data handling",
                "title": "Generated Synthetic Legal Confusion Sample",
                "paragraphs": [
                    "The legal team reviewed the confidentiality clause and confirmed that unauthorized sharing would trigger breach notice requirements.",
                    "The policy exception described data handling boundaries, indemnity rights, and audit review obligations for the partner platform.",
                    "The legal notice recorded jurisdiction requirements, dispute escalation steps, and evidence preservation instructions for the review.",
                ],
            },
        ],
        "IT": [
            {
                "filename": "synthetic_it_confusion_01.pdf",
                "doc_type": "identity provisioning",
                "title": "Generated Synthetic IT Confusion Sample",
                "paragraphs": [
                    "The IT team approved a privileged access request for the directory service and recorded the identity provisioning workflow for the new role.",
                    "The access review documented MFA enforcement, service account lifecycle controls, and approval routing for the privileged group.",
                    "The incident ticket logged the password reset, endpoint remediation, and follow-up verification steps completed by support operations.",
                ],
            },
            {
                "filename": "synthetic_it_confusion_02.pdf",
                "doc_type": "access approval workflow",
                "title": "Generated Synthetic IT Confusion Sample",
                "paragraphs": [
                    "The system change request included role assignment, temporary escalation rights, and a rollback plan for the production environment.",
                    "The security audit reviewed access logs, privileged account status, and MFA challenge response settings for the identity platform.",
                    "The network troubleshooting record documented routing failures, firewall adjustments, and remediation steps completed by the operations team.",
                ],
            },
        ],
    }

    for department, specs in confusion_specs.items():
        dept_dir = DATASET_ROOT / department
        dept_dir.mkdir(parents=True, exist_ok=True)
        for index, spec in enumerate(specs, start=1):
            output_path = dept_dir / spec["filename"]
            if output_path.exists():
                continue
            create_pdf(
                output_path,
                department,
                index,
                paragraphs=spec["paragraphs"],
                doc_type=spec["doc_type"],
                title=spec["title"],
            )
            print(f"Created {output_path}")


if __name__ == "__main__":
    generate_documents(20)
    generate_confusion_documents()
