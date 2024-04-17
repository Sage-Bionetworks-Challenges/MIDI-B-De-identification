#!/usr/bin/env cwl-runner

# INPUTS:
#   submission_id: Submission ID
#   synapse_config: filepath to .synapseConfig file
#   admin_folder_id: Synapse Folder ID accessible by an admin
#   submitter_folder_id: Synapse Folder ID accessible by the submitter
#   workflow_id: Synapse File ID that links to the workflow archive

cwlVersion: v1.0
class: Workflow

label: MIDI-B De-identification - Task 1 workflow
doc: >
  This workflow will validate a participant's de-identified images, checking for:
    - Submission is a Synapse project
    - Submission is not the challenge site (which is a Synapse project)
    - Submission is accessible to the organizers team
    - Submission specific config.json is generated
  Archive (create a project copy) if the submission is valid.

requirements:
  - class: StepInputExpressionRequirement

inputs:
  - adminUploadSynId:
    label: Synapse Folder ID accessible by an admin
    type: string
  - id: submissionId
    label: Submission ID
    type: int
  - id: synapseConfig
    label: filepath to .synapseConfig file
    type: File
  - id: submitterUploadSynId
    label: Synapse Folder ID accessible by the submitter
    type: string
  - id: workflowSynapseId
    label: Synapse File ID that links to the workflow
    type: string
  - id: organizers
    label: User or team ID for challenge organizers
    type: string
    default: "3487816"  # TODO: enter organizers username (they will become the archive owner)

outputs: []

steps:
  organizers_log_access:
    doc: >
      Give challenge organizers `download` permissions to the submission logs
    run: |-
      https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/set_permissions.cwl
    in:
      - id: entityid
        source: "#submitterUploadSynId"
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
      - id: evaluation_id
      - id: results
      
  create_config_file:
    run: /bin/bash
    label: "Create config.json"
    in:
      - id: submitterUploadSynId
        source: "#submitterUploadSynId"
      - id: submissionId
        source: "#submissionId"
    out: [config_file]

  validate:
    run: validate.cwl
    in:
      - id: synapse_config
        source: "#synapseConfig"
      - id: submissionid
        source: "#submissionId"
      - id: challengewiki
        valueFrom: "syn53065762"  # TODO: update to the Challenge's staging synID
    # UNCOMMENT THE FOLLOWING IF NEEDED
    #   - id: public
    #     default: true
    #   - id: admin
    #     source: "#admin"
    out:
      - id: results
      - id: status
      - id: invalid_reasons
  
  validation_email:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/validate_email.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: synapse_config
        source: "#synapseConfig"
      - id: status
        source: "#validate/status"
      - id: invalid_reasons
        source: "#validate/invalid_reasons"
      # UNCOMMENT IF EMAIL SHOULD ONLY BE SENT FOR ERRORS
      # - id: errors_only
      #   default: true
    out: [finished]

  annotate_validation_with_output:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#validate/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
    out: [finished]

  check_status:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/check_status.cwl
    in:
      - id: status
        source: "#validate/status"
      - id: previous_annotation_finished
        source: "#annotate_validation_with_output/finished"
      - id: previous_email_finished
        source: "#validation_email/finished"
    out: [finished]
 
  archive:
    run: archive.cwl
    in:
      - id: synapse_config
        source: "#synapseConfig"
      - id: submissionid
        source: "#submissionId"
      - id: organizers
        source: "#organizers"
      - id: check_validation_finished 
        source: "#check_status/finished"
    out:
      - id: results

  annotate_archive_with_output:
    run: https://raw.githubusercontent.com/Sage-Bionetworks/ChallengeWorkflowTemplates/v4.1/cwl/annotate_submission.cwl
    in:
      - id: submissionid
        source: "#submissionId"
      - id: annotation_values
        source: "#archive/results"
      - id: to_public
        default: true
      - id: force
        default: true
      - id: synapse_config
        source: "#synapseConfig"
      - id: previous_annotation_finished
        source: "#annotate_validation_with_output/finished"
    out: [finished]
