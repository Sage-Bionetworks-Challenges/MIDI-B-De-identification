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
      Add 'status', and 'submission errors' annotation to the submission
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

  upload_to_synapse:
    run: steps/synapse_upload.cwl
    in:
      - id: discrepancy_results
        source: "#create_scoring_report/discrepancy_results"
      - id: scoring_results
        source: "#create_scoring_report/scoring_results"
      - id: score_value
        source: "#get_score/results"
      - id: compressed_file
        source: "#download_submission/filepath"
      - id: synapse_config   # this input is needed so that uploading to Synapse is possible
        source: "#synapseConfig"
      - id: parent_id  # this input is needed so that Synapse knows where to upload file
        source: "#adminUploadSynId"
    out:
      - id: results
    
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
