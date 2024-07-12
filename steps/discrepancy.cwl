#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Discrepancies

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: config_file
    type: File

outputs:
  - id: discrepancy_results
    type: File
    outputBinding:
      glob: discrepancy_report.csv

  # - id: results
  #   type: File
  #   outputBinding:
  #     glob: results.json

  # - id: status
  #   type: string
  #   outputBinding:
  #     glob: results.json
  #     outputEval: $(JSON.parse(self[0].contents)['submission_status'])
  #     loadContents: true

baseCommand: python
arguments:
  - valueFrom: MIDI_validation_script/run_reports.py
  - prefix: --config_file
    valueFrom: $(inputs.config_file)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v5
