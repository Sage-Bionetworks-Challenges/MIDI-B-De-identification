#!/usr/bin/env cwl-runner

cwlVersion: v1.0
class: CommandLineTool
label: Run the submission against the Organizers pipeline for Scoring

requirements:
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: /usr/local/bin/MIDI_validation_script/midi_1_1_answer_data_1.db
        entry: $(inputs.answer_database.path)  # Ensure the database file is available in the container

inputs:
  compressed_file:
    type: File
    inputBinding:
      position: 1  # Ensures this input appears directly as the first argument
  
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
  - $(inputs.compressed_file.path)

hints:
  DockerRequirement:
    dockerPull: docker.synapse.org/syn53065762/validate_score:v12
