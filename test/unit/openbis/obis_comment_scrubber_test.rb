require 'test_helper'

class ObisCommentScrubberTest < ActiveSupport::TestCase
  def setup
    @scrubber = Seek::Openbis::ObisCommentScrubber.new
  end

  test 'setup work' do
    assert @scrubber
  end

  test 'cleans comments' do
    txt = "\u003croot\u003e\u003ccommentEntry date=\"1511277856415\" person=\"seek\"\u003eAll was fine\u003c/commentEntry\u003e\u003ccommentEntry date=\"1511283153915\" person=\"seek\"\u003eBut it was tiring\u003c/commentEntry\u003e\u003c/root\u003e"

    res = Loofah.fragment(txt).scrub!(@scrubber).scrub!(:prune).to_s
    # puts res

    exp = '<div>
<p>All was fine</p>
<p>But it was tiring</p>
</div>'

    assert_equal exp, res
  end
end
