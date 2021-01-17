#HITS Group
Factory.define(:hits, class: Institution) do |f|
  f.title "Heidelberg Institute for Theoretical Studies"
  f.country "Germany"
  f.city "Heidelberg"
  f.web_page "http://www.h-its.org/"
end

Factory.define(:ain, class: Project) do |f|
  f.title "Astroinformatics"
  f.description "The AIN group develops new methods and tools to deal with the exponentially increasing amount of data in astronomy."
  f.web_page "https://www.h-its.org/research/ain/"
end

Factory.define(:ccc, class: Project) do |f|
  f.title "Computational Carbon Chemistry"
  f.description "The CCC group uses state-of-the-art computational chemistry to explore and exploit diverse functional organic materials."
  f.web_page "https://www.h-its.org/research/ccc/"
end

Factory.define(:cme, class: Project) do |f|
  f.title "Computational Molecular Evolution"
  f.description "The Computational Molecular Evolution (CME) group focuses on developing algorithms, computer architectures, and high-performance computing solutions for bioinformatics."
  f.web_page "https://www.h-its.org/research/cme/"
end

Factory.define(:cst, class: Project) do |f|
  f.title "Computational Statistics"
  f.description "The group’s current focus is on probabilistic forecasting."
  f.web_page "https://www.h-its.org/research/cst/"
end

Factory.define(:dmq, class: Project) do |f|
  f.title "Data Mining and Uncertainty Quantification"
  f.description "In this group we make use of stochastic mathematical models, high-performance computing, and hardware-aware computing to quantify the impact of uncertainties in large data sets and/or associated mathematical models and thus help to establish reliable insights in data mining. Currently, the fields of application are medical engineering, biology, and meteorology."
  f.web_page "https://www.h-its.org/research/dmq/"
end

Factory.define(:grg, class: Project) do |f|
  f.title "Groups and Geometry"
  f.description "The research group “Groups and Geometry” investigates various mathematical problems in the fields of geometry and topology, which involve the interplay between geometric spaces, such as Riemannian manifolds or metric spaces, and groups, arising for example from symmetries, acting on them."
  f.web_page "https://www.h-its.org/research/grg/"
end

Factory.define(:mbm, class: Project) do |f|
  f.title "Molecular Biomechanics"
  f.description "The major interest of the Molecular Biomechanics group is to decipher how proteins have been designed to specifically respond to mechanical forces in the cellular environment or as a biomaterial.s"
  f.web_page "https://www.h-its.org/research/mbm/"
end

Factory.define(:mcm, class: Project) do |f|
  f.title "Molecular and Cellular Modeling"
  f.description "In the MCM group we are primarily interested in understanding how biomolecules interact."
  f.web_page "https://www.h-its.org/research/mcm/"
end

Factory.define(:nlp, class: Project) do |f|
  f.title "Natural Language Processing"
  f.description "The Natural Language Processing (NLP) group develops methods, algorithms, and tools for the automatic analysis of natural language."
  f.web_page "https://www.h-its.org/research/nlp/"
end

Factory.define(:pso, class: Project) do |f|
  f.title "Physics of Stellar Objects"
  f.description "Our research group “Physics of Stellar Objects” seeks to understand the processes in stars and stellar explosions based on extensive numerical simulations."
  f.web_page "https://www.h-its.org/research/pso/"
end

Factory.define(:sdbv, class: Project) do |f|
  f.title "Scientific Databases and Visualization"
  f.description "Our mission is to improve data storage and the search for life science data, making storage, search, and processing simple to use for domain experts who are not computer scientists. We believe that much can be learned from running actual systems and serving their users, who can then tell us what is important for them."
  f.web_page "https://www.h-its.org/research/sdbv/"
end

# WorkGroup
Factory.define(:sdbv_work_group, class: WorkGroup) do |f|
  f.association :project, factory: :sdbv
  f.association :institution, factory: :hits
end


# GroupMembership
Factory.define(:sdbv_group_membership, class: GroupMembership) do |f|
  f.association :work_group, factory: :sdbv_work_group
end


# WorkGroup
Factory.define(:mcm_work_group, class: WorkGroup) do |f|
  f.association :project, factory: :mcm
  f.association :institution, factory: :hits
end


# GroupMembership
Factory.define(:mcm_group_membership, class: GroupMembership) do |f|
  f.association :work_group, factory: :mcm_work_group
end


Factory.define(:institute_with_multiple_work_groups, parent: :hits) do |f|
  f.after_create do |institute|
    institute.work_groups = FactoryGirl.create_list(:work_group, 10)
  end
end