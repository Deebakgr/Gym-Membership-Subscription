# Gym Membership Management - ABAP RAP Application 🏋️‍♂️💻

A complete, fully functional backend application built using the **ABAP RESTful Application Programming Model (RAP)**. This project demonstrates a **Managed Scenario** implemented from scratch (without relying on ADT generator wizards) and is fully compliant with modern **Tier-1 ABAP Cloud** strictness rules.

It exposes an **OData V2** service consumed by a Fiori Elements UI, providing a seamless user experience for managing gym members, subscription plans, and statuses.

---

## 🌟 Key Features

* **Full CRUD Operations:** Create, Read, Update, and Delete gym member records.
* **Early Numbering:** Automated 16-byte UUID generation using `cl_system_uuid=>create_uuid_x16_static()`.
* **Custom Business Actions:** * `Activate`: Changes a cancelled/expired membership to active.
  * `Cancel`: Instantly cancels an active membership.
  * `Renew`: Uses an interactive Fiori popup dialog (Abstract Entity) to accept user input and add months to the membership duration.
* **Tier-1 Cloud Compliant Math:** Calculates future expiration dates using pure ABAP date math (accounting for leap years and end-of-month rollovers) without relying on legacy/unreleased Function Modules.
* **Data Integrity (Validations):** Ensures mandatory fields are populated, validates email formatting, ensures logical dates (End Date > Start Date), and checks for valid Plan Types and Fees.
* **Automated Logic (Determinations):** Automatically defaults the currency to `USD` and status to `ACTIVE` upon creation.
* **Advanced Fiori Elements UI:**
  * **KPI Badges (Criticality):** Colored text indicators for Plans (VIP, Premium, Basic) and Statuses (Active, Cancelled, Expired) using `#WITHOUT_ICON` for a clean look.
  * **Value Helps:** Integrated standard SAP currency search (`I_Currency`).
  * Seamlessly integrated action buttons directly in the Fiori List Report and Object Page headers.

---

## 🏗️ Architecture & ABAP Objects

This project strictly follows the RAP architectural layers:

| Layer | Object Name | Description |
| :--- | :--- | :--- |
| **Database** | `ZGYM_MEMBER_T` | Transparent table with `sysuuid_x16` primary key and administrative RAP fields. |
| **Data Model (Base)** | `ZI_GYM_MEMBER` | Interface CDS View. Defines calculations for UI Criticality (Colors). |
| **Data Model (Projection)** | `ZC_GYM_MEMBER` | Projection CDS View. Exposes data to the UI and attaches standard Value Helps (`I_Currency`). |
| **Behavior Definition** | `ZI_GYM_MEMBER` | Base BDEF (Managed). Defines CRUD, validations, determinations, actions, and DB field mappings. |
| **Behavior Implementation**| `ZBP_GYM_MEMBER` | ABAP Class containing all business logic, validations, and early numbering logic. |
| **Abstract Entity** | `ZA_GYM_RENEW` | Parameter structure to capture user input (`RenewalMonths`) for the Renew action. |
| **UI Annotations** | `ZC_GYM_MEMBER` | Metadata Extension (MDE) formatting the Fiori Elements layout. |
| **Projection BDEF** | `ZC_GYM_MEMBER` | Exposes standard operations and custom actions to the consumer layer. |
| **Service Definition** | `ZUI_GYM_MEMBER_SRV`| Defines the scope of the service to be exposed. |
| **Service Binding** | `ZUI_GYM_MEMBER_O2` | Binds the service to the **OData V2 - UI** protocol. |

---

## 🚀 Getting Started

### Prerequisites
* SAP S/4HANA (On-Premise 2020+ or Cloud) or SAP BTP ABAP Environment.
* ABAP Development Tools (ADT) installed in Eclipse.

### Installation / Deployment
1. Clone this repository or copy the source code files.
2. Create the Database Table `ZGYM_MEMBER_T` and activate it.
3. Create the Base CDS View `ZI_GYM_MEMBER` and Base Behavior Definition.
4. Implement the ABAP logic in `ZBP_GYM_MEMBER`.
5. Create the Abstract Entity `ZA_GYM_RENEW`.
6. Create the Projection View `ZC_GYM_MEMBER`, Projection Behavior Definition, and Metadata Extension.
7. Create the Service Definition and Service Binding.
8. **Activate all objects** (`Ctrl + Shift + F3`).

### Running the App
1. Open the Service Binding (`ZUI_GYM_MEMBER_O2`) in ADT.
2. Ensure the binding is **Published**.
3. Select the `GymMember` entity and click **Preview**.
4. Use the Fiori Elements interface to test creating, updating, cancelling, and renewing memberships!

*(Note: We utilize OData V2 for the Service Binding to ensure the "Create" button renders natively in the ADT preview for a non-draft transactional application).*

---
*Developed with SAP ABAP RAP guidelines.*
