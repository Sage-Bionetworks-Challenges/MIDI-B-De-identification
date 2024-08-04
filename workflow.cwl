#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: Workflow
label: MICCAI 2024 MIDI-B Challenge Evaluation
doc: >
  Image de-identification is a requirement for the 
  public sharing of medical images. The goal of the 
  Medical Image Deidentification Benchmark (MIDI-B) 
  challenge is to guide the assessment of rule-based 
  DICOM image de-identification algorithms using 
  clinical images with synthetic identifiers.

requirements:
  - class: StepInputExpressionRequirement

inputs:
  submissionId:
    label: Submission ID
    type: int
  adminUploadSynId:
    label: Synapse Folder ID accessible by the admin
    type: string
  submitterUploadSynId:
    label: Synapse Folder ID accessible by the submitter
    type: string
  synapseConfig:
    label: filepath to .synapseConfig file
    type: File
  organizers:
    label: User or team ID for challenge organizers
    type: string
    default: "3487813"

outputs: {}

steps:
  organizers_log_access:
    doc: >
      Give challenge organizers `download` permissions to the submission logs
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#adminUploadSynId"
      - id: principalid
        source: "#organizers"
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []

  set_submitter_folder_permissions:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#submitterUploadSynId"
      # TODO: replace `valueFrom` with the admin user ID or admin team ID
      - id: principalid
        source: "#organizers" 
      - id: permissions
        valueFrom: "download"
      - id: synapse_config
        source: "#synapseConfig"
    out: []
    
  download_submission:
    doc: Download submission
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/get_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
    out:
      - id: filepath
      - id: entity_id
      - id: entity_type
      - id: results

  create_scoring_report:
    run: steps/test.cwl
    in:
      - id: compressed_file
        source: "#download_submission/filepath"
    out:
      - id: pixel_results
      - id: database_created
      - id: results
      - id: status
      - id: invalid_reasons
      - id: scoring_results
      - id: discrepancy_results
      - id: discrepancy_internal
    
  notify_filepath_status:
    doc: Notify participant if submission is not acceptable.
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#create_scoring_report/status"
      - id: invalid_reasons
        source: "#create_scoring_report/invalid_reasons"
      - id: errors_only
        default: true
    out: [finished]

  get_score:
    doc: Isolate the submission score
    run: steps/isolate_score.cwl
    in:
      - id: scoring_file
        source: "#create_scoring_report/scoring_results"
      - id: results_file
        source: "#create_scoring_report/results"
      - id: check_validation_finished 
        source: "#notify_filepath_status/finished"
    out:
      - id: results
  
  add_score_annots:
    doc: >
      Add 'submission_status' and 'submission_errors' annotations to the
      submission
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#get_score/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  add_status_annots:
    doc: >
      Add 'status, and 'submission errors' annotation to the submission
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#create_scoring_report/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]
  
  check_filepath_status:
    doc: >
      Check the validation status of the submission; if 'INVALID', throw an
      exception to stop the workflow
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#create_scoring_report/status"
      - id: previous_annotation_finished
        source: "#add_status_annots/finished"
    out: [finished]

  # create_dciodvfy_report:
  #   run: steps/dicovdfy.cwl
  #   in:
  #     - id: compressed_file
  #       source: "#download_submission/filepath"
  #   out:
  #     - id: dciodvfy_results

  upload_to_synapse:
    run: steps/synapse_upload.cwl
    in:
      - id: discrepancy_results
        source: "#create_scoring_report/discrepancy_results"
      - id: scoring_results
        source: "#create_scoring_report/scoring_results"
      - id: synapse_config   # this input is needed so that uploading to Synapse is possible
        source: "#synapseConfig"
      - id: parent_id  # this input is needed so that Synapse knows where to upload file
        source: "#adminUploadSynId"
    out:
      - id: results
      # removed since this step is no longer happening
      # - id: dciodvfy_results
      #   source: "#create_scoring_report/dciodvfy_results"
    
  annotate_full_evaluation_with_output:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        # source: "#get_score/results"
        source: "#upload_to_synapse/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]
  
    
  annotate_submission_with_output:
    doc: Update `submission_status` and add scoring metric annotations
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.0/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#get_score/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#add_score_annots/finished"
    out: [finished] 
  # annotate_full_evaluation_with_score:
  #   run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
  #   in:
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: annotation_values
  #       source: "#get_score/results"
  #     - id: to_public
  #       default: true
  #     - id: force
  #       default: true
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #   out: [finished]

  # send_score_results:
  #   doc: >
  #     Send email of the scores to the submitter, as well as the link to the
  #     files on Synapse
  #   run: steps/email_results.cwl
  #   in:
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #     - id: results
  #       source: "#upload_to_synapse/results"
  #   out: [finished]
      # - id: discrepancy_results
      #   source: "#create_scoring_report/discrepancy_results"
      # - id: scoring_results
      #   source: "#create_scoring_report/scoring_results"
      # - id: parent_id  # this input is needed so that Synapse knows where to upload file
      #   source: "#adminUploadSynId"
      # OPTIONAL: add annotations to be withheld from participants to `[]`
      # - id: private_annotations
      #   default: []
    
  
  #remove writeup file check and subsequent email re writeup
  # validate:
  #   run: writeup/validate.cwl
  #   in:
      # - id: writeup_file
      #   source: "#unzip_generate_config/writeup_file"
    #   - id: synapse_config
    #     source: "#synapseConfig"
    #   - id: submissionid
    #     source: "#submissionId"
    #   - id: challengewiki
    #     valueFrom: "syn53065762"  # TODO: update to the Challenge's staging synID
    # # UNCOMMENT THE FOLLOWING IF NEEDED
    # #   - id: public
    # #     default: true
    # #   - id: admin
    # #     source: "#admin"
    # out:
    #   - id: results
    #   - id: status
    #   - id: invalid_reasons
  
  # validation_email:
  #   run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
  #   in:
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #     - id: status
  #       source: "#validate/status"
  #     - id: invalid_reasons
  #       source: "#validate/invalid_reasons"
  #     # UNCOMMENT IF EMAIL SHOULD ONLY BE SENT FOR ERRORS
  #     # - id: errors_only
  #     #   default: true
  #   out: [finished]

  # annotate_validation_with_output:
  #   run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
  #   in:
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: annotation_values
  #       source: "#validate/results"
  #     - id: to_public
  #       default: true
  #     - id: force
  #       default: true
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #   out: [finished]

  # check_status:
  #   run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
  #   in:
  #     - id: status
  #       source: "#validate/status"
  #     - id: previous_annotation_finished
  #       source: "#annotate_validation_with_output/finished"
  #     - id: previous_email_finished
  #       source: "#validation_email/finished"
  #   out: [finished]
 
  # archive:
  #   run: writeup/archive.cwl
  #   in:
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: admin
  #       source: "#organizers"
  #     - id: check_validation_finished 
  #       source: "#check_status/finished"
  #   out:
  #     - id: results

  # annotate_archive_with_output:
  #   run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
  #   in:
  #     - id: submissionid
  #       source: "#submissionId"
  #     - id: annotation_values
  #       source: "#archive/results"
  #     - id: to_public
  #       default: true
  #     - id: force
  #       default: true
  #     - id: synapse_config
  #       source: "#synapseConfig"
  #     - id: previous_annotation_finished
  #       source: "#annotate_validation_with_output/finished"
  #   out: [finished]

 