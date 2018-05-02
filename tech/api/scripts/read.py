types = ['Assay', 'DataFile', 'Document', 'Event', 'Institution',
         'Investigation', 'Model', 'Organism', 'Person',
         'Presentation', 'Programme', 'Project', 'Publication',
         'SampleType', 'Sop', 'Study']

readTemplate = "A **read{0}** operation will return information about the\n\
{0} identified, provided the authenticated user has access to it.\n\
\n\
The **read{0}** operation returns a JSON object representing the {0}."

updateTemplate = "An **update{0}** operation will modify the information held about the specified {0}. This operation is only available if the authenticated user has access to the {0}.\n\
\n\
The **update{0}** operation returns a JSON object representing the modified {0}."

deleteTemplate= "A **delete{0}** operation will delete the specified {0}, if the authenticated user has sufficient access to it."

for t in types:
  fname = "read{0}.md".format(t)
  with open(fname, 'w') as f:
    print >> f, readTemplate.format(t)

  fname = "update{0}.md".format(t)
  with open(fname, 'w') as f:
    print >> f, updateTemplate.format(t)

  fname = "delete{0}.md".format(t)
  with open(fname, 'w') as f:
    print >> f, deleteTemplate.format(t)




  
