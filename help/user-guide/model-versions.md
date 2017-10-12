---
title: SEEK User Guide - model versions
layout: page
---

* [Upload a new model version](#upload-a-new-model-version)
* [Comparing two versions of a model](#comparing-versions)

# Upload a new Model version

_This also applies to uploading a new Data file, SOP or Presentation version._

SEEK supports versioning. In SEEK, the expected use of model versioning is to keep track of a model as it is changed and improved. 
You can upload a new version of a model using the _Administration_ button.

![upload version](/images/user-guide/upload_new_version.png){:.screenshot}

When uploading a new model, you can either upload the file, or you can link from a remote URL e.g. from Biomodels database.
 
![local file or url](/images/user-guide/local_file_or_url.png){:.screenshot} 

When uploading a new model version SEEK updates the file. You should include comments describing the revision. N.B: 
If you want to edit the metadata associated with the file you need to edit this separately.
 
![revision comments](/images/user-guide/revision_comments.png){:.screenshot}

After uploading, you will be able to see the two versions displayed in the metadata.
 
![two versions](/images/user-guide/two_versions.png){:.screenshot}


# Comparing two versions of a Model

<a name='comparing-versions'/>

If a model has a number of versions, you can compare between two versions to see what was changed.
 
![two versions](/images/user-guide/two_versions.png){:.screenshot}

Navigate down to the Version History and click _Compare_.

![compare versions](/images/user-guide/compare_versions.png){:.screenshot}

You will then be given the option to choose the models that you want to compare:
 
![which versions](/images/user-guide/which_versions_to_compare.png){:.screenshot} 

SEEK then returns a list, and diagram containing the differences. 
Deletions appear in red, additions in blue, and updates that do not affect the network are in yellow.
 
![version diff](/images/user-guide/version_diff.png){:.screenshot} 

SEEK uses [BiVES](https://sems.uni-rostock.de/projects/bives/) to compare the different models. 