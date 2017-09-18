class OpenbisAssay < Assay

  # GroupedPagination mixing does not add it to sub classes, or rather calls by self.class.pages and it brakes
  # why it works for Assay if mixing only adds to ActiveRecord::Base
  def self.pages
    superclass.pages
  end
end