# Clinical Genomics Pipeline

> A modular Nextflow + Singularity pipeline for clinical genomics analysis, including HiFi long-read alignment, variant calling, and RNA-seq quantification.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Pipelines](#pipelines)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Architecture](#pipeline-architecture)
- [Container Images](#container-images)
- [Configuration](#configuration)
- [Results](#results)
- [System Requirements](#system-requirements)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This repository contains two production-ready bioinformatics pipelines:

1. **HiFi Variant Calling Pipeline** — Aligns PacBio HiFi long reads to a reference genome and calls variants (SNPs/Indels) using deep learning (Clair3).
2. **RNA-seq Quantification Pipeline** — Quantifies gene expression from short-read RNA-seq data using Salmon, with quality control via FastQC and MultiQC.

Both pipelines are built with **Nextflow** for workflow orchestration and **Singularity** for containerized, reproducible execution.

---

## Features

- **Containerized execution** — All tools run inside Singularity `.sif` images for full reproducibility
- **Modular design** — Each step is a separate Nextflow process module
- **Local execution** — Runs on a single machine (laptop, workstation, or server)
- **Resource-aware** — Configurable CPU and memory allocation per process
- **Retry logic** — Failed tasks automatically retry once
- **Test profile** — Built-in tiny dataset for quick validation
- **Pure Singularity option** — Bash-only pipeline for environments without Nextflow

---

## Pipelines

### 1. HiFi Variant Calling Pipeline (`/my-rnaseq-pipeline`)

| Step | Tool | Purpose | Container |
|------|------|---------|-----------|
| Index Reference | `samtools faidx` | Create FASTA index | `minimap2.sif` |
| Align Reads | `minimap2` | Align HiFi reads to reference | `minimap2.sif` |
| Sort BAM | `samtools sort` | Sort aligned reads by coordinate | `minimap2.sif` |
| Index BAM | `samtools index` | Create BAM index | `minimap2.sif` |
| Call Variants | `Clair3` | AI-powered SNP/Indel calling | `clair3.sif` |

**Input:** PacBio HiFi FASTQ + Reference genome (FASTA)  
**Output:** Sorted BAM, BAI index, VCF with variants

### 2. RNA-seq Quantification Pipeline (`/salmon-rnaseq-pipeline`)

| Step | Tool | Purpose | Container |
|------|------|---------|-----------|
| Quality Control | `FastQC` | Check read quality | `fastqc.sif` |
| Build Index | `salmon index` | Index transcriptome | `salmon.sif` |
| Quantify | `salmon quant` | Estimate transcript abundance | `salmon.sif` |
| Aggregate Report | `MultiQC` | Combine all QC reports | `multiqc.sif` |

**Input:** Paired-end RNA-seq FASTQ + Transcriptome (FASTA)  
**Output:** FastQC reports, Salmon quantification (`quant.sf`), MultiQC HTML report

---

## Quick Start

### HiFi Variant Calling

```bash
cd my-rnaseq-pipeline
nextflow run main.nf -profile test
```

### RNA-seq Quantification

```bash
cd salmon-rnaseq-pipeline
nextflow run main.nf -profile test
```

### Pure Singularity (no Nextflow)

```bash
cd singularity-rnaseq
./scripts/run_pipeline.sh
```

---

## Installation

### Prerequisites

- Linux/WSL2 with Ubuntu 22.04+
- Java 17 (for Nextflow)
- Singularity/Apptainer 3.x
- Nextflow >= 25.10.0
- 8+ CPU cores, 16+ GB RAM (for HiFi pipeline)
- 4+ CPU cores, 8+ GB RAM (for RNA-seq pipeline)

### Step 1: Install Java 17

```bash
sudo apt update
sudo apt install -y openjdk-17-jdk
java -version  # Should show "17.0.x"
```

### Step 2: Install Nextflow

```bash
curl -s https://get.nextflow.io | bash
chmod +x nextflow
sudo mv nextflow /usr/local/bin/
```

### Step 3: Install Singularity/Apptainer

```bash
sudo apt install -y singularity-container
# or
sudo apt install -y apptainer
```

### Step 4: Clone this repository

```bash
git clone https://github.com/liz003-ziz1010/clinical_genimics.git
cd clinical_genimics
```

### Step 5: Build containers (or pull pre-built)

**Build from definition files:**
```bash
cd my-rnaseq-pipeline/containers
sudo singularity build minimap2.sif minimap2.def
sudo singularity build clair3.sif clair3.def
```

**Pull pre-built (faster):**
```bash
cd salmon-rnaseq-pipeline/containers
singularity pull --name fastqc.sif https://depot.galaxyproject.org/singularity/fastqc:0.12.1--hdfd78af_0
singularity pull --name salmon.sif https://depot.galaxyproject.org/singularity/salmon:1.10.3--h45fbf2d_5
singularity pull --name multiqc.sif https://depot.galaxyproject.org/singularity/multiqc:1.25--pyhdfd78af_0
```

---

## Usage

### HiFi Variant Calling Pipeline

```bash
cd my-rnaseq-pipeline

# Run with test data
nextflow run main.nf -profile test

# Run with your own data
nextflow run main.nf   --reads /path/to/reads.fastq   --reference /path/to/reference.fa   --sample my_sample

# Resume from cached steps
nextflow run main.nf -profile test -resume

# Generate execution report and DAG
nextflow run main.nf -profile test -with-report report.html -with-dag flowchart.png
```

### RNA-seq Quantification Pipeline

```bash
cd salmon-rnaseq-pipeline

# Run with test data
nextflow run main.nf -profile test

# Run with your own paired-end data
nextflow run main.nf   --reads "/path/to/reads_{1,2}.fq"   --transcriptome /path/to/transcriptome.fa
```

### Pure Singularity Pipeline (no Nextflow)

```bash
cd singularity-rnaseq
./scripts/run_pipeline.sh
```

---

## Pipeline Architecture

```
clinical_genimics/
├── my-rnaseq-pipeline/              # HiFi Variant Calling
│   ├── main.nf                      # Workflow orchestrator
│   ├── nextflow.config              # Pipeline configuration
│   ├── modules/
│   │   ├── align.nf                 # MINIMAP2 alignment
│   │   ├── index.nf                 # SAMTOOLS indexing
│   │   ├── sort.nf                  # SAMTOOLS sorting
│   │   └── variant.nf               # Clair3 variant calling
│   ├── containers/
│   │   ├── minimap2.def             # Singularity recipe (minimap2 + samtools)
│   │   └── clair3.def               # Singularity recipe (Clair3 AI)
│   └── data/                        # Test data (reference.fa, HUCR38.fastq)
│
├── salmon-rnaseq-pipeline/          # RNA-seq Quantification
│   ├── main.nf                      # Workflow orchestrator
│   ├── nextflow.config              # Pipeline configuration
│   ├── modules/
│   │   ├── fastqc.nf                # Quality control
│   │   ├── salmon.nf                # Index + quantification
│   │   └── multiqc.nf               # Report aggregation
│   └── containers/                  # Pre-built or custom .sif files
│
└── singularity-rnaseq/            # Pure Singularity (no Nextflow)
    ├── scripts/
    │   └── run_pipeline.sh          # Bash orchestrator
    ├── containers/                  # .sif images
    ├── data/                        # Input FASTQ + transcriptome
    └── results/                     # Output directory
```

---

## Container Images

### HiFi Pipeline

| Container | Base Image | Tools | Size |
|-----------|-----------|-------|------|
| `minimap2.sif` | `ubuntu:22.04` | minimap2, samtools, htslib | ~200 MB |
| `clair3.sif` | `hkubal/clair3:v1.0.9` | Clair3, Python, PyTorch | ~2 GB |

### RNA-seq Pipeline

| Container | Source | Tool | Size |
|-----------|--------|------|------|
| `fastqc.sif` | Galaxy Depot / Biocontainers | FastQC 0.12.1 | ~280 MB |
| `salmon.sif` | Galaxy Depot / Combinelab | Salmon 1.10.3 | ~41 MB |
| `multiqc.sif` | Galaxy Depot / Ewels | MultiQC 1.25 | ~272 MB |

---

## Configuration

### `nextflow.config` (HiFi Pipeline)

```groovy
params {
    reads       = null                    // Input FASTQ
    reference   = null                    // Reference FASTA
    sample      = "sample1"               // Sample name prefix
    outdir      = "${launchDir}/results"  // Output directory
}

process {
    executor      = 'local'
    errorStrategy = 'retry'
    maxRetries    = 1
}

profiles {
    test {
        params.reads     = "${projectDir}/data/HUCR38.fastq"
        params.reference = "${projectDir}/data/reference.fa"
    }
}
```

### Resource Allocation

| Process | CPUs | Memory | Container |
|---------|------|--------|-----------|
| MINIMAP2_ALIGN | 8 | 16 GB | minimap2.sif |
| SAMTOOLS_FAIDX | 2 | 4 GB | minimap2.sif |
| SAMTOOLS_SORT | 2 | 4 GB | minimap2.sif |
| SAMTOOLS_INDEX | 2 | 4 GB | minimap2.sif |
| CLAIR3 | 4 | 8 GB | clair3.sif |

---

## Results

### HiFi Variant Calling

```
results/
├── aligned.bam              # Sorted, aligned reads
├── aligned.bam.bai          # BAM index
├── variants.vcf             # Called variants (SNPs/Indels)
└── report.html              # Execution report (optional)
```

### RNA-seq Quantification

```
results/
├── fastqc/
│   ├── *_fastqc.html        # Per-sample QC reports
│   └── *_fastqc.zip
├── salmon/
│   └── sample_quant/
│       ├── quant.sf         # Transcript abundance estimates
│       ├── aux_info/
│       └── logs/
└── multiqc/
    └── multiqc_report.html  # Aggregated QC report
```

---

## System Requirements

### Minimum

- OS: Ubuntu 22.04+ / WSL2
- CPU: 4 cores
- RAM: 8 GB
- Disk: 20 GB free
- Java: OpenJDK 17

### Recommended (HiFi Pipeline)

- CPU: 8+ cores
- RAM: 16+ GB
- Disk: 50 GB free (for large genomes)
- GPU: Optional (Clair3 can use CPU-only mode)

---

## Troubleshooting

### `FATAL: while performing build: conveyor failed to get`

Docker image tag doesn't exist. Use Galaxy Depot pre-built images instead:
```bash
singularity pull --name tool.sif https://depot.galaxyproject.org/singularity/tool:version
```

### `Cannot connect to Docker daemon`

This pipeline uses **Singularity**, not Docker. No Docker daemon needed.

### `Out of memory` / WSL crashes

Reduce resource allocation in `nextflow.config`:
```groovy
process {
    cpus = 2
    memory = 4.GB
}
```

Or use the **test profile** with tiny data.

### `report.html already exists`

Add to `nextflow.config`:
```groovy
report {
    overwrite = true
}
```

### `Graphviz is required`

Install for DAG generation:
```bash
sudo apt install -y graphviz
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-pipeline`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-pipeline`)
5. Open a Pull Request

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

## Citation

If you use this pipeline in your research, please cite:

- **Minimap2**: Li, H. (2018). Minimap2: pairwise alignment for nucleotide sequences. *Bioinformatics*, 34(18), 3094-3100.
- **SAMtools**: Danecek, P., et al. (2021). Twelve years of SAMtools and BCFtools. *GigaScience*, 10(2), giab008.
- **Clair3**: Zheng, Z., et al. (2022). Symphonizing pileup and full-alignment for deep learning-based long-read variant calling. *Nature Computational Science*, 2(12), 797-803.
- **Salmon**: Patro, R., et al. (2017). Salmon provides fast and bias-aware quantification of transcript expression. *Nature Methods*, 14(4), 417-419.
- **Nextflow**: Di Tommaso, P., et al. (2017). Nextflow enables reproducible computational workflows. *Nature Biotechnology*, 35(4), 316-319.

---

## Contact

- **Repository**: https://github.com/liz003-ziz1010/clinical_genimics
- **Issues**: https://github.com/liz003-ziz1010/clinical_genimics/issues

---

> Built with Nextflow, Singularity, and a lot of coffee.
