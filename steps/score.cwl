#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Scoring

requirements:
  - class: InlineJavascriptRequirement

inputs:
  compressed_file:
    type: File
    inputBinding:
      position: 1

outputs:
  scoring_results:
    type: File
    outputBinding:
      glob: pixel_validation.xlsx

  database_created:
    type: File
    outputBinding:
      glob: validation_results.db

baseCommand: python
arguments:
  - /usr/local/bin/MIDI_validation_script/run_validation.py
  - prefix: --compressed_file
    valueFrom: $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
