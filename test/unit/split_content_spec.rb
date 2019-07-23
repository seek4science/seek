require 'minitest/autorun'
require 'minitest/spec'

class TestClass
  def split_content(content, length=10, overlap=5)
    overlap = length-overlap
    if overlap<=0
      raise 'overlap should be smaller than length'
    end
    length -=1
    words = content.split(' ')
    i = 0
    phrases = Array.new
    loop do
      temp = words[i*overlap..i*overlap+length]
      break if !temp || temp.empty?
      phrases << temp.join(' ')
      i+=1
    end
    phrases
  end
end


describe TestClass do
  subject {TestClass.new}
  it "should be instance of array" do
    subject.split_content('Hello world!',10,5).must_be_instance_of Array
  end
  it "should extract input string" do
    subject.split_content('',10,5).must_equal([])
    subject.split_content('Hello world!',10,5).must_equal(['Hello world!'])
    subject.split_content('Hello world!',2,1).must_equal(['Hello world!','world!'])
  end
  it "should raise error if overlap is equal or greater than length" do
    assert_raises RuntimeError do
      subject.split_content('Hello world!',2,2)
      subject.split_content('Hello world!',2,3)
    end
  end
end