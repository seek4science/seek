import inflect
p = inflect.engine()

types = ['Assay', 'DataFile', 'Document', 'Event', 'Institution',
         'Investigation', 'Model', 'Organism', 'Person',
         'Presentation', 'Programme', 'Project', 'Publication',
         'SampleType', 'Sop', 'Study']

listTemplate = "The **list{0}** operation returns a JSON object containing a list of all the [**{0}**](#tag/{1}) to which the authenticated user has accesss."

createTemplate = "A **create{0}** operation creates a new instance of a [**{0}**](#tag/{1}). The instance is populated with the content of the body of the API call.\n\
\n\
The **create{0}** operation returns a JSON object representing the newly created [**{0}**](#tag/{1}) and redirects to its URL."

readTemplate = "A **read{0}** operation will return information about the\
 [{0}](#tag/{1} identified, provided the authenticated user has access to it.\n\
\n\
The **read{0}** operation returns a JSON object representing the [**{0}**](#tag/{1})."

updateTemplate = "An **update{0}** operation will modify the information held about the specified [**{0}**](#tag/{1}). This operation is only available if the authenticated user has access to the [**{0}**](#tag/{1}).\n\
\n\
The **update{0}** operation returns a JSON object representing the modified [**{0}**](#tag/{1})."

deleteTemplate= "A **delete{0}** operation will delete the specified [**{0}**](#tag/{1}), if the authenticated user has sufficient access to it.\n"

for t in types:
  plural = p.plural(t)
  lower_plural = plural[0].lower() + plural[1:]
  print (plural)

  fname = "create{0}.md".format(t)
  with open(fname, 'w') as f:
    print(createTemplate.format(t, lower_plural), file = f)

  fname = "read{0}.md".format(t)
  with open(fname, 'w') as f:
    print(readTemplate.format(t, lower_plural), file = f)

  fname = "update{0}.md".format(t)
  with open(fname, 'w') as f:
    print(updateTemplate.format(t, lower_plural), file = f)

  fname = "delete{0}.md".format(t)
  with open(fname, 'w') as f:
    print(deleteTemplate.format(t, lower_plural), file = f)

  fname = "list{0}.md".format(plural)
  with open(fname, 'w') as f:
    print(listTemplate.format(plural, lower_plural), file = f)
