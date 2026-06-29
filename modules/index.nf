process SAMTOOLS_FAIDX {
    container "${params.sif_samtools}"
    cpus 2
    memory 4.GB
    
    input:
    path reference
    
    output:
    path "${reference}.fai", emit: fai
    
    script:
    """
    samtools faidx ${reference}
    """
}
