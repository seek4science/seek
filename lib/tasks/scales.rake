require 'rubygems'
require 'rake'
require 'active_record/fixtures'

namespace :seek_scales do
  desc("adds the scales defined by Virtual Liver")
  task(:vl_scales=>:environment) do
    Scale.destroy_all
    Scale.new(:title=>"Organism",:key=>"organism",:pos=>5,:image_name=>"vl-scales/organism.png").save!
    Scale.new(:title=>"Liver",:key=>"liver",:pos=>4,:image_name=>"vl-scales/liver.png").save!
    Scale.new(:title=>"Liver Lobule",:key=>"liverlobule",:pos=>3,:image_name=>"vl-scales/liverlobule.png").save!
    Scale.new(:title=>"Intercellular",:key=>"intercellular",:image_name=>"vl-scales/intercellular.png",:pos=>2).save!
    Scale.new(:title=>"Cell",:key=>"cell",:image_name=>"vl-scales/cellular.png",:pos=>1).save!
  end

  desc("adds scales passed on to us by Afsaneh for AirProm demo")
  task(:airprom=>:environment) do
    Scale.destroy_all
    Scale.new(:title=>"Genomics",:key=>"genomics",:pos=>1,:image_name=>"airprom/genomics.jpg").save!
    Scale.new(:title=>"Sub-cellular",:key=>"subcellular",:pos=>2,:image_name=>"airprom/sub-cellular.jpg").save!
    Scale.new(:title=>"Inflammatory cells",:key=>"inflammatory",:pos=>3,:image_name=>"airprom/inflammatory-cells.jpg").save!
    Scale.new(:title=>"Structural cells",:key=>"structural",:pos=>4,:image_name=>"airprom/structural-cells.png").save!
    Scale.new(:title=>"Aveoli",:key=>"aveoli",:pos=>5,:image_name=>"airprom/aveoli.png").save!
    Scale.new(:title=>"Small airways",:key=>"smallairway",:pos=>6,:image_name=>"airprom/small-airway.jpg").save!
    Scale.new(:title=>"Large airways",:key=>"largeairway",:pos=>7,:image_name=>"airprom/large-airway.png").save!
    Scale.new(:title=>"Lung",:key=>"lung",:pos=>8,:image_name=>"airprom/lung.jpg").save!
    Scale.new(:title=>"Organism",:key=>"organism",:pos=>9,:image_name=>"airprom/organism.jpg").save!
  end

end