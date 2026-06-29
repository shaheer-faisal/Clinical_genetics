process CLAIR3 {
    container "${params.sif_clair3}"
    cpus 8
    memory 16.GB
    publishDir "${params.outdir}/variants", mode: 'copy'
    
    input:
    path sorted_bam
    path bai
    path reference
    path fai
    
    output:
    path "merge_output.vcf.gz", emit: vcf
    path "merge_output.vcf.gz.tbi", emit: tbi
    
    script:
    """
    run_clair3.sh \
        --bam_fn=${sorted_bam} \
        --ref_fn=${reference} \
        --model_path=${params.model_path} \
        --output=./ \
        --threads=${task.cpus} \
        --platform=hifi \
        --sample_name=${params.sample} \
        --include_all_ctgs
    """
}
