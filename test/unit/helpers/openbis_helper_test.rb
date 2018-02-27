require 'test_helper'

class OpenbisHelperTest < ActionView::TestCase

  test 'openbis_rich_content_sanitizer works' do

    txt = 'no html to 1234567 cuttted'
    cleaned = openbis_rich_content_sanitizer(txt,15).to_s

    exp = 'no html to 1234567 ...'

    assert_equal exp,cleaned
    assert cleaned.html_safe?

    txt = '
<?xml><html><head></head><body><div><div class="ala" style="margin-top: 20;">text in div</div>
<p> para gragh</p><p>parag without closing
<ul> <li class="top">first list</li><li>second</li></ul>
</div></body></html>'

    cleaned = openbis_rich_content_sanitizer(txt,15).to_s

    exp = '<div>
<div>text in div</div><p>para ...</p>
</div>'

    assert_equal exp,cleaned
    assert cleaned.html_safe?

    cleaned = openbis_rich_content_sanitizer(txt).to_s

    exp =
'
<div>
<div>text in div</div>
<p> para gragh</p>
<p>parag without closing
</p>
<ul> <li>first list</li>
<li>second</li>
</ul>
</div>'

    assert_equal exp,cleaned
    assert cleaned.html_safe?

  end

  test 'StylingScrubber removes class and style attr' do
    scrubber = OpenbisHelper::StylingScrubber.new

    txt = '<div><div class="ala"><p style="margin: 10;">Content</p></div></div>'

    res = Loofah.fragment(txt).scrub!(scrubber).to_s
    assert_equal '<div><div><p>Content</p></div></div>', res
  end

  test 'StatefulWordTrimmer trimms text spanned over the calls' do
    trimmer = OpenbisHelper::StatefulWordTrimmer.new(15)

    txt = ' 12345 678 '
    res = trimmer.trim(txt)
    assert_equal '12345 678', res
    refute trimmer.trimmed

    txt = '90   '
    res = trimmer.trim(txt)
    assert_equal '90', res

    txt = '123 456'
    res = trimmer.trim(txt)
    assert_equal '123 ...', res
    assert trimmer.trimmed

    res = trimmer.trim(txt)
    assert_equal '', res
    assert trimmer.trimmed

  end

  test 'TextTrimmingScrubber trims html if text nodes exceed limit' do
    scrubber = OpenbisHelper::TextTrimmingScrubber.new(15)

    txt = '<div> <ul><li>12345 </li><li>678 90</li></ul>
          <p>12</p> <ul><li>34 56</li><li>cut</li></ul><div>no more</div></div>'

    res = Loofah.fragment(txt).scrub!(scrubber).to_s
    # puts res
    assert_equal '<div><ul>
<li>12345</li>
<li>678 90</li>
</ul><p>12</p><ul><li>34 ...</li></ul>
</div>', res
  end



end