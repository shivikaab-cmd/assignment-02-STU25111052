# Part 2 — RDBMS vs NoSQL

## Database Recommendation

**Recommendation: Start with MySQL; augment with MongoDB for the fraud detection module.**

For the core patient management system, MySQL (or any RDBMS) is the correct choice. Healthcare data is inherently relational — patients have appointments, appointments link to doctors, diagnoses reference standardized medical codes (ICD-10), and prescriptions tie to pharmacies. These relationships are stable, well-understood, and benefit enormously from enforced schemas and foreign key constraints. More critically, healthcare data demands **ACID** guarantees. If a patient's medication dosage is being updated and the server crashes mid-transaction, an ACID-compliant database rolls back to the last consistent state. No partial writes. No ambiguous dosage records. In a domain where a wrong drug dosage can be fatal, this is non-negotiable.

MongoDB, by contrast, operates under **BASE** semantics (Basically Available, Soft state, Eventually consistent). While it offers high availability and horizontal scalability, it trades away the hard consistency guarantees that patient records require. A MongoDB replica set may serve slightly stale reads from a secondary node — acceptable for a product catalogue, unacceptable for a patient allergy list.

The **CAP theorem** reinforces this: in a distributed system, you can have at most two of Consistency, Availability, and Partition tolerance. MySQL clusters prioritize **Consistency + Partition tolerance (CP)**, meaning they may briefly become unavailable under a network partition rather than serve inconsistent data — the right trade-off for healthcare. MongoDB defaults to **Availability + Partition tolerance (AP)**.

**For the fraud detection module, the answer changes.** Fraud detection requires ingesting and querying semi-structured, rapidly evolving behavioral signals — click patterns, device fingerprints, geolocation sequences — that do not map cleanly to fixed relational schemas. MongoDB's flexible document model, horizontal write scaling, and array/nested-object support make it well-suited here. A hybrid architecture — MySQL for patient records, MongoDB for fraud signals — gives the startup both safety and speed.
