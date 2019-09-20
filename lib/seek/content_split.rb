module Seek
  module ContentSplit
    def split_content(str, length, overlap)
      factor = length - overlap
      raise 'overlap should be smaller than length' if factor <= 0
      length -= 1
      words = str.split(' ')
      phrases = []
      loop do
        temp = words[(phrases.length * factor)..(phrases.length * factor + length)]
        break if !temp || temp.empty? || temp.length < overlap
        phrases << temp.join(' ')
      end
      phrases
    end
  end
end
