process MINIMAP2_ALIGN {
    container "${params.sif_minimap2}"
    cpus 8
    memory 16.GB
    
    input:
    path reference
    path reads
    
    output:
    path "${params.sample}.bam", emit: bam
    
    script:
    """
    minimap2 -ax map-hifi ${reference} ${reads} -t ${task.cpus} | samtools view -bS - > ${params.sample}.bam
    """
}
