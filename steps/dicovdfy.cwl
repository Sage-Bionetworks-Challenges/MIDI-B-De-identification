#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for dciodvfy

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: config_file
    type: File

outputs:
  - id: dciodvfy_results
    type: File
    outputBinding:
      glob: dciodvfy_report.csv

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
  - valueFrom: MIDI_validation_script/run_dciodvfy.py
  - prefix: --config_file
    valueFrom: $(inputs.config_file)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
