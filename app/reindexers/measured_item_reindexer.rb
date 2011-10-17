class MeasuredItemReindexer < ReindexerObserver
  observe :measured_item

  def consequences measured_item
    [
        measured_item.studied_factors.collect{|sf| sf.data_file},
        measured_item.experimental_conditions.collect{|ec| ec.sop}
    ].flatten
  end

end