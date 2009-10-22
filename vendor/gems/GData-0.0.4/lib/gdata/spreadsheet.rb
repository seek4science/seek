require 'gdata/base'

module GData

  class Spreadsheet < GData::Base

    def initialize(spreadsheet_id)
      @spreadsheet_id = spreadsheet_id
      super 'wise', 'gdata-ruby', 'spreadsheets.google.com'
    end

    def evaluate_cell(cell)
      path = "/feeds/cells/#{@spreadsheet_id}/1/#{@headers ? "private" : "public"}/basic/#{cell}"

      doc = Hpricot(request(path))
      result = (doc/"content[@type='text']").inner_html
    end

    def save_entry(entry)
      path = "/feeds/cells/#{@spreadsheet_id}/1/#{@headers ? 'private' : 'public'}/full"

      post(path, entry)
    end

    def entry(formula, row=1, col=1)
      <<XML
  <entry xmlns='http://www.w3.org/2005/Atom' xmlns:gs='http://schemas.google.com/spreadsheets/2006'>
    <gs:cell row='#{row}' col='#{col}' inputValue='=#{formula}' />
  </entry>
XML
    end

    def add_to_cell(formula)
      save_entry(entry(formula))
    end

  end

end
