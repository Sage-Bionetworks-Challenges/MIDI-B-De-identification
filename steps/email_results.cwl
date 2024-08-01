#!/usr/bin/env cwl-runner
cwlVersion: v1.0
class: CommandLineTool

label: Send email with results

requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing:
  - entryname: email_results.py
    entry: |
      #!/usr/bin/env python
      import synapseclient
      import argparse
      import json
      import os
      parser = argparse.ArgumentParser()
      parser.add_argument("-s", "--submissionid", required=True, help="Submission ID")
      parser.add_argument("-c", "--synapse_config", required=True, help="credentials file")
      #parser.add_argument("-r", "--discrepancy_file", required=True, help="Discrepancy file")
      parser.add_argument("-r", "--scoring_file", required=True, help="Scoring file")
      parser.add_argument("-p", "--private_annotations", nargs="+", default=[], help="annotations to not be sent via e-mail")

      args = parser.parse_args()
      syn = synapseclient.Synapse(configPath=args.synapse_config)
      syn.login()

      sub = syn.getSubmission(args.submissionid)
      participantid = sub.get("teamId")
      if participantid is not None:
        name = syn.getTeam(participantid)['name']
      else:
        participantid = sub.userId
        name = syn.getUserProfile(participantid)['userName']
      evaluation = syn.getEvaluation(sub.evaluationId)
      with open(args.results) as json_data:
        annots = json.load(json_data)
      if annots.get('submission_status') is None:
        raise Exception("score.cwl must return submission_status as a json key")
      status = annots['submission_status']
      if status == "SCORED":
          csv_id = annots['scoring']
          csv_full_id = annots.get('scoring', '')
          # del annots['status']
          # del annots['submission_scores']
          for annot in args.private_annotations:
            try:
              del annots[annot]
            except KeyError:
              pass
          if csv_full_id:
            del annots['scoring']
          subject = f"Submission to '{evaluation.name}' scored!"
          message = [
            f"Hello {name},\n\n",
            f"Your submission (id: {sub.id}) has been scored and below are the metric averages:\n\n",
            "\n".join([i + " : " + str(annots[i]) for i in annots]),
            "\n\n"
          ]
          if csv_full_id:
            message.append(f"Your scoring report is available here: https://www.synapse.org/#!Synapse:{csv_id}")
            # message.append(f"\nLegacy scores are available here: https://www.synapse.org/#!Synapse:{csv_full_id}")
          else:
            message.append(f"Your report is available here: https://www.synapse.org/#!Synapse:{csv_id}")
          message.append("\n\nSincerely,\nChallenge Administrator")
          syn.sendMessage(
              userIds=[participantid],
              messageSubject=subject,
              messageBody="".join(message))

inputs:
- id: submissionid
  type: int
- id: synapse_config
  type: File
- id: scoring_file
  type: File
- id: private_annotations
  type: string[]?

outputs:
- id: finished
  type: boolean
  outputBinding:
    outputEval: $( true )

baseCommand: python3
arguments:
- valueFrom: email_results.py
- prefix: -s
  valueFrom: $(inputs.submissionid)
- prefix: -c
  valueFrom: $(inputs.synapse_config.path)
- prefix: -r
  valueFrom: $(inputs.results)
- prefix: -p
  valueFrom: $(inputs.private_annotations)

hints:
  DockerRequirement:
    dockerPull: sagebionetworks/synapsepythonclient:v2.7.2