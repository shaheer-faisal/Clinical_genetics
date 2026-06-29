process SAMTOOLS_SORT {
    container "${params.sif_samtools}"
    cpus 4
    memory 12.GB
    
    input:
    path bam
    
    output:
    path "${params.sample}.sorted.bam", emit: sorted_bam
    
    script:
    """
    samtools sort -@ ${task.cpus} -m 2G ${bam} -o ${params.sample}.sorted.bam
    """
}

process SAMTOOLS_INDEX {
    container "${params.sif_samtools}"
    cpus 2
    memory 4.GB
    
    input:
    path sorted_bam
    
    output:
    path "${sorted_bam}.bai", emit: bai
    
    script:
    """
    samtools index ${sorted_bam}
    """
}
