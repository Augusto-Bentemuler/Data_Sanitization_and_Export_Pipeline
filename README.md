# Data Sanitization & Export Pipeline

This repository contains a production-grade, fault-tolerant ETL (Extract, Transform, Load) pipeline built in R. It programmatically processes messy raw datasets, executes explicit schema sanitation, removes disguised nulls, neutralizes encoding discrepancies, and exports clean data into multi-format persistence layers (CSV and native Excel) with structured observability.

## Key Architecture & Software Engineering Features

* **Defensive Programming & Input Contracts**: Implements strict input validation and structural error handling to safeguard data integrity against malformed inputs or empty objects.
* **Vectorized Performance**: Leverages C++ backend execution (`stringi`) to perform high-speed string sanitization and normalization without slow, iterative loops.
* **Robust String Sanitation & Typos Neutralization**: Cleans human errors, standardizes lower-case transformations, handles accent normalization (Latin-ASCII), and maps an extensive corporate dictionary of disguised nulls (e.g., "N/A", "--", "?", "undefined").
* **Reproducibility & Environment Isolation**: Designed with self-contained dependency management and automatic directory provisioning, making it fully ready to run in headless environments or containerized servers without manual intervention.

## Tech Stack & Libraries

* **Language:** R
* **Data Manipulation:** tidyverse (dplyr, tidyr)
* **String Processing & Encoding:** stringi, readr
* **Export Persistence:** writexl
* **Quality Assurance & Observability:** Structured audit logs (`[AUDIT]`)

## Methodology Brief

The pipeline enforces clean data standards to ensure reliable downstream analytics, machine learning, or executive reporting.

* **Structural Hygiene:** Automatically standardizes column names to snake_case, strips invisible whitespace, and enforces rigorous UTF-8 encoding across operating systems.
* **Deterministic Deduplication:** Safely purges exact record duplicates while emitting complete operational metrics.
* **Multi-Format Persistence:** Automatically archives sanitized outputs into version-timestamped CSV (UTF-8 strict) and Excel (`.xlsx`) files.
