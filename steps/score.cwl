#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Scoring

requirements:
  - class: InlineJavascriptRequirement

inputs:
  - id: compressed_file
    type: File

outputs:
  - id: scoring_results
    type: File
    outputBinding:
      glob: pixel_validation.xlsx

  - id: database_created
    type: File
    outputBinding:
      glob: validation_results.db

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
  - valueFrom: /usr/local/bin/MIDI_validation_script/run_validation.py
  - prefix: --compressed_file
    valueFrom: $(inputs.compressed_file)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
