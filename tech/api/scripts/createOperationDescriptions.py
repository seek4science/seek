import inflect
p = inflect.engine()

types = ['Assay', 'DataFile', 'Document', 'Event', 'Institution',
         'Investigation', 'Model', 'Organism', 'Person',
         'Presentation', 'Programme', 'Project', 'Publication',
         'SampleType', 'Sop', 'Study']

listTemplate = "The **list{0}** operation returns a JSON object containing a list of all the {0} to which the authenticated user has accesss."

createTemplate = "A **create{0}** operation creates a new instance of a {0}. The instance is populated with the content of the body of the API call.\n\
\n\
The **create{0}** operation returns a JSON object representing the newly created {0} and redirects to its URL."

readTemplate = "A **read{0}** operation will return information about the\
 {0} identified, provided the authenticated user has access to it.\n\
\n\
The **read{0}** operation returns a JSON object representing the {0}."

updateTemplate = "An **update{0}** operation will modify the information held about the specified {0}. This operation is only available if the authenticated user has access to the {0}.\n\
\n\
The **update{0}** operation returns a JSON object representing the modified {0}."

deleteTemplate= "A **delete{0}** operation will delete the specified {0}, if the authenticated user has sufficient access to it.\n"

for t in types:
  fname = "create{0}.md".format(t)
  with open(fname, 'w') as f:
    print(createTemplate.format(t), file = f)

  fname = "read{0}.md".format(t)
  with open(fname, 'w') as f:
    print(readTemplate.format(t), file = f)

  fname = "update{0}.md".format(t)
  with open(fname, 'w') as f:
    print(updateTemplate.format(t), file = f)

  fname = "delete{0}.md".format(t)
  with open(fname, 'w') as f:
    print(deleteTemplate.format(t), file = f)

  plural = p.plural(t)
  print (plural)
  fname = "list{0}.md".format(plural)
  with open(fname, 'w') as f:
    print(listTemplate.format(plural), file = f)
