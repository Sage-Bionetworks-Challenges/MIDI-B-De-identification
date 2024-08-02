#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Create a file that holds the score for the synapse upload step.
requirements:
  - class: InlineJavascriptRequirement

inputs:
  scoring_file:
    type: File
  
  check_validation_finished:
    type: boolean?

outputs:
  results:
    type: File
    outputBinding:
      glob: results.json

baseCommand: get_score.py
arguments:
  - prefix: --scoring_file
    valueFrom: $(inputs.scoring_file.path)
  - prefix: -o
    valueFrom: results.json

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/get_score:v1
