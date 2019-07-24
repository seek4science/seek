module Seek
  module ContentSplit
    def split_content(str, length = 10, overlap = 5)
      overlap = length - overlap
      raise 'overlap should be smaller than length' if overlap <= 0
      length -= 1
      words = str.split(' ')
      phrases = []
      loop do
        temp = words[phrases.length * overlap..phrases.length * overlap + length]
        break if !temp || temp.empty?
        phrases << temp.join(' ')
      end
      phrases
    end
  end
end
