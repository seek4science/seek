module TagsHelper
  include ActsAsTaggableOn::TagsHelper
  include ActsAsTaggableOn

  def tag_cloud(tags, classes,counter_method=:count)
    tags = tags.sort_by{|t| t.name.downcase}
    max_count = tags.max_by(&counter_method).send(counter_method).to_f
    if max_count < 1
      max_count = 1
    end

    tags.each do |tag|
      index = ((tag.send(counter_method) / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def overall_tag_cloud(tags, classes,&block)
    tag_cloud(tags,classes,:overall_total, &block)
  end
  

  def tags_for_context context
    #Tag.find(:all).select{|t| !t.taggings.detect{|tg| tg.context==context.to_s}.nil? }
    Tag.find(:all,:group=>"tags.id",:joins=>:taggings,:conditions=>["taggings.context = ?",context.to_s])
  end

  def show_tag?(tag)
    #FIXME: not sure this is required or works any more. was originally to work around a bug in acts-as-taggable-on
    tag.taggings.size>1 || (tag.taggings.size==1 && tag.taggings[0].taggable_id)
  end

  def link_for_tag tag, options={}
    length=options[:truncate_length]
    length||=150
    link = show_tag_path(tag)
    link_to h(truncate(tag.name,:length=>length)), link, :class=>options[:class],:id=>options[:id],:style=>options[:style],:title=>tooltip_title_attrib(tag.name)
  end

  def list_item_tags_list tags,options={}
    tags.map do |t|
      divider=tags.last==t ? "" : "<span class='spacer'>,</span> ".html_safe
      link_for_tag(t,options)+divider
    end
  end

  def aggregated_asset_tags
    tags = []
    (asset_model_classes | [Assay]).each do |c|
      tags |= c.tag_counts if c.taggable?
    end
    tags
  end

  def all_substances
    #Find all substances from Compounds table, Synonyms table, Protein table and Mixtures table
    # add to substance name the type of the substance
    # add to substance id the type of the substance
    all_substances = []

    #From Compounds table
    compounds =  Compound.find(:all)
    compounds.each do |compound|
      s = Substance.new
      s.id = compound.id.to_s + ',Compound'
      s.name = compound.name + ' : a Compound'
      all_substances.push s
    end

    #From Synonyms table
    synonyms = Synonym.find(:all)
    synonyms.each do |synonym|
      s = Substance.new
      s.id = synonym.id.to_s + ',Synonym'
      s.name = synonym.name + " : a synonym of #{synonym.substance_type} #{synonym.substance.name}"
      all_substances.push s
    end
    all_substances
  end

  class Substance
     def initialize(id = "1,Compound", name='glucose : a Compound')
       @id = id
       @name = name
     end
     def id
       @id
     end
     def id=id
       @id = id
     end

     def name
       @name
     end
     def name=name
       @name = name
     end
  end
end